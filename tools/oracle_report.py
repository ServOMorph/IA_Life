"""Evalue le gate de la Phase 1 de roadmap_apprentissage_v2 sur une campagne d'oracle.

Lit un dossier de resultats de campagne (sous-dossiers run_*/ avec manifest.json + summary
archive), regroupe par environnement (combinaison de la grille) puis par bras, et pour
chaque environnement :

  - taux de survie, duree de vie mediane, mures mangees moyennes de l'agent apprenant,
    par bras ;
  - meilleure et pire politique FIXE (prefixe --fixed-prefix, defaut "pf_") ;
  - test des signes apparie au seed, meilleure vs pire, sur lifetime_seconds
    (mures mangees en secondaire quand la duree de vie est a egalite) ;
  - gate : meilleure survie >= --best-min (0.70), pire survie <= --worst-max (0.30),
    accord du test des signes >= --min-agree (9) sur --n-seeds (12).

Verdict final : le ou les environnements qui passent le gate, classes par ecart de survie ;
sinon, message explicite (roadmap : remonter le choix a l'utilisateur).

Usage : python tools/oracle_report.py results/_p1_oracle_env_sweep --agent Rouge [--json rapport.json]
"""

from __future__ import annotations

import argparse
import json
import math
import statistics
import sys
from collections import defaultdict
from pathlib import Path
from typing import Any


def load_runs(results_dir: Path, agent_name: str) -> list[dict[str, Any]]:
    runs: list[dict[str, Any]] = []
    for manifest_path in sorted(results_dir.glob("*/manifest.json")):
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        if manifest.get("status") != "completed":
            continue
        summary_name = manifest.get("summary")
        if not summary_name:
            continue
        summary_path = manifest_path.parent / summary_name
        if not summary_path.exists():
            continue
        summary = json.loads(summary_path.read_text(encoding="utf-8"))
        agent = next((a for a in summary.get("agents", []) if a.get("name") == agent_name), None)
        if agent is None:
            continue
        runs.append({
            "env_key": json.dumps(manifest.get("parameters", {}), sort_keys=True),
            "env": manifest.get("parameters", {}),
            "arm": manifest.get("arm", ""),
            "seed": manifest.get("seed"),
            "alive": bool(agent.get("alive", False)),
            "lifetime": float(agent.get("lifetime_seconds", 0.0)),
            "berries_eaten": float(agent.get("berries_eaten_total", 0.0)),
        })
    return runs


def sign_test_agreement(pairs: list[tuple[float, float]]) -> tuple[int, int, int]:
    """Retourne (victoires de a, victoires de b, egalites) sur des couples (a, b)."""
    a_wins = sum(1 for a, b in pairs if a > b)
    b_wins = sum(1 for a, b in pairs if b > a)
    ties = sum(1 for a, b in pairs if a == b)
    return a_wins, b_wins, ties


def arm_stats(records: list[dict[str, Any]]) -> dict[str, Any]:
    return {
        "n": len(records),
        "survival_rate": statistics.fmean([1.0 if r["alive"] else 0.0 for r in records]) if records else 0.0,
        "median_lifetime": statistics.median([r["lifetime"] for r in records]) if records else 0.0,
        "mean_berries_eaten": statistics.fmean([r["berries_eaten"] for r in records]) if records else 0.0,
    }


def evaluate(runs: list[dict[str, Any]], fixed_prefix: str, best_min: float, worst_max: float,
             min_agree: int, n_seeds: int) -> dict[str, Any]:
    by_env: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for run in runs:
        by_env[run["env_key"]].append(run)

    environments: list[dict[str, Any]] = []
    for env_key, env_runs in by_env.items():
        by_arm: dict[str, list[dict[str, Any]]] = defaultdict(list)
        for run in env_runs:
            by_arm[run["arm"]].append(run)
        arms_report = {arm: arm_stats(recs) for arm, recs in sorted(by_arm.items())}
        fixed_arms = [a for a in arms_report if a.startswith(fixed_prefix)]

        env_entry: dict[str, Any] = {
            "env": env_runs[0]["env"],
            "arms": arms_report,
            "gate_pass": False,
        }

        if len(fixed_arms) >= 2:
            ranked = sorted(fixed_arms, key=lambda a: (arms_report[a]["survival_rate"], arms_report[a]["mean_berries_eaten"]))
            worst, best = ranked[0], ranked[-1]
            best_by_seed = {r["seed"]: r for r in by_arm[best]}
            worst_by_seed = {r["seed"]: r for r in by_arm[worst]}
            common = sorted(set(best_by_seed) & set(worst_by_seed))
            life_pairs = [(best_by_seed[s]["lifetime"], worst_by_seed[s]["lifetime"]) for s in common]
            berry_pairs = [(best_by_seed[s]["berries_eaten"], worst_by_seed[s]["berries_eaten"]) for s in common]
            b_life, w_life, ties_life = sign_test_agreement(life_pairs)
            b_berry, w_berry, _ = sign_test_agreement(berry_pairs)
            # Accord = victoires de la meilleure sur la duree de vie, depart des egalites
            # tranche par les mures mangees.
            agree = b_life + sum(1 for (a, b), (c, d) in zip(life_pairs, berry_pairs) if a == b and c > d)
            best_ok = arms_report[best]["survival_rate"] >= best_min
            worst_ok = arms_report[worst]["survival_rate"] <= worst_max
            agree_ok = agree >= min_agree and len(common) >= n_seeds
            env_entry.update({
                "best_fixed_arm": best,
                "worst_fixed_arm": worst,
                "best_survival": arms_report[best]["survival_rate"],
                "worst_survival": arms_report[worst]["survival_rate"],
                "survival_gap": arms_report[best]["survival_rate"] - arms_report[worst]["survival_rate"],
                "paired_seeds": len(common),
                "lifetime_best_wins": b_life,
                "lifetime_worst_wins": w_life,
                "lifetime_ties": ties_life,
                "agreement": agree,
                "best_survival_ok": best_ok,
                "worst_survival_ok": worst_ok,
                "agreement_ok": agree_ok,
                "gate_pass": bool(best_ok and worst_ok and agree_ok),
            })
        environments.append(env_entry)

    environments.sort(key=lambda e: e.get("survival_gap", -1.0), reverse=True)
    passing = [e for e in environments if e["gate_pass"]]
    return {
        "n_seeds": n_seeds,
        "min_agree": min_agree,
        "best_min": best_min,
        "worst_max": worst_max,
        "environments": environments,
        "passing_environments": passing,
        "verdict": "PASS" if passing else "FAIL",
    }


