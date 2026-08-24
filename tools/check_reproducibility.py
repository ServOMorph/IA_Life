"""Exécute deux fois une expérience et compare leurs résultats déterministes.

Usage : python tools/check_reproducibility.py experiments/telemetry_smoke_v1.json
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))

from run_headless import run_headless


def run_once(config: dict, timeout_seconds: int) -> dict:
    logs = ROOT / "logs"
    before = set(logs.glob("*.summary.json")) if logs.exists() else set()
    if run_headless(config, timeout_seconds):
        raise RuntimeError("L'exécution headless a échoué.")
    created = set(logs.glob("*.summary.json")) - before
    if len(created) != 1:
        raise RuntimeError("Une exécution doit produire exactement un summary.json.")
    return json.loads(created.pop().read_text(encoding="utf-8"))


def canonical_summary(summary: dict) -> dict:
    """Retire uniquement l'identifiant technique propre à chaque processus."""
    result = json.loads(json.dumps(summary))
    result.pop("session_id", None)
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description="Vérifie la reproductibilité seed-à-seed d'une expérience.")
    parser.add_argument("config", type=Path, help="Fichier ExperimentConfig JSON")
    parser.add_argument("--timeout", type=int, default=150, help="Timeout Python de sécurité par run")
    args = parser.parse_args()
    config = json.loads(args.config.read_text(encoding="utf-8"))

    try:
        first = canonical_summary(run_once(config, args.timeout))
        second = canonical_summary(run_once(config, args.timeout))
    except (OSError, ValueError, RuntimeError) as error:
        print(f"Échec de la vérification : {error}", file=sys.stderr)
        return 1

    if first != second:
        print("NON REPRODUCTIBLE : les summaries diffèrent pour la même configuration et la même seed.", file=sys.stderr)
        return 1
    print("REPRODUCTIBLE : deux runs ont produit des summaries strictement identiques (hors session_id).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
