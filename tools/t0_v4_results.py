"""Valide strictement les résultats préenregistrés de T0 v4."""

from __future__ import annotations

from typing import Any

try:
    from .t0_results import validate_records as validate_structure
except ImportError:
    from t0_results import validate_records as validate_structure

EXPERIMENT_ID = "t0_contract_v4"
FINGERPRINT = "t0_contract_v4|resource_distance=3.0|actions=8|ticks=15|horizon=48|alpha=0.20|gamma=0.90|progress=0.50"
INITIALIZATION_SEEDS = {340001001, 340001002, 340001003}
CARD_SEEDS = set(range(340000101, 340000133))
CHECKPOINTS = {0, 10, 50, 200, 1000}
ARMS = {"scripted", "initial_frozen", "random_valid", "trained", "reset_each_episode"}


def validate_records(records: list[Any], expected_keys: set[tuple[str, str, int, int, int]]) -> list[str]:
    errors = validate_structure(records, expected_keys)
    for index, record in enumerate(records):
        if not isinstance(record, dict):
            continue
        if record.get("experiment_id") != EXPERIMENT_ID:
            errors.append(f"résultat {index}: identifiant expérimental T0 v4 invalide")
        if record.get("config_fingerprint") != FINGERPRINT:
            errors.append(f"résultat {index}: empreinte T0 v4 invalide")
        if record.get("initialization_seed") not in INITIALIZATION_SEEDS:
            errors.append(f"résultat {index}: seed d'initialisation T0 v4 invalide")
        if record.get("card_seed") not in CARD_SEEDS:
            errors.append(f"résultat {index}: seed de carte T0 v4 invalide")
        if record.get("checkpoint") not in CHECKPOINTS or record.get("arm") not in ARMS:
            errors.append(f"résultat {index}: bras ou checkpoint T0 v4 invalide")
    return errors
