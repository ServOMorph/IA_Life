"""Évalue le gate gelé de confirmation T3 v3 (contrat de confirmation v1)."""

from __future__ import annotations

import argparse
import json
import random
from collections import defaultdict
from pathlib import Path

from t3_confirmation_results import ARMS, CARDS, CHECKPOINT, INITIALIZATIONS, load_jsonl, validate_records

ROOT = Path(__file__).resolve().parents[1]
BASELINES = ("initial_frozen", "random_valid")
BOOTSTRAPS = 20_000
BOOTSTRAP_SEED = 410003101
REPLAY_FIELDS = ("survived", "berries_picked", "berries_eaten", "terminated", "truncated", "actions")


def paired_values(groups, arm: str, cards) -> dict[tuple[int, int], float]:
    return {(seed, card): float(groups[(arm, seed, card)]["survived"])
            for seed in sorted(INITIALIZATIONS) for card in sorted(cards)}


def interval(candidate, reference, cards) -> tuple[float, float]:
    rng = random.Random(BOOTSTRAP_SEED)
    initializations = sorted(INITIALIZATIONS)
    ordered_cards = sorted(cards)
    differences = {seed: [candidate[(seed, card)] - reference[(seed, card)] for card in ordered_cards]
                   for seed in initializations}
    estimates = []
    for _ in range(BOOTSTRAPS):
        total = 0.0
        count = 0
        for seed in (rng.choice(initializations) for _ in initializations):
            sample = rng.choices(differences[seed], k=len(ordered_cards))
            total += sum(sample)
            count += len(sample)
        estimates.append(total / count)
    estimates.sort()
    return estimates[int(0.0125 * BOOTSTRAPS)], estimates[int(0.9875 * BOOTSTRAPS) - 1]


def rate(values) -> float:
    return sum(values.values()) / len(values)


def lineage_gains(candidate, reference, cards) -> dict[int, float]:
    return {seed: sum(candidate[(seed, card)] - reference[(seed, card)] for card in cards) / len(cards)
            for seed in sorted(INITIALIZATIONS)}


def meal_rate(groups, arm: str, cards) -> float:
    rows = [groups[(arm, seed, card)] for seed in INITIALIZATIONS for card in cards]
    return sum(row["berries_eaten"] > 0 for row in rows) / len(rows)


def replay_gate(label: str, groups, cards) -> dict[str, object]:
    errors: list[str] = []
    for seed in sorted(INITIALIZATIONS):
        path = ROOT / "experiments" / f"t3_confirmation_{label}_replay_{seed}.jsonl"
        if not path.exists():
            errors.append(f"replay absent {seed}")
            continue
        rows = load_jsonl(path)
        if {row["card_seed"] for row in rows} != set(cards) or len(rows) != len(cards):
            errors.append(f"replay incomplet {seed}")
        for row in rows:
            reference = groups.get(("trained", seed, row["card_seed"]))
            if reference is None or any(row[field] != reference[field] for field in REPLAY_FIELDS):
                errors.append(f"résultat divergent {seed}/{row['card_seed']}")
            elif row["table_checksum"] != reference["table_checksum"]:
                errors.append(f"checksum divergent {seed}/{row['card_seed']}")
            if len(row.get("action_trace", [])) != row["actions"]:
                errors.append(f"trace invalide {seed}/{row['card_seed']}")
    return {"ok": not errors, "errors": errors[:20]}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--cards", choices=("validation", "final"), required=True)
    args = parser.parse_args()
    label = "dryrun" if args.cards == "validation" else "final"
    cards = sorted(CARDS[args.cards])
    records = load_jsonl(ROOT / "experiments" / f"t3_confirmation_{label}_results.jsonl")
    errors = validate_records(records, args.cards)
    if errors:
        raise RuntimeError("\n".join(errors[:40]))
    groups = {(row["arm"], row["initialization_seed"], row["card_seed"]): row for row in records}
    values = {arm: paired_values(groups, arm, cards) for arm in ARMS}
    trained = values["trained"]
    gains = {arm: rate(trained) - rate(values[arm]) for arm in BASELINES}
    intervals = {arm: interval(trained, values[arm], cards) for arm in BASELINES}
    per_lineage = {arm: lineage_gains(trained, values[arm], cards) for arm in BASELINES}
    reset = values["reset_each_episode"]
    reset_intervals = {arm: interval(reset, values[arm], cards) for arm in BASELINES}
    reset_lineages = {arm: lineage_gains(reset, values[arm], cards) for arm in BASELINES}
    reset_meets_core = (
        rate(reset) >= 0.60
        and all(rate(reset) - rate(values[arm]) >= 0.10 for arm in BASELINES)
        and all(reset_intervals[arm][0] > 0 for arm in BASELINES)
        and all(all(gain > 0 for gain in reset_lineages[arm].values()) for arm in BASELINES)
    )
    trained_meals = meal_rate(groups, "trained", cards)
    replay = replay_gate(label, groups, cards)
    gates = {
        "scripted_solvable": rate(values["scripted_food"]) >= 0.90,
        "trained_survival": rate(trained) >= 0.60,
        "minimum_gains": all(gain >= 0.10 for gain in gains.values()),
        "positive_corrected_intervals": all(interval_[0] > 0 for interval_ in intervals.values()),
        "positive_lineage_gains": all(all(gain > 0 for gain in per_lineage[arm].values()) for arm in BASELINES),
        "food_non_regression": all(trained_meals + 0.05 >= meal_rate(groups, arm, cards) for arm in BASELINES),
        "persistence_ablation": not reset_meets_core,
        "reload_replay": bool(replay["ok"]),
    }
    summaries = {
        arm: {
            "survival_rate": rate(values[arm]),
            "survived": int(sum(values[arm].values())),
            "episodes": len(values[arm]),
            "meal_rate": meal_rate(groups, arm, cards),
            "berries_eaten": sum(groups[(arm, seed, card)]["berries_eaten"]
                                 for seed in INITIALIZATIONS for card in cards),
        }
        for arm in sorted(ARMS)
    }
    report = {
        "cards": args.cards,
        "checkpoint": CHECKPOINT,
        "gates": gates,
        "verdict": "critere_atteint" if all(gates.values()) else "critere_non_atteint_ou_indetermine",
        "summaries": summaries,
        "survival_gains": gains,
        "corrected_97_5_percent_intervals": intervals,
        "lineage_gains": {arm: {str(seed): gain for seed, gain in per_lineage[arm].items()} for arm in BASELINES},
        "reset_diagnostic": {
            "meets_core": reset_meets_core,
            "intervals": reset_intervals,
        },
        "replay": replay,
    }
    (ROOT / "experiments" / f"t3_confirmation_{label}_analysis.json").write_text(
        json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps(report, indent=2, sort_keys=True))
    return 0 if all(gates.values()) else 1


if __name__ == "__main__":
    raise SystemExit(main())
