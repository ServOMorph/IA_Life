"""Évalue le gate préenregistré T3 v2."""

from __future__ import annotations

import argparse
import json
import random
from collections import defaultdict
from pathlib import Path

from t3_results import INITIALIZATIONS, VALIDATION_SEEDS, load_jsonl, validate_records

ROOT = Path(__file__).resolve().parents[1]
CHECKPOINTS = (0, 10, 50, 200)
TRAINED_ARMS = ("trained", "reset_each_episode")
BASELINES = ("initial_frozen", "random_valid")
BOOTSTRAPS = 20_000
BOOTSTRAP_SEED = 400003001


def select_checkpoints(groups, arm: str) -> dict[int, int]:
    selected = {}
    for seed in sorted(INITIALIZATIONS):
        candidates = []
        for checkpoint in CHECKPOINTS:
            rows = groups[(arm, seed, checkpoint)]
            candidates.append((sum(row["survived"] for row in rows),
                               sum(row["berries_eaten"] > 0 for row in rows),
                               sum(row["berries_eaten"] for row in rows),
                               -checkpoint, checkpoint))
        selected[seed] = max(candidates)[4]
    return selected


def paired_values(groups, selected, arm: str) -> dict[tuple[int, int], float]:
    values = {}
    for seed in INITIALIZATIONS:
        checkpoint = selected[arm][seed] if arm in TRAINED_ARMS else 0
        for row in groups[(arm, seed, checkpoint)]:
            values[(seed, row["card_seed"])] = float(row["survived"])
    return values


def hierarchical_interval(candidate, reference) -> tuple[float, float]:
    rng = random.Random(BOOTSTRAP_SEED)
    initializations = sorted(INITIALIZATIONS)
    cards = sorted(VALIDATION_SEEDS)
    estimates = []
    for _ in range(BOOTSTRAPS):
        sampled_initializations = [rng.choice(initializations) for _ in initializations]
        differences = []
        for seed in sampled_initializations:
            sampled_cards = [rng.choice(cards) for _ in cards]
            differences.extend(candidate[(seed, card)] - reference[(seed, card)] for card in sampled_cards)
        estimates.append(sum(differences) / len(differences))
    estimates.sort()
    return estimates[int(0.0125 * BOOTSTRAPS)], estimates[int(0.9875 * BOOTSTRAPS) - 1]


def arm_summary(groups, selected, arm: str) -> dict[str, float | int]:
    rows = []
    for seed in sorted(INITIALIZATIONS):
        checkpoint = selected[arm][seed] if arm in TRAINED_ARMS else 0
        rows.extend(groups[(arm, seed, checkpoint)])
    return {
        "survived": sum(row["survived"] for row in rows),
        "episodes": len(rows),
        "meal_episodes": sum(row["berries_eaten"] > 0 for row in rows),
        "berries_eaten": sum(row["berries_eaten"] for row in rows),
    }


def main() -> int:
    global INITIALIZATIONS, VALIDATION_SEEDS, load_jsonl, validate_records, BOOTSTRAP_SEED
    parser = argparse.ArgumentParser()
    parser.add_argument("--contract", choices=("v2", "v3"), default="v2")
    args = parser.parse_args()
    if args.contract == "v3":
        from t3_v3_results import INITIALIZATIONS as v3_initializations
        from t3_v3_results import VALIDATION_SEEDS as v3_validation_seeds
        from t3_v3_results import load_jsonl as v3_load_jsonl
        from t3_v3_results import validate_records as v3_validate_records
        INITIALIZATIONS = v3_initializations
        VALIDATION_SEEDS = v3_validation_seeds
        load_jsonl = v3_load_jsonl
        validate_records = v3_validate_records
        BOOTSTRAP_SEED = 410003001
    records = load_jsonl(ROOT / "experiments" / f"t3_{args.contract}_results.jsonl")
    errors = validate_records(records)
    if errors:
        raise RuntimeError("\n".join(errors[:40]))
    groups = defaultdict(list)
    for record in records:
        groups[(record["arm"], record["initialization_seed"], record["checkpoint"])].append(record)
    selected = {arm: select_checkpoints(groups, arm) for arm in TRAINED_ARMS}
    summaries = {arm: arm_summary(groups, selected, arm)
                 for arm in ("scripted_food", "initial_frozen", "random_valid") + TRAINED_ARMS}
    trained_values = paired_values(groups, selected, "trained")
    intervals = {}
    gains = {}
    for reference_arm in BASELINES:
        reference_values = paired_values(groups, selected, reference_arm)
        gains[reference_arm] = sum(trained_values[key] - reference_values[key] for key in trained_values) / len(trained_values)
        intervals[reference_arm] = hierarchical_interval(trained_values, reference_values)

    def lineage_gain_positive(reference_arm: str) -> bool:
        reference = paired_values(groups, selected, reference_arm)
        return all(sum(trained_values[(seed, card)] - reference[(seed, card)] for card in VALIDATION_SEEDS) > 0
                   for seed in INITIALIZATIONS)

    trained_rate = summaries["trained"]["survived"] / summaries["trained"]["episodes"]
    reset_rate = summaries["reset_each_episode"]["survived"] / summaries["reset_each_episode"]["episodes"]
    reset_values = paired_values(groups, selected, "reset_each_episode")
    reset_meets_core = (
        reset_rate >= 0.60
        and all(sum(reset_values[key] - paired_values(groups, selected, arm)[key] for key in reset_values) / len(reset_values) >= 0.10 for arm in BASELINES)
        and all(hierarchical_interval(reset_values, paired_values(groups, selected, arm))[0] > 0 for arm in BASELINES)
        and all(all(sum(reset_values[(seed, card)] - paired_values(groups, selected, arm)[(seed, card)] for card in VALIDATION_SEEDS) > 0
                    for seed in INITIALIZATIONS) for arm in BASELINES)
    )
    trained_meal_rate = summaries["trained"]["meal_episodes"] / summaries["trained"]["episodes"]
    gates = {
        "scripted_solvable": summaries["scripted_food"]["survived"] / summaries["scripted_food"]["episodes"] >= 0.90,
        "trained_survival": trained_rate >= 0.60,
        "minimum_gains": all(gain >= 0.10 for gain in gains.values()),
        "positive_corrected_intervals": all(interval[0] > 0 for interval in intervals.values()),
        "positive_lineage_gains": all(lineage_gain_positive(arm) for arm in BASELINES),
        "food_non_regression": all(trained_meal_rate + 0.05 >= summaries[arm]["meal_episodes"] / summaries[arm]["episodes"] for arm in BASELINES),
        "persistence_ablation": not reset_meets_core,
    }
    report = {
        "selected_checkpoints": selected,
        "summaries": summaries,
        "survival_gains": gains,
        "corrected_97_5_percent_intervals": intervals,
        "gates": gates,
    }
    (ROOT / "experiments" / f"t3_{args.contract}_analysis.json").write_text(
        json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps(report, indent=2, sort_keys=True))
    return 0 if all(gates.values()) else 1


if __name__ == "__main__":
    raise SystemExit(main())
