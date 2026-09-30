"""Compare les replays T2 aux résultats de campagne retenus."""

from __future__ import annotations

import json
from pathlib import Path

from t2_results import load_jsonl

ROOT = Path(__file__).resolve().parents[1]
SELECTED = {380001001: 200, 380001002: 200, 380001003: 200}
FIELDS = ("consumed", "berries_picked", "berries_eaten", "terminated", "truncated", "actions")


def main() -> int:
    campaign = load_jsonl(ROOT / "experiments" / "t2_v1_results.jsonl")
    expected = {
        (row["initialization_seed"], row["card_seed"]): row
        for row in campaign
        if row["arm"] == "trained_memory" and row["checkpoint"] == SELECTED[row["initialization_seed"]]
    }
    errors: list[str] = []
    observed = {}
    for seed in SELECTED:
        path = ROOT / "experiments" / f"t2_v1_replay_{seed}.jsonl"
        for row in load_jsonl(path):
            key = (row["initialization_seed"], row["card_seed"])
            if key in observed:
                errors.append(f"doublon replay {key}")
            observed[key] = row
            if row["selected_action"] != row["remembered_sector"]:
                errors.append(f"décision non reproduite {key}")
            reference = expected.get(key)
            if reference is None or any(row[field] != reference[field] for field in FIELDS):
                errors.append(f"résultat divergent {key}")
            if row["table_checksum"] != reference["table_checksum"]:
                errors.append(f"checksum divergent {key}")
    if set(observed) != set(expected):
        errors.append("ensemble de replays incomplet")
    if errors:
        raise RuntimeError("\n".join(errors[:40]))
    print("96/96 replays T2 identiques après recharge ; décisions mémorisées reproduites.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
