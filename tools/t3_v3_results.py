"""Validation structurelle des résultats T3 v3."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

EXPERIMENT_ID = "t3_world_v3"
FINGERPRINT = "t3_world_v3|agents=4|fixed_competitors=3|ronces=24|berries=3|danger=0|hunger=50|depletion=4.0|vision=40|memory=5|actions=8|ticks=15|horizon=80|alpha=0.20|gamma=0.90|epsilon=0.20|progress=0.25|time_cost=0.01"
ARMS = {"scripted_food", "initial_frozen", "random_valid", "trained", "reset_each_episode"}
TRAINED_ARMS = {"trained", "reset_each_episode"}
CHECKPOINTS = {0, 10, 50, 200}
VALIDATION_SEEDS = set(range(410000101, 410000133))
INITIALIZATIONS = {410001001, 410001002, 410001003}
REQUIRED_FIELDS = {
    "experiment_id": str, "arm": str, "initialization_seed": int, "card_seed": int,
    "checkpoint": int, "survived": bool, "berries_picked": int, "berries_eaten": int,
    "terminated": bool, "truncated": bool, "actions": int, "table_checksum": str,
    "config_fingerprint": str,
}


def result_key(record: dict[str, Any]) -> tuple[str, str, int, int, int]:
    return (record["experiment_id"], record["arm"], record["initialization_seed"],
            record["card_seed"], record["checkpoint"])


def expected_t3_keys() -> set[tuple[str, str, int, int, int]]:
    return {
        (EXPERIMENT_ID, arm, initialization, card, checkpoint)
        for initialization in INITIALIZATIONS for card in VALIDATION_SEEDS for arm in ARMS
        for checkpoint in (CHECKPOINTS if arm in TRAINED_ARMS else {0})
    }


def validate_records(records: list[Any]) -> list[str]:
    errors: list[str] = []
    expected = expected_t3_keys()
    observed: set[tuple[str, str, int, int, int]] = set()
    for index, record in enumerate(records):
        if not isinstance(record, dict):
            errors.append(f"résultat {index}: objet JSON attendu")
            continue
        missing = [field for field in REQUIRED_FIELDS if field not in record]
        if missing:
            errors.extend(f"résultat {index}: champ manquant {field}" for field in missing)
            continue
        for field, field_type in REQUIRED_FIELDS.items():
            if type(record[field]) is not field_type:
                errors.append(f"résultat {index}: champ invalide {field}")
        if record["experiment_id"] != EXPERIMENT_ID or record["arm"] not in ARMS:
            errors.append(f"résultat {index}: identifiant expérimental invalide")
        if record["config_fingerprint"] != FINGERPRINT:
            errors.append(f"résultat {index}: empreinte invalide")
        if record["card_seed"] not in VALIDATION_SEEDS or record["initialization_seed"] not in INITIALIZATIONS:
            errors.append(f"résultat {index}: seed hors réserve")
        valid_checkpoints = CHECKPOINTS if record["arm"] in TRAINED_ARMS else {0}
        if record["checkpoint"] not in valid_checkpoints:
            errors.append(f"résultat {index}: checkpoint invalide")
        if type(record["actions"]) is int and not 1 <= record["actions"] <= 80:
            errors.append(f"résultat {index}: nombre d'actions invalide")
        if record["terminated"] == record["truncated"]:
            errors.append(f"résultat {index}: fin d'épisode invalide")
        if record["survived"] != (record["truncated"] and not record["terminated"]):
            errors.append(f"résultat {index}: survie incohérente")
        if min(record["berries_picked"], record["berries_eaten"]) < 0 or record["berries_eaten"] > record["berries_picked"]:
            errors.append(f"résultat {index}: compte alimentaire incohérent")
        key = result_key(record)
        if key in observed:
            errors.append(f"résultat {index}: doublon {key}")
        observed.add(key)
        if key not in expected:
            errors.append(f"résultat {index}: identifiant inattendu {key}")
    errors.extend(f"résultat manquant: {key}" for key in sorted(expected - observed))
    return errors


def load_jsonl(path: Path) -> list[Any]:
    return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line]
