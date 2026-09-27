"""Valide les résultats T1 avant agrégation."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any

REQUIRED_FIELDS = {
    "experiment_id": str, "arm": str, "initialization_seed": int, "card_seed": int,
    "checkpoint": int, "consumed": bool, "first_selected_available": bool,
    "berries_picked": int, "berries_eaten": int, "terminated": bool, "truncated": bool,
    "actions": int, "table_checksum": str, "config_fingerprint": str,
}
VALID_ARMS = {"scripted_observed", "initial_frozen", "random_valid", "trained", "reset_each_episode"}
VALID_SEEDS = set(range(320000101, 320000133))
VALID_INITIALIZATIONS = {320001001, 320001002, 320001003}
CHECKPOINTS = {0, 10, 50, 200, 1000}
EXPERIMENT_ID = "t1_choice_v2"
FINGERPRINT = "t1_choice_v2|targets=3|available=1|distances=3,6,9|actions=8|ticks=15|horizon=24|alpha=0.20|gamma=0.90|progress=0.50|state=available_sector_distance_previous"
FINGERPRINT_V3 = "t1_choice_v3|targets=3|available=1|distances=3,6,9|actions=8|ticks=15|horizon=24|alpha=0.20|gamma=0.90|progress=0.50|first_bandit=sector|first_epsilon=0.50"
FINGERPRINT_V4 = "t1_choice_v4|targets=3|available=1|distances=3,6,9|actions=8|ticks=15|horizon=24|alpha=0.20|gamma=0.90|progress=0.50|first_explore=min_count|first_tie=lowest"


def contract_values(contract: str):
    if contract == "v2":
        return EXPERIMENT_ID, FINGERPRINT, VALID_SEEDS, VALID_INITIALIZATIONS
    if contract == "v3":
        return "t1_choice_v3", FINGERPRINT_V3, set(range(350000101, 350000133)), {350001001, 350001002, 350001003}
    if contract == "v4":
        return "t1_choice_v4", FINGERPRINT_V4, set(range(360000101, 360000133)), {360001001, 360001002, 360001003}
    raise ValueError(f"contrat T1 inconnu : {contract}")


def expected_t1_keys(contract: str = "v2") -> set[tuple[str, str, int, int, int]]:
    experiment_id, _, valid_seeds, valid_initializations = contract_values(contract)
    return {
        (experiment_id, arm, initialization_seed, card_seed, checkpoint)
        for initialization_seed in valid_initializations
        for card_seed in valid_seeds
        for arm in VALID_ARMS
        for checkpoint in (CHECKPOINTS if arm in {"trained", "reset_each_episode"} else {0})
    }


def result_key(record: dict[str, Any]) -> tuple[str, str, int, int, int]:
    return (record["experiment_id"], record["arm"], record["initialization_seed"], record["card_seed"], record["checkpoint"])


def validate_records(records: list[Any], expected_keys: set[tuple[str, str, int, int, int]], contract: str = "v2") -> list[str]:
    experiment_id, fingerprint, valid_seeds, valid_initializations = contract_values(contract)
    errors: list[str] = []
    observed: set[tuple[str, str, int, int, int]] = set()
    for index, record in enumerate(records):
        if not isinstance(record, dict):
            errors.append(f"résultat {index}: objet JSON attendu")
            continue
        missing = [field for field in REQUIRED_FIELDS if field not in record]
        for field in missing:
            errors.append(f"résultat {index}: champ manquant {field}")
        if missing:
            continue
        for field, field_type in REQUIRED_FIELDS.items():
            if type(record[field]) is not field_type:
                errors.append(f"résultat {index}: champ invalide {field}")
        if record["experiment_id"] != experiment_id or record["arm"] not in VALID_ARMS:
            errors.append(f"résultat {index}: identifiant expérimental invalide")
        if record["config_fingerprint"] != fingerprint:
            errors.append(f"résultat {index}: empreinte invalide")
        if record["card_seed"] not in valid_seeds or record["initialization_seed"] not in valid_initializations:
            errors.append(f"résultat {index}: seed hors réserve")
        if record["checkpoint"] not in CHECKPOINTS:
            errors.append(f"résultat {index}: checkpoint invalide")
        if type(record["actions"]) is int and not 1 <= record["actions"] <= 24:
            errors.append(f"résultat {index}: nombre d'actions invalide")
        if type(record["terminated"]) is bool and type(record["truncated"]) is bool and record["terminated"] == record["truncated"]:
            errors.append(f"résultat {index}: fin d'épisode invalide")
        if type(record["consumed"]) is bool and type(record["berries_eaten"]) is int and record["consumed"] != (record["berries_eaten"] > 0):
            errors.append(f"résultat {index}: consommation incohérente")
        key = result_key(record)
        if key in observed:
            errors.append(f"résultat {index}: doublon {key}")
        observed.add(key)
        if key not in expected_keys:
            errors.append(f"résultat {index}: identifiant inattendu {key}")
    for key in sorted(expected_keys - observed):
        errors.append(f"résultat manquant: {key}")
    return errors


def load_jsonl(path: Path) -> list[Any]:
    return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("results", type=Path)
    parser.add_argument("--expected", type=Path)
    parser.add_argument("--contract", choices=("v2", "v3", "v4"), default="v2")
    args = parser.parse_args()
    try:
        expected = {result_key(item) for item in json.loads(args.expected.read_text(encoding="utf-8"))} if args.expected else expected_t1_keys(args.contract)
        errors = validate_records(load_jsonl(args.results), expected, args.contract)
    except (OSError, ValueError, json.JSONDecodeError, KeyError) as error:
        print(error, file=sys.stderr)
        return 1
    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