def fmt_env(env: dict[str, Any]) -> str:
    return ", ".join(f"{k.split('.')[-1]}={v}" for k, v in sorted(env.items()))


def print_report(report: dict[str, Any]) -> None:
    for entry in report["environments"]:
        print(f"\n=== {fmt_env(entry['env'])} ===")
        print(f"  {'bras':<12} {'survie':>7} {'vie_med':>9} {'mures_moy':>10}  n")
        for arm, stats in entry["arms"].items():
            print(f"  {arm:<12} {stats['survival_rate']:>7.2f} {stats['median_lifetime']:>9.1f} {stats['mean_berries_eaten']:>10.2f}  {stats['n']}")
        if "best_fixed_arm" in entry:
            print(f"  meilleure fixe : {entry['best_fixed_arm']} (survie {entry['best_survival']:.2f})  "
                  f"pire fixe : {entry['worst_fixed_arm']} (survie {entry['worst_survival']:.2f})  "
                  f"ecart {entry['survival_gap']:.2f}")
            print(f"  test des signes (vie, meilleure vs pire) : {entry['lifetime_best_wins']}-{entry['lifetime_worst_wins']} "
                  f"({entry['lifetime_ties']} egalites)  accord retenu {entry['agreement']}/{entry['paired_seeds']}")
            flags = []
            flags.append(f"meilleure>={report['best_min']:.2f} {'OK' if entry['best_survival_ok'] else 'NON'}")
            flags.append(f"pire<={report['worst_max']:.2f} {'OK' if entry['worst_survival_ok'] else 'NON'}")
            flags.append(f"accord>={report['min_agree']} {'OK' if entry['agreement_ok'] else 'NON'}")
            print(f"  gate : {'  '.join(flags)}  =>  {'PASS' if entry['gate_pass'] else 'echec'}")
        else:
            print("  moins de deux bras fixes : gate non evaluable")

    print("\n" + "=" * 60)
    if report["passing_environments"]:
        print(f"GATE PASS : {len(report['passing_environments'])} environnement(s) separent les politiques fixes.")
        top = report["passing_environments"][0]
        print(f"  Retenu (ecart de survie max) : {fmt_env(top['env'])}")
        print(f"  {top['best_fixed_arm']} survie {top['best_survival']:.2f}  vs  {top['worst_fixed_arm']} survie {top['worst_survival']:.2f}")
    else:
        print("GATE FAIL : aucun environnement de la grille ne separe les politiques fixes")
        print("  (meilleure >= seuil, pire <= seuil, accord du test des signes).")
        print("  Roadmap : ne pas engager les Phases 2 a 4 ; remonter a l'utilisateur le choix")
        print("  entre enrichir l'environnement et suspendre l'axe apprentissage.")


def main() -> int:
    parser = argparse.ArgumentParser(description="Gate Phase 1 (oracle de politiques fixes).")
    parser.add_argument("results_dir", type=Path, help="Dossier de campagne (contient run_*/)")
    parser.add_argument("--agent", default="Rouge", help="Nom de l'agent apprenant (defaut Rouge)")
    parser.add_argument("--fixed-prefix", default="pf_", help="Prefixe des bras de politique fixe (defaut pf_)")
    parser.add_argument("--best-min", type=float, default=0.70, help="Survie minimale de la meilleure politique fixe")
    parser.add_argument("--worst-max", type=float, default=0.30, help="Survie maximale de la pire politique fixe")
    parser.add_argument("--min-agree", type=int, default=9, help="Accord minimal du test des signes")
    parser.add_argument("--n-seeds", type=int, default=12, help="Nombre de seeds attendus par bras et environnement")
    parser.add_argument("--json", type=Path, default=None, help="Ecrit le rapport complet en JSON")
    args = parser.parse_args()

    if not args.results_dir.is_dir():
        print(f"Dossier introuvable : {args.results_dir}", file=sys.stderr)
        return 2
    runs = load_runs(args.results_dir, args.agent)
    if not runs:
        print(f"Aucun run complete avec l'agent '{args.agent}' dans {args.results_dir}", file=sys.stderr)
        return 2

    report = evaluate(runs, args.fixed_prefix, args.best_min, args.worst_max, args.min_agree, args.n_seeds)
    print_report(report)
    if args.json:
        args.json.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"\nRapport JSON : {args.json}")
    return 0 if report["verdict"] == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
