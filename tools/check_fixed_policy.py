"""Verifie le decideur `politique_fixe` (Phase 1 de roadmap_apprentissage_v2).

Trois proprietes, sur un ExperimentConfig ou au moins un agent est en
`decider_type: "politique_fixe"` :

  1. Determinisme     : deux runs de la meme config donnent des resumes identiques
                        (hors session_id, bloc experiment, parametres par agent).
  2. Aucun apprentissage : le run n'emet aucun evenement `apprentissage_maj` ni
                        `apprentissage_table` (la table reste figee), mais bien des
                        `apprentissage_decision` (le chemin de faim est exerce).
  3. Politiques distinctes : forcer `fixed_policy_s1`, `fixed_policy_s2` et `fixed_policy_s3` a "errance"
                        produit un comportement different de la config d'origine. Exige
                        qu'au moins une decision S1 ou S2 ait ete prise dans le run de
                        reference (sinon le choix de politique n'est pas exerce et le test
                        est declare inconclusif).

Sortie 0 si les trois passent, 1 sinon.

Usage : python tools/check_fixed_policy.py experiments/p1_fixed_policy_selftest.json [--timeout 200]
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


def run_once(config: dict, timeout_seconds: int) -> tuple[dict, Path]:
    before = set(LOGS.glob("*.summary.json")) if LOGS.exists() else set()
    if run_headless(config, timeout_seconds):
        raise RuntimeError("L'execution headless a echoue.")
    created = set(LOGS.glob("*.summary.json")) - before
    if len(created) != 1:
        raise RuntimeError(f"Une execution doit produire exactement un summary.json ({len(created)} trouves).")
    summary_path = created.pop()
    jsonl_path = summary_path.with_name(summary_path.name.removesuffix(".summary.json") + ".jsonl")
    return json.loads(summary_path.read_text(encoding="utf-8")), jsonl_path


def force_wander(node):
    if isinstance(node, dict):
        out = {}
        for k, v in node.items():
            if k in ("fixed_policy_s1", "fixed_policy_s2", "fixed_policy_s3") and v != "errance":
                out[k] = "errance"
            else:
                out[k] = force_wander(v)
        return out
    if isinstance(node, list):
        return [force_wander(item) for item in node]
    return node


def has_fixed_policy(node) -> bool:
    if isinstance(node, dict):
        if node.get("decider_type") == "politique_fixe":
            return True
        return any(has_fixed_policy(v) for v in node.values())
    if isinstance(node, list):
        return any(has_fixed_policy(item) for item in node)
    return False


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
                return f"{path}.{key} : absent du premier run"
            if key not in b:
                return f"{path}.{key} : absent du second run"
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
        return f"{path} : {a!r} != {b!r}"
    return None


def event_categories(jsonl_path: Path) -> set[str]:
    categories: set[str] = set()
    for line in jsonl_path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            categories.add(json.loads(line).get("category", ""))
        except json.JSONDecodeError:
            continue
    return categories


def decision_situations(jsonl_path: Path) -> set[str]:
    situations: set[str] = set()
    for line in jsonl_path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            event = json.loads(line)
        except json.JSONDecodeError:
            continue
        if event.get("category") == "apprentissage_decision":
            situations.add(event.get("data", {}).get("situation", ""))
    return situations


def main() -> int:
    parser = argparse.ArgumentParser(description="Verification du decideur politique_fixe.")
    parser.add_argument("config", type=Path, help="ExperimentConfig JSON avec un agent en decider_type 'politique_fixe'")
    parser.add_argument("--timeout", type=int, default=200, help="Timeout Python de securite par run")
    args = parser.parse_args()

    config = json.loads(args.config.read_text(encoding="utf-8"))
    if not has_fixed_policy(config):
        print("Refuse : la config ne contient aucun decider_type 'politique_fixe'.", file=sys.stderr)
        return 1
    config_wander = force_wander(config)
    if json.dumps(config, sort_keys=True) == json.dumps(config_wander, sort_keys=True):
        print("Refuse : fixed_policy_s1, fixed_policy_s2 et fixed_policy_s3 valent deja 'errance', test 3 sans objet.", file=sys.stderr)
        return 1

    try:
        run_a_summary, run_a_jsonl = run_once(config, args.timeout)
        run_b_summary, _ = run_once(config, args.timeout)
        run_c_summary, _ = run_once(config_wander, args.timeout)
    except (OSError, ValueError, RuntimeError) as error:
        print(f"Echec de la verification : {error}", file=sys.stderr)
        return 1

    ok = True

    diff = first_difference(behavioral_view(run_a_summary), behavioral_view(run_b_summary))
    if diff:
        print("ECHEC test 1 (determinisme) : deux runs identiques divergent.", file=sys.stderr)
        print(f"  Premier ecart : {diff}", file=sys.stderr)
        ok = False
    else:
        print("OK test 1 : deux runs de la meme config sont identiques.")

    categories = event_categories(run_a_jsonl)
    forbidden = {"apprentissage_maj", "apprentissage_table"} & categories
    if forbidden:
        print(f"ECHEC test 2 (aucun apprentissage) : evenements interdits emis : {sorted(forbidden)}", file=sys.stderr)
        ok = False
    elif "apprentissage_decision" not in categories:
        print("ECHEC test 2 : aucun evenement apprentissage_decision, le chemin de faim n'a pas ete exerce.", file=sys.stderr)
        ok = False
    else:
        print("OK test 2 : aucune mise a jour de score, chemin de faim exerce.")

    situations = decision_situations(run_a_jsonl)
    choiceful = {"S1_ronce_visible", "S2_memoire"} & situations
    if not choiceful:
        print(f"INCONCLUSIF test 3 : ni S1 ni S2 rencontrés (situations vues : {sorted(situations)}). "
              "Choisir une config selftest ou le choix de politique est exerce.", file=sys.stderr)
        ok = False
    else:
        diff = first_difference(behavioral_view(run_a_summary), behavioral_view(run_c_summary))
        if diff:
            print(f"OK test 3 : politique errance produit un comportement different ({sorted(choiceful)} exercees).")
        else:
            print("ECHEC test 3 (politiques distinctes) : tout en errance ne change rien au resultat.", file=sys.stderr)
            ok = False

    if ok:
        print("SUCCES : decideur politique_fixe deterministe, fige et sensible a la politique.")
        return 0
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
