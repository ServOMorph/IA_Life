"""Compare les replays T3 v2 aux résultats retenus."""

from __future__ import annotations

import argparse
from pathlib import Path

from t3_results import load_jsonl

ROOT = Path(__file__).resolve().parents[1]
SELECTED = {400001001: 200, 400001002: 200, 400001003: 200}
FIELDS = ("survived", "berries_picked", "berries_eaten", "terminated", "truncated", "actions")


def main() -> int:
    global load_jsonl, SELECTED
    parser = argparse.ArgumentParser()
    parser.add_argument("--contract", choices=("v2", "v3"), default="v2")
    args = parser.parse_args()
    if args.contract == "v3":
        from t3_v3_results import load_jsonl as v3_load_jsonl
        load_jsonl = v3_load_jsonl
        SELECTED = {410001001: 200, 410001002: 200, 410001003: 200}
    campaign = load_jsonl(ROOT / "experiments" / f"t3_{args.contract}_results.jsonl")
    expected = {
        (row["initialization_seed"], row["card_seed"]): row
        for row in campaign
        if row["arm"] == "trained" and row["checkpoint"] == SELECTED[row["initialization_seed"]]
    }
    errors: list[str] = []
    observed = {}
    for seed in SELECTED:
        for row in load_jsonl(ROOT / "experiments" / f"t3_{args.contract}_replay_{seed}.jsonl"):
            key = (row["initialization_seed"], row["card_seed"])
            if key in observed:
                errors.append(f"doublon replay {key}")
            observed[key] = row
            reference = expected.get(key)
            if reference is None or any(row[field] != reference[field] for field in FIELDS):
                errors.append(f"résultat divergent {key}")
            if reference is None or row["table_checksum"] != reference["table_checksum"]:
                errors.append(f"checksum divergent {key}")
            if len(row.get("action_trace", [])) != row["actions"]:
                errors.append(f"trace d'actions invalide {key}")
    if set(observed) != set(expected):
        errors.append("ensemble de replays incomplet")
    if errors:
        raise RuntimeError("\n".join(errors[:40]))
    print(f"96/96 replays T3 {args.contract} identiques après recharge ; traces d'actions complètes.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
