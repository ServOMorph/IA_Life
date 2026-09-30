"""Évalue le gate préenregistré T2 v1."""

from __future__ import annotations

import json
from collections import defaultdict
from pathlib import Path

from t2_results import INITIALIZATIONS, load_jsonl, validate_records

CHECKPOINTS = (0, 10, 50, 200, 1000)
TRAINED_ARMS = ("trained_memory", "trained_observation_only", "reset_each_episode")


def select_checkpoints(groups, arm: str) -> dict[int, int]:
    return {
        seed: max((sum(row["consumed"] for row in groups[(arm, seed, checkpoint)]), -checkpoint, checkpoint)
                  for checkpoint in CHECKPOINTS)[2]
        for seed in sorted(INITIALIZATIONS)
    }


def main() -> int:
    path = Path(__file__).resolve().parents[1] / "experiments" / "t2_v1_results.jsonl"
    records = load_jsonl(path)
    errors = validate_records(records)
    if errors:
        raise RuntimeError("\n".join(errors[:40]))
    groups = defaultdict(list)
    for record in records:
        groups[(record["arm"], record["initialization_seed"], record["checkpoint"])].append(record)
    selected = {arm: select_checkpoints(groups, arm) for arm in TRAINED_ARMS}
    print("checkpoints retenus", selected)
    totals: dict[str, int] = {}
    arms = ("scripted_memory", "initial_memory_frozen", "random_valid") + TRAINED_ARMS
    for arm in arms:
        total = 0
        for seed in sorted(INITIALIZATIONS):
            checkpoint = selected[arm][seed] if arm in TRAINED_ARMS else 0
            rows = groups[(arm, seed, checkpoint)]
            consumed = sum(row["consumed"] for row in rows)
            total += consumed
            print(arm, seed, checkpoint, f"consumed={consumed}/32")
        totals[arm] = total
        print(arm, f"TOTAL consumed={total}/96")
    memory = totals["trained_memory"] / 96
    comparisons = ("initial_memory_frozen", "random_valid", "trained_observation_only")
    gates = {
        "scripted_96": totals["scripted_memory"] == 96,
        "memory_success": memory >= 0.90,
        "aggregate_gains": all(memory - totals[arm] / 96 >= 0.30 for arm in comparisons),
        "lineage_gains": all(
            sum(row["consumed"] for row in groups[("trained_memory", seed, selected["trained_memory"][seed])])
            > sum(row["consumed"] for row in groups[(arm, seed, selected[arm][seed] if arm in TRAINED_ARMS else 0)])
            for seed in sorted(INITIALIZATIONS) for arm in comparisons
        ),
        "observation_ceiling": totals["trained_observation_only"] / 96 <= 0.35,
        "reset_ablation": not (
            totals["reset_each_episode"] / 96 >= 0.90
            and all(totals["reset_each_episode"] / 96 - totals[arm] / 96 >= 0.30 for arm in comparisons)
        ),
    }
    for seed, checkpoint in selected["trained_memory"].items():
        checksum = json.loads(groups[("trained_memory", seed, checkpoint)][0]["table_checksum"])
        counts = dict(checksum["counts"])
        if sum(sum(int(value) for value in values) for values in counts.values()) != checkpoint:
            raise RuntimeError(f"Nombre d'essais T2 invalide : {seed}")
        if any(max(values) - min(values) > 1 for values in counts.values()):
            raise RuntimeError(f"Exploration T2 déséquilibrée : {seed}")
    print("gate", gates)
    return 0 if all(gates.values()) else 1


if __name__ == "__main__":
    raise SystemExit(main())
