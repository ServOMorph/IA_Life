"""Compare les replays figés T1 v3 et décrit les premiers pas."""

from __future__ import annotations

import argparse
from collections import Counter, defaultdict
from pathlib import Path

from t1_results import load_jsonl


ROOT = Path(__file__).resolve().parents[1]
FIELDS = ("consumed", "first_selected_available", "actions", "berries_picked",
          "berries_eaten", "terminated", "truncated", "table_checksum")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--contract", choices=("v3", "v4", "v5"), default="v3")
    args = parser.parse_args()
    initialization_base = {"v3": 350001000, "v4": 360001000, "v5": 370001000}[args.contract]
    seeds = tuple(initialization_base + index for index in (1, 2, 3))
    results = load_jsonl(ROOT / "experiments" / f"t1_{args.contract}_results.jsonl")
    selected = {}
    for seed in seeds:
        selected[seed] = max(
            (sum(row["consumed"] for row in results if row["arm"] == "trained" and row["initialization_seed"] == seed and row["checkpoint"] == checkpoint),
             sum(row["first_selected_available"] for row in results if row["arm"] == "trained" and row["initialization_seed"] == seed and row["checkpoint"] == checkpoint),
             -checkpoint, checkpoint)
            for checkpoint in (0, 10, 50, 200, 1000)
        )[3]
    campaign = {
        (row["initialization_seed"], row["card_seed"]): row
        for row in results
        if row["arm"] == "trained" and row["checkpoint"] == selected[row["initialization_seed"]]
    }
    replays = [row for seed in seeds for row in load_jsonl(
        ROOT / "experiments" / f"t1_{args.contract}_replay_{seed}.jsonl")]
    if len(replays) != 96 or len(campaign) != 96:
        raise RuntimeError("Lot de replay incomplet")
    for row in replays:
        key = row["initialization_seed"], row["card_seed"]
        if key not in campaign or any(row[field] != campaign[key][field] for field in FIELDS):
            raise RuntimeError(f"Replay divergent : {key}")
        if row["first_action"] != row["action_trace"][0]:
            raise RuntimeError(f"Trace invalide : {key}")
        if row["first_selected_available"] != (row["first_action"] == row["available_sector"]):
            raise RuntimeError(f"Métrique causale incohérente : {key}")
    categories = Counter()
    by_sector = defaultdict(Counter)
    by_distance = defaultdict(Counter)
    for row in replays:
        exact = row["first_selected_available"]
        progress = row["first_distance_progress"]
        angular_gap = min((row["first_action"] - row["available_sector"]) % 8,
                          (row["available_sector"] - row["first_action"]) % 8)
        categories["consumed"] += row["consumed"]
        categories["exact"] += exact
        categories["wrong"] += not exact
        categories["wrong_consumed"] += not exact and row["consumed"]
        categories["wrong_positive_progress"] += not exact and progress > 0.001
        categories["wrong_nonpositive_progress"] += not exact and progress <= 0.001
        categories["wrong_adjacent"] += not exact and angular_gap == 1
        categories["wrong_adjacent_consumed"] += not exact and angular_gap == 1 and row["consumed"]
        categories["wrong_toward_empty_sector"] += not exact and row["first_action"] in row["empty_sectors"]
        categories["wrong_toward_empty_consumed"] += not exact and row["first_action"] in row["empty_sectors"] and row["consumed"]
        by_sector[row["available_sector"]]["total"] += 1
        by_sector[row["available_sector"]]["exact"] += exact
        by_sector[row["available_sector"]]["consumed"] += row["consumed"]
        by_distance[row["available_distance_bin"]]["total"] += 1
        by_distance[row["available_distance_bin"]]["consumed"] += row["consumed"]
        by_distance[row["available_distance_bin"]]["wrong"] += not exact
        by_distance[row["available_distance_bin"]]["wrong_consumed"] += not exact and row["consumed"]
    print("checkpoints retenus :", selected)
    print("replays identiques à la campagne :", len(replays), "/ 96")
    print("premiers pas :", dict(categories))
    print("par secteur :", {key: dict(value) for key, value in sorted(by_sector.items())})
    print("par distance :", {key: dict(value) for key, value in sorted(by_distance.items())})
    failures = [row for row in replays if not row["consumed"]]
    print("échecs (3 exemples) :", [{"initialization_seed": row["initialization_seed"],
                                    "card_seed": row["card_seed"],
                                    "distance_bin": row["available_distance_bin"],
                                    "target": row["available_sector"],
                                    "actions": row["action_trace"]}
                                   for row in failures[:3]])
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
