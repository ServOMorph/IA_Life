"""Rapport de mesure du benchmark avant/apres de roadmap_apprentissage_v2 (M0..Mf).

Lit un dossier de resultats de campagne (sous-dossiers run_*/ avec manifest.json +
summary archive), regroupe par bras et par seed, et pour un bras champion donne :

  - par bras : taux de survie, duree de vie mediane, mures mangees moyennes, temps sous
    pickup_hunger_threshold moyen, part des decisions de faim offrant >= 2 actions valides ;
  - test des signes apparie au seed, champion vs chaque bras de reference, sur la survie
    (primaire), la duree de vie et les mures mangees (secondaires) ;
  - controle de non-regression : diff des summaries de comportement des bras figes contre
    une mesure de reference (--baseline-dir), si fournie.

Ne prononce pas le verdict du gate : il est ecrit dans la roadmap et se lit sur ce rapport.

Usage :
  python tools/benchmark_report.py results/_benchmark_apprentissage_m1 --agent Rouge \
    --champion adaptatif_courant --ref aleatoire --ref adaptatif_v1 --ref pf_er_rm \
    --baseline-dir results/_benchmark_apprentissage_m0 --json results/_benchmark_apprentissage_m1/m1_report.json
"""

from __future__ import annotations

import argparse
import json
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
            "run_dir": manifest_path.parent,
            "arm": manifest.get("arm", ""),
            "seed": manifest.get("seed"),
            "alive": bool(agent.get("alive", False)),
            "lifetime": float(agent.get("lifetime_seconds", 0.0)),
            "berries_eaten": float(agent.get("berries_eaten_total", 0.0)),
            "berries_picked": float(agent.get("berries_picked_total", 0.0)),
            "hunger_decisions_multi": _multi_action_share(summary_path.with_name(
                summary_path.name.removesuffix(".summary.json") + ".jsonl")),
        })
    return runs


def _multi_action_share(jsonl_path: Path) -> float:
    """Part des decisions de faim (apprentissage_decision) prises dans une situation
    offrant >= 2 actions valides. Utilise le champ available_count du log quand il est
    present (decideur adaptatif / politique_fixe depuis la Phase 3) ; sinon approxime par
    la situation (S3_inconnu = 1 action, S1/S2 = plusieurs), cas du bras fige adaptatif_v1.
    Renvoie -1 si aucun evenement (bras non apprenant)."""
    if not jsonl_path.exists():
        return -1.0
    total = 0
    multi = 0
    for line in jsonl_path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            event = json.loads(line)
        except json.JSONDecodeError:
            continue
        if event.get("category") != "apprentissage_decision":
            continue
        total += 1
        data = event.get("data", {})
        available_count = data.get("available_count")
        if available_count is not None:
            if int(available_count) >= 2:
                multi += 1
        elif data.get("situation", "") in ("S1_ronce_visible", "S2_memoire"):
            multi += 1
    if total == 0:
        return -1.0
    return multi / total


def arm_stats(runs: list[dict[str, Any]]) -> dict[str, dict[str, Any]]:
    by_arm: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for run in runs:
        by_arm[run["arm"]].append(run)
    stats: dict[str, dict[str, Any]] = {}
    for arm, arm_runs in sorted(by_arm.items()):
        n = len(arm_runs)
        shares = [r["hunger_decisions_multi"] for r in arm_runs if r["hunger_decisions_multi"] >= 0.0]
        stats[arm] = {
            "n": n,
            "survival_rate": sum(1 for r in arm_runs if r["alive"]) / n if n else 0.0,
            "median_lifetime": statistics.median(r["lifetime"] for r in arm_runs) if n else 0.0,
            "mean_berries_eaten": statistics.fmean(r["berries_eaten"] for r in arm_runs) if n else 0.0,
            "mean_berries_picked": statistics.fmean(r["berries_picked"] for r in arm_runs) if n else 0.0,
            "mean_multi_action_share": statistics.fmean(shares) if shares else None,
        }
    return stats


def sign_test(champion: list[dict[str, Any]], reference: list[dict[str, Any]], key: str) -> dict[str, Any]:
    ref_by_seed = {r["seed"]: r for r in reference}
    wins = losses = ties = 0
    paired = 0
    for run in champion:
        other = ref_by_seed.get(run["seed"])
        if other is None:
            continue
        paired += 1
        a, b = run[key], other[key]
        if a > b:
            wins += 1
        elif a < b:
            losses += 1
        else:
            ties += 1
    return {"paired": paired, "champion_wins": wins, "reference_wins": losses, "ties": ties}


