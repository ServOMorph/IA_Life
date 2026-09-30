"""Résume le gate préenregistré T1 v2."""

from __future__ import annotations

import argparse
import json
from collections import defaultdict
from pathlib import Path

from t1_results import expected_t1_keys, load_jsonl, validate_records


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--contract", choices=("v2", "v3", "v4", "v5"), default="v2")
    args = parser.parse_args()
    path = Path(__file__).resolve().parents[1] / "experiments" / f"t1_{args.contract}_results.jsonl"
    records = load_jsonl(path)
    errors = validate_records(records, expected_t1_keys(args.contract), args.contract)
    if errors:
        raise RuntimeError("\n".join(errors[:40]))
    groups = defaultdict(list)
    for record in records:
        groups[(record["arm"], record["initialization_seed"], record["checkpoint"])].append(record)
    selected = {}
    seed_base = {"v2": 320001000, "v3": 350001000, "v4": 360001000, "v5": 370001000}[args.contract]
    for seed in (seed_base + 1, seed_base + 2, seed_base + 3):
        candidates = [(sum(row["consumed"] for row in groups[("trained", seed, checkpoint)]),
                       sum(row["first_selected_available"] for row in groups[("trained", seed, checkpoint)]),
                       -checkpoint, checkpoint)
                      for checkpoint in (0, 10, 50, 200, 1000)]
        selected[seed] = max(candidates)[3]
    print("checkpoints retenus", selected)
    if args.contract in {"v4", "v5"}:
        for seed, checkpoint in selected.items():
            checksum = groups[("trained", seed, checkpoint)][0]["table_checksum"]
            counts = dict(json.loads(checksum)["first_counts"])
            if sum(sum(int(value) for value in values) for values in counts.values()) != checkpoint:
                raise RuntimeError(f"Nombre d'essais v4 invalide : {seed}")
            if any(max(values) - min(values) > 1 for values in counts.values()):
                raise RuntimeError(f"Exploration v4 déséquilibrée : {seed}")
            print("essais équilibrés", seed, {sector: sum(values) for sector, values in counts.items()})
    for arm in ("scripted_observed", "initial_frozen", "random_valid", "trained", "reset_each_episode"):
        total_consumed = total_first = 0
        for seed in selected:
            checkpoint = selected[seed] if arm == "trained" else 1000 if arm == "reset_each_episode" else 0
            rows = groups[(arm, seed, checkpoint)]
            consumed = sum(row["consumed"] for row in rows)
            first = sum(row["first_selected_available"] for row in rows)
            total_consumed += consumed
            total_first += first
            print(arm, seed, checkpoint, f"consumed={consumed}/32", f"first={first}/32")
        print(arm, f"TOTAL consumed={total_consumed}/96 first={total_first}/96")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
