"""Gate Phase 3 (roadmap_environnement_apprenable_v3) : calibration des zones dangereuses.

Lit les runs d'une campagne (dossiers `run_*/` contenant chacun un
`*.summary.json`), les regroupe par point de la grille de calibration
(`metadata.campaign_parameters`) puis par bras et par seed, et applique les
quatre criteres du gate ecrits dans `roadmap_environnement_apprenable_v3.md`
(Phase 3) sur chaque point :

  1. `danger_eviter` subit moins de cout de danger (`danger_hunger_cost_total`)
     que `danger_viser` sur au moins 10/12 seeds.
  2. `danger_eviter` bat `danger_viser` sur le resultat (comparaison
     lexicographique survie, mures mangees, duree de vie) dans le meme sens
     sur au moins 9/12 seeds.
  3. `danger_eviter` bat `aleatoire` sur le resultat, meme mesure, sur au
     moins 9/12 seeds.
  4. La survie n'est ni triviale ni effondree : parmi les quatre bras
     (eviter/ignorer/viser/aleatoire), la meilleure survie moyenne du point
     est entre 0,50 et 0,90 et la pire au plus a 0,40.

Les points qui passent les quatre criteres sont classes par accord du
critere 2 (nombre de seeds ou eviter bat viser), puis par ecart de survie
moyenne eviter - viser, decroissant — reprend le principe de classement
"separation des politiques" de la Phase 1 (`oracle_report.py`).

Usage : python tools/check_danger_calibration.py results/_danger_zone_oracle_v3 --agent Rouge
"""

from __future__ import annotations

import argparse
import json
from collections import defaultdict
from pathlib import Path
from typing import Any


REQUIRED_ARMS = ("danger_eviter", "danger_ignorer", "danger_viser", "aleatoire")


def load_runs(results_dir: Path, agent: str) -> list[dict[str, Any]]:
    runs = []
    for summary_path in sorted(results_dir.glob("run_*/*.summary.json")):
        payload = json.loads(summary_path.read_text(encoding="utf-8"))
        experiment = payload["experiment"]
        metadata = experiment.get("metadata", {})
        arm = metadata.get("arm", "")
        params = metadata.get("campaign_parameters", {})
        agent_summary = next((a for a in payload["agents"] if a["name"] == agent), None)
        if agent_summary is None:
            raise ValueError(f"{summary_path} : agent '{agent}' introuvable")
        runs.append({
            "path": summary_path,
            "arm": arm,
            "seed": experiment["seed"],
            "grid_key": tuple(sorted(params.items())),
            "alive": bool(agent_summary["alive"]),
            "berries": float(agent_summary["berries_eaten_total"]),
            "lifetime": float(agent_summary["lifetime_seconds"]),
            "danger_cost": float(agent_summary["danger_hunger_cost_total"]),
        })
    return runs


def result_tuple(run: dict[str, Any]) -> tuple[int, float, float]:
    """Comparaison lexicographique : survie, mures mangees, duree de vie."""
    return (int(run["alive"]), run["berries"], run["lifetime"])


def group_by_grid(runs: list[dict[str, Any]]) -> dict[tuple, dict[str, dict[int, dict[str, Any]]]]:
    grid: dict[tuple, dict[str, dict[int, dict[str, Any]]]] = defaultdict(lambda: defaultdict(dict))
    for run in runs:
        grid[run["grid_key"]][run["arm"]][run["seed"]] = run
    return grid