def behavioral_view(summary: dict) -> dict:
    result = json.loads(json.dumps(summary))
    result.pop("session_id", None)
    result.pop("experiment", None)
    for agent in result.get("agents", []):
        agent.pop("parameters", None)
    return result


def first_difference(a: Any, b: Any, path: str = "") -> str | None:
    if type(a) is not type(b):
        return f"{path or '<racine>'} : types differents"
    if isinstance(a, dict):
        for key in sorted(set(a) | set(b)):
            if key not in a or key not in b:
                return f"{path}.{key} : present d'un seul cote"
            diff = first_difference(a[key], b[key], f"{path}.{key}")
            if diff:
                return diff
        return None
    if isinstance(a, list):
        if len(a) != len(b):
            return f"{path} : longueurs differentes ({len(a)} vs {len(b)})"
        for i, (x, y) in enumerate(zip(a, b)):
            diff = first_difference(x, y, f"{path}[{i}]")
            if diff:
                return diff
        return None
    if a != b:
        return f"{path} : {a!r} != {b!r}"
    return None


def _summary_for(run_dir: Path) -> dict | None:
    manifest = json.loads((run_dir / "manifest.json").read_text(encoding="utf-8"))
    summary_name = manifest.get("summary")
    if not summary_name:
        return None
    path = run_dir / summary_name
    return json.loads(path.read_text(encoding="utf-8")) if path.exists() else None


def frozen_regression(runs: list[dict[str, Any]], baseline_dir: Path, agent_name: str, frozen_arms: list[str]) -> dict[str, Any]:
    base_runs = load_runs(baseline_dir, agent_name)
    base_index = {(r["arm"], r["seed"]): r["run_dir"] for r in base_runs}
    report: dict[str, Any] = {}
    for run in runs:
        if run["arm"] not in frozen_arms:
            continue
        base_dir = base_index.get((run["arm"], run["seed"]))
        key = f"{run['arm']}/seed_{run['seed']}"
        if base_dir is None:
            report[key] = "absent de la mesure de reference"
            continue
        fresh = _summary_for(run["run_dir"])
        stored = _summary_for(base_dir)
        if fresh is None or stored is None:
            report[key] = "summary introuvable"
            continue
        diff = first_difference(behavioral_view(stored), behavioral_view(fresh))
        report[key] = "OK" if diff is None else f"DIVERGENCE {diff}"
    return report


def main() -> int:
    parser = argparse.ArgumentParser(description="Rapport de mesure du benchmark roadmap_apprentissage_v2.")
    parser.add_argument("results_dir", type=Path)
    parser.add_argument("--agent", default="Rouge")
    parser.add_argument("--champion", required=True)
    parser.add_argument("--ref", action="append", default=[], dest="refs")
    parser.add_argument("--baseline-dir", type=Path, default=None)
    parser.add_argument("--frozen-arm", action="append", default=["automate", "adaptatif_v1", "aleatoire", "pf_er_rm"], dest="frozen_arms")
    parser.add_argument("--json", type=Path, default=None)
    args = parser.parse_args()

    runs = load_runs(args.results_dir, args.agent)
    if not runs:
        print(f"Aucun run complete dans {args.results_dir}", file=sys.stderr)
        return 1

    stats = arm_stats(runs)
    by_arm: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for run in runs:
        by_arm[run["arm"]].append(run)

    if args.champion not in by_arm:
        print(f"Bras champion '{args.champion}' absent des resultats.", file=sys.stderr)
        return 1

    comparisons: dict[str, Any] = {}
    for ref in args.refs:
        if ref not in by_arm:
            comparisons[ref] = "bras absent"
            continue
        comparisons[ref] = {
            "survival": sign_test(by_arm[args.champion], by_arm[ref], "alive"),
            "lifetime": sign_test(by_arm[args.champion], by_arm[ref], "lifetime"),
            "berries_eaten": sign_test(by_arm[args.champion], by_arm[ref], "berries_eaten"),
        }

    regression: dict[str, Any] = {}
    if args.baseline_dir is not None:
        regression = frozen_regression(runs, args.baseline_dir, args.agent, args.frozen_arms)

    report = {
        "results_dir": str(args.results_dir),
        "agent": args.agent,
        "champion": args.champion,
        "arm_stats": stats,
        "paired_sign_tests": comparisons,
        "frozen_arm_regression": regression,
    }

    print(json.dumps(report, indent=2, ensure_ascii=False))
    if args.json is not None:
        args.json.write_text(json.dumps(report, indent=2, ensure_ascii=False), encoding="utf-8")
        print(f"\nRapport ecrit : {args.json}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
