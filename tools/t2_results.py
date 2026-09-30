"""Validation structurelle des résultats T2 v1."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

EXPERIMENT_ID = "t2_memory_v1"
FINGERPRINT = "t2_memory_v1|target=1|distances=3,6,9|sectors=8|fov=90|turn=180|actions=8|ticks=15|horizon=24|alpha=0.20|progress=0.50|explore=min_count|execution=hold_first"
ARMS = {"scripted_memory", "initial_memory_frozen", "random_valid", "trained_memory", "trained_observation_only", "reset_each_episode"}
TRAINED_ARMS = {"trained_memory", "trained_observation_only", "reset_each_episode"}
CHECKPOINTS = {0, 10, 50, 200, 1000}
VALIDATION_SEEDS = set(range(380000101, 380000133))
INITIALIZATIONS = {380001001, 380001002, 380001003}
REQUIRED_FIELDS = {
    "experiment_id": str, "arm": str, "initialization_seed": int, "card_seed": int,
    "checkpoint": int, "consumed": bool, "selected_remembered_sector": bool,
    "berries_picked": int, "berries_eaten": int, "terminated": bool, "truncated": bool,
    "actions": int, "policy_decisions": int, "table_checksum": str, "config_fingerprint": str,
}


def result_key(record: dict[str, Any]) -> tuple[str, str, int, int, int]:
    return (record["experiment_id"], record["arm"], record["initialization_seed"], record["card_seed"], record["checkpoint"])


def expected_t2_keys() -> set[tuple[str, str, int, int, int]]:
    return {
        (EXPERIMENT_ID, arm, initialization, card, checkpoint)
        for initialization in INITIALIZATIONS
        for card in VALIDATION_SEEDS
        for arm in ARMS
        for checkpoint in (CHECKPOINTS if arm in TRAINED_ARMS else {0})
    }


def validate_records(records: list[Any]) -> list[str]:
    errors: list[str] = []
    expected = expected_t2_keys()
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
        if record["checkpoint"] not in CHECKPOINTS:
            errors.append(f"résultat {index}: checkpoint invalide")
        if type(record["actions"]) is int and not 1 <= record["actions"] <= 24:
            errors.append(f"résultat {index}: nombre d'actions invalide")
        if record["policy_decisions"] != 1:
            errors.append(f"résultat {index}: nombre de décisions invalide")
        if record["terminated"] == record["truncated"]:
            errors.append(f"résultat {index}: fin d'épisode invalide")
        if record["consumed"] != (record["berries_picked"] == 1 and record["berries_eaten"] == 1):
            errors.append(f"résultat {index}: consommation incohérente")
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
