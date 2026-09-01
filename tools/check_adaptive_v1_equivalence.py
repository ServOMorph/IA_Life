"""Verifie que le bras gele `adaptatif_v1` produit exactement le meme comportement
que `adaptatif` a seed fixe, tant que `scripts/adaptive_decider.gd` n'a pas ete modifie.

Prend un ExperimentConfig qui utilise `decider_type: "adaptatif"` pour au moins un agent.
Execute deux runs headless : l'original, puis une copie ou chaque `"adaptatif"` est
remplace par `"adaptatif_v1"`. Compare les resumes sur les seules grandeurs de
comportement (compteurs par agent, faim finale, duree de vie, positions, distances,
evenements execute), en ignorant `session_id`, le bloc `experiment` et le champ
`parameters` de chaque agent (qui differe par construction : decider_type, config_sha).

Sortie 0 si strictement identiques, 1 sinon (avec le premier ecart affiche).

Usage : python tools/check_adaptive_v1_equivalence.py experiments/apprentissage_faim_v2.json [--timeout 400]
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))

from run_headless import run_headless

LOGS = ROOT / "logs"


def run_once(config: dict, timeout_seconds: int) -> dict:
    before = set(LOGS.glob("*.summary.json")) if LOGS.exists() else set()
    if run_headless(config, timeout_seconds):
        raise RuntimeError("L'execution headless a echoue.")
    created = set(LOGS.glob("*.summary.json")) - before
    if len(created) != 1:
        raise RuntimeError(f"Une execution doit produire exactement un summary.json ({len(created)} trouves).")
    return json.loads(created.pop().read_text(encoding="utf-8"))


def swap_to_v1(node):
    if isinstance(node, dict):
        return {k: ("adaptatif_v1" if k == "decider_type" and v == "adaptatif" else swap_to_v1(v)) for k, v in node.items()}
    if isinstance(node, list):
        return [swap_to_v1(item) for item in node]
    return node


def behavioral_view(summary: dict) -> dict:
    result = json.loads(json.dumps(summary))
    result.pop("session_id", None)
    result.pop("experiment", None)
    for agent in result.get("agents", []):
        agent.pop("parameters", None)
    return result


def first_difference(a, b, path: str = "") -> str | None:
    if type(a) is not type(b):
        return f"{path or '<racine>'} : types differents ({type(a).__name__} vs {type(b).__name__})"
    if isinstance(a, dict):
        for key in sorted(set(a) | set(b)):
            if key not in a:
                return f"{path}.{key} : absent du run adaptatif"
            if key not in b:
                return f"{path}.{key} : absent du run adaptatif_v1"
            diff = first_difference(a[key], b[key], f"{path}.{key}")
            if diff:
                return diff
        return None
    if isinstance(a, list):
        if len(a) != len(b):
            return f"{path} : longueurs differentes ({len(a)} vs {len(b)})"
        for index, (item_a, item_b) in enumerate(zip(a, b)):
            diff = first_difference(item_a, item_b, f"{path}[{index}]")
            if diff:
                return diff
        return None
    if a != b:
        return f"{path} : {a!r} (adaptatif) != {b!r} (adaptatif_v1)"
    return None


def main() -> int:
    parser = argparse.ArgumentParser(description="Equivalence adaptatif / adaptatif_v1 a seed fixe.")
    parser.add_argument("config", type=Path, help="ExperimentConfig JSON avec un agent en decider_type 'adaptatif'")
    parser.add_argument("--timeout", type=int, default=400, help="Timeout Python de securite par run")
    args = parser.parse_args()

    config = json.loads(args.config.read_text(encoding="utf-8"))
    config_v1 = swap_to_v1(config)
    if json.dumps(config, sort_keys=True) == json.dumps(config_v1, sort_keys=True):
        print("Refuse : la config ne contient aucun decider_type 'adaptatif' a comparer.", file=sys.stderr)
        return 1

    try:
        base = behavioral_view(run_once(config, args.timeout))
        v1 = behavioral_view(run_once(config_v1, args.timeout))
    except (OSError, ValueError, RuntimeError) as error:
        print(f"Echec de la verification : {error}", file=sys.stderr)
        return 1

    diff = first_difference(base, v1)
    if diff:
        print("NON EQUIVALENT : adaptatif et adaptatif_v1 divergent a seed fixe.", file=sys.stderr)
        print(f"  Premier ecart : {diff}", file=sys.stderr)
        return 1
    print("EQUIVALENT : adaptatif_v1 reproduit adaptatif bit a bit (comportement, hors parametres).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