def evaluate_point(grid_key: tuple, arms: dict[str, dict[int, dict[str, Any]]], n_seeds: int) -> dict[str, Any]:
    missing = [a for a in REQUIRED_ARMS if a not in arms or len(arms[a]) != n_seeds]
    if missing:
        return {"grid_key": grid_key, "incomplete": missing}

    seeds = sorted(arms["danger_eviter"])
    for arm in REQUIRED_ARMS:
        if sorted(arms[arm]) != seeds:
            return {"grid_key": grid_key, "incomplete": [f"{arm}:seeds_mismatch"]}

    eviter, viser, ignorer, aleatoire = (arms[a] for a in REQUIRED_ARMS)

    cost_agree = sum(1 for s in seeds if eviter[s]["danger_cost"] < viser[s]["danger_cost"])
    result_agree_viser = sum(1 for s in seeds if result_tuple(eviter[s]) > result_tuple(viser[s]))
    result_agree_aleatoire = sum(1 for s in seeds if result_tuple(eviter[s]) > result_tuple(aleatoire[s]))

    survivals = {
        arm: sum(arms[arm][s]["alive"] for s in seeds) / len(seeds)
        for arm in REQUIRED_ARMS
    }
    best_survival = max(survivals.values())
    worst_survival = min(survivals.values())

    criterion_1 = cost_agree >= 10
    criterion_2 = result_agree_viser >= 9
    criterion_3 = result_agree_aleatoire >= 9
    criterion_4 = 0.50 <= best_survival <= 0.90 and worst_survival <= 0.40

    return {
        "grid_key": grid_key,
        "incomplete": [],
        "n_seeds": len(seeds),
        "cost_agree": cost_agree,
        "result_agree_viser": result_agree_viser,
        "result_agree_aleatoire": result_agree_aleatoire,
        "survivals": survivals,
        "best_survival": best_survival,
        "worst_survival": worst_survival,
        "criteria": {
            "1_cost_eviter_lt_viser": criterion_1,
            "2_result_eviter_beats_viser": criterion_2,
            "3_result_eviter_beats_aleatoire": criterion_3,
            "4_survival_not_trivial_not_collapsed": criterion_4,
        },
        "gate_passed": criterion_1 and criterion_2 and criterion_3 and criterion_4,
        "eviter_survival": survivals["danger_eviter"],
        "viser_survival": survivals["danger_viser"],
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Gate Phase 3 (calibration zones dangereuses).")
    parser.add_argument("results_dir", type=Path)
    parser.add_argument("--agent", default="Rouge")
    parser.add_argument("--n-seeds", type=int, default=12)
    parser.add_argument("--json", type=Path, default=None, help="Ecrit le rapport complet en JSON")
    args = parser.parse_args()

    runs = load_runs(args.results_dir, args.agent)
    if not runs:
        print(f"Aucun run trouve sous {args.results_dir}")
        return 1

    grid = group_by_grid(runs)
    points = [evaluate_point(key, arms, args.n_seeds) for key, arms in grid.items()]

    incomplete = [p for p in points if p["incomplete"]]
    for p in incomplete:
        print(f"INCOMPLET {dict(p['grid_key'])} : {p['incomplete']}")

    complete = [p for p in points if not p["incomplete"]]
    passed = [p for p in complete if p["gate_passed"]]
    passed.sort(key=lambda p: (p["result_agree_viser"], p["eviter_survival"] - p["viser_survival"]), reverse=True)

    print(f"\n{len(complete)} points de grille evalues, {len(passed)} passent le gate causal.\n")
    for p in complete:
        key_str = ", ".join(f"{k.split('.')[-1]}={v}" for k, v in p["grid_key"])
        status = "PASSE" if p["gate_passed"] else "echec"
        print(
            f"[{status}] {key_str} | cout eviter<viser: {p['cost_agree']}/{p['n_seeds']} "
            f"| resultat eviter>viser: {p['result_agree_viser']}/{p['n_seeds']} "
            f"| resultat eviter>aleatoire: {p['result_agree_aleatoire']}/{p['n_seeds']} "
            f"| survie best={p['best_survival']:.2f} worst={p['worst_survival']:.2f} "
            f"| survivals={ {a: round(v, 2) for a, v in p['survivals'].items()} }"
        )

    if passed:
        print("\nMeilleur candidat (classe par accord resultat eviter>viser puis ecart de survie) :")
        best = passed[0]
        print(f"  {dict(best['grid_key'])}")
        print(f"  survivals={best['survivals']}")
    else:
        print("\nBRANCHE ECHEC : aucun point de grille ne passe les quatre criteres.")

    if args.json:
        args.json.write_text(json.dumps({"points": [
            {**p, "grid_key": dict(p["grid_key"])} for p in points
        ]}, indent=2, ensure_ascii=False), encoding="utf-8")

    return 0 if passed else 1


if __name__ == "__main__":
    raise SystemExit(main())
