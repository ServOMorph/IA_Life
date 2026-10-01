"""Compare les bras automate et llm_survie de la campagne de Phase 5 (roadmap_survie_llm.md).

Usage : python tools/analyze_llm_survie.py [--out rapport.json]
Lit les deux dossiers de campagne, applique le critère de experiments/llm_survie_critere_v1.md
et affiche un tableau apparié par carte.
"""

from __future__ import annotations

import argparse
import json
import platform
import re
import statistics
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ARMS = {
    "automate": ROOT / "results" / "_llm_survie_v1_automate",
    "llm_survie": ROOT / "results" / "_llm_survie_v1_llm",
}
CAP_SECONDS = 1200.0
MIN_RATIO = 0.80
MIN_WINS = 4
MAX_FALLBACK_RATE = 0.05


def load_arm(directory: Path) -> dict[int, dict]:
    runs: dict[int, dict] = {}
    for run_dir in sorted(directory.glob("run_*")):
        summaries = sorted(run_dir.glob("*.summary.json"))
        config_path = run_dir / "config.json"
        if not summaries or not config_path.exists():
            continue
        seed = int(json.loads(config_path.read_text(encoding="utf-8"))["seed"])
        runs[seed] = json.loads(summaries[-1].read_text(encoding="utf-8"))
    return runs


def lifetime(agent: dict) -> float:
    return min(CAP_SECONDS, float(agent["lifetime_seconds"]))


def card_indicator(summary: dict) -> float:
    return statistics.fmean(lifetime(agent) for agent in summary["agents"])


def sum_agents(summary: dict, key: str) -> float:
    return float(sum(agent.get(key, 0) for agent in summary["agents"]))


def hardware() -> dict:
    info = {"os": platform.platform(), "python": platform.python_version()}
    try:
        info["processeur"] = subprocess.run(
            ["powershell", "-NoProfile", "-Command", "(Get-CimInstance Win32_Processor | Select-Object -First 1).Name"],
            capture_output=True, text=True, check=True,
        ).stdout.strip()
        info["ollama"] = subprocess.run(["ollama", "--version"], capture_output=True, text=True).stdout.strip()
    except (OSError, subprocess.SubprocessError):
        pass
    return info


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", type=Path, default=None)
    args = parser.parse_args()

    arms = {name: load_arm(path) for name, path in ARMS.items()}
    seeds = sorted(set(arms["automate"]) & set(arms["llm_survie"]))
    if not seeds:
        print("Aucune carte commune aux deux bras.")
        return 1

    rows = []
    for seed in seeds:
        auto = arms["automate"][seed]
        llm = arms["llm_survie"][seed]
        rows.append({
            "seed": seed,
            "automate_vie_moyenne_s": card_indicator(auto),
            "llm_vie_moyenne_s": card_indicator(llm),
            "automate_survivants": sum(1 for a in auto["agents"] if a["alive"]),
            "llm_survivants": sum(1 for a in llm["agents"] if a["alive"]),
            "automate_mures_mangees": sum_agents(auto, "berries_eaten_total"),
            "llm_mures_mangees": sum_agents(llm, "berries_eaten_total"),
            "llm_tours": sum_agents(llm, "llm_survie_tours"),
            "llm_refus": sum_agents(llm, "llm_survie_refus"),
            "llm_replis": sum_agents(llm, "llm_survie_replis"),
            "llm_attente_sim_s": sum_agents(llm, "llm_survie_attente_sim_totale_s"),
            "llm_faim_perdue_attente": sum_agents(llm, "llm_survie_faim_perdue_attente"),
            "llm_latence_moyenne_ms": statistics.fmean(a.get("llm_survie_latence_moyenne_ms", 0.0) for a in llm["agents"]),
        })

    mean_auto = statistics.fmean(r["automate_vie_moyenne_s"] for r in rows)
    mean_llm = statistics.fmean(r["llm_vie_moyenne_s"] for r in rows)
    wins = sum(1 for r in rows if r["llm_vie_moyenne_s"] >= r["automate_vie_moyenne_s"])
    turns = sum(r["llm_tours"] for r in rows)
    fallback_rate = sum(r["llm_replis"] for r in rows) / turns if turns else 1.0
    distribution: dict[str, int] = {}
    for summary in arms["llm_survie"].values():
        for agent in summary["agents"]:
            for action, count in agent.get("llm_survie_distribution_actions", {}).items():
                distribution[action] = distribution.get(action, 0) + int(count)

    complete = len(rows) == 6
    criterion_1 = complete and fallback_rate <= MAX_FALLBACK_RATE
    criterion_2 = mean_auto > 0 and mean_llm >= MIN_RATIO * mean_auto
    criterion_3 = wins >= MIN_WINS
    report = {
        "cartes": len(rows),
        "vie_moyenne_automate_s": mean_auto,
        "vie_moyenne_llm_s": mean_llm,
        "ratio_llm_sur_automate": mean_llm / mean_auto if mean_auto else None,
        "cartes_llm_superieur_ou_egal": wins,
        "taux_repli": fallback_rate,
        "distribution_actions_llm": distribution,
        "critere_1_robustesse": criterion_1,
        "critere_2_performance": criterion_2,
        "critere_3_lecture_forte": criterion_3,
        "succes": criterion_1 and criterion_2,
        "materiel": hardware(),
        "cartes_detail": rows,
    }

    print("%-9s %9s %9s %6s %6s %8s %8s %6s %6s %9s" % ("seed", "auto_vie", "llm_vie", "a_surv", "l_surv", "a_mures", "l_mures", "tours", "repli", "lat_ms"))
    for r in rows:
        print("%-9d %9.0f %9.0f %6d %6d %8.0f %8.0f %6.0f %6.0f %9.0f" % (
            r["seed"], r["automate_vie_moyenne_s"], r["llm_vie_moyenne_s"], r["automate_survivants"], r["llm_survivants"],
            r["automate_mures_mangees"], r["llm_mures_mangees"], r["llm_tours"], r["llm_replis"], r["llm_latence_moyenne_ms"]))
    print()
    print("Vie moyenne : automate %.0f s, llm_survie %.0f s (ratio %.2f)" % (mean_auto, mean_llm, report["ratio_llm_sur_automate"] or 0))
    print("Cartes llm >= automate : %d/%d ; taux de repli %.3f" % (wins, len(rows), fallback_rate))
    print("Critere 1 (robustesse) : %s ; critere 2 (performance) : %s ; critere 3 (lecture forte) : %s" % (criterion_1, criterion_2, criterion_3))
    print("Succes (1 et 2) : %s" % report["succes"])
    print("Distribution des actions llm : %s" % re.sub(r"\s+", " ", json.dumps(distribution, ensure_ascii=False)))
    if args.out:
        args.out.write_text(json.dumps(report, indent=2, ensure_ascii=False), encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
