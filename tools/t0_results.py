"""Valide les résultats d'évaluation T0 avant leur agrégation."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any


REQUIRED_FIELDS = {
    "experiment_id": str,
    "arm": str,
    "initialization_seed": int,
    "card_seed": int,
    "checkpoint": int,
    "success": bool,
    "terminated": bool,
    "truncated": bool,
    "table_checksum": str,
    "config_fingerprint": str,
}


def result_key(record: dict[str, Any]) -> tuple[str, str, int, int, int]:
    return (
        record["experiment_id"], record["arm"], record["initialization_seed"],
        record["card_seed"], record["checkpoint"],
    )


def validate_records(records: list[Any], expected_keys: set[tuple[str, str, int, int, int]]) -> list[str]:
    errors: list[str] = []
    observed: set[tuple[str, str, int, int, int]] = set()
    for index, record in enumerate(records):
        if not isinstance(record, dict):
            errors.append(f"résultat {index}: objet JSON attendu")
            continue
        for field, expected_type in REQUIRED_FIELDS.items():
            if field not in record:
                errors.append(f"résultat {index}: champ manquant {field}")
            elif type(record[field]) is not expected_type:
                errors.append(f"résultat {index}: champ invalide {field}")
        if any(field not in record for field in REQUIRED_FIELDS):
            continue
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


def load_expected(path: Path) -> set[tuple[str, str, int, int, int]]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(payload, list):
        raise ValueError("La liste des identifiants attendus doit être un tableau JSON.")
    return {result_key(record) for record in payload if isinstance(record, dict) and all(field in record for field in REQUIRED_FIELDS)}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("results", type=Path)
    parser.add_argument("--expected", required=True, type=Path)
    args = parser.parse_args()
    try:
        errors = validate_records(load_jsonl(args.results), load_expected(args.expected))
    except (OSError, ValueError, json.JSONDecodeError) as error:
        print(error, file=sys.stderr)
        return 1
    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
