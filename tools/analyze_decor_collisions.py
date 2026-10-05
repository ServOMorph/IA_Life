"""Évalue la campagne appariée de collisions du décor."""

from __future__ import annotations

import argparse
import json
import statistics
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
SEEDS = set(range(26103101, 26103107))
ARMS = ("sans_collisions", "avec_collisions")


def load_campaign(directory: Path) -> dict[str, dict[int, dict]]:
    result: dict[str, dict[int, dict]] = {arm: {} for arm in ARMS}
    for run_dir in sorted(directory.glob("run_*")):
        manifest = json.loads((run_dir / "manifest.json").read_text(encoding="utf-8"))
        if manifest["status"] != "completed":
            raise ValueError(f"Run incomplet : {run_dir}")
        arm, seed = manifest["arm"], manifest["seed"]
        if arm not in result or seed not in SEEDS or seed in result[arm]:
            raise ValueError(f"Bras ou seed inattendu : {run_dir}")
        config = json.loads((run_dir / "config.json").read_text(encoding="utf-8"))
        if config["simulation"]["game_speed"] != 1.0 or config["simulation"]["max_simulation_seconds"] != 1200.0:
            raise ValueError(f"Simulation hors contrat : {run_dir}")
        if config["environment"]["game_config"]["decor_collisions"] != (arm == "avec_collisions"):
            raise ValueError(f"Interrupteur incohérent : {run_dir}")
        summaries = list(run_dir.glob("*.summary.json"))
        logs = list(run_dir.glob("*.jsonl"))
        if len(summaries) != 1 or len(logs) != 1:
            raise ValueError(f"Archives incomplètes : {run_dir}")
        summary = json.loads(summaries[0].read_text(encoding="utf-8"))
        if summary["status"] != "completed" or len(summary["agents"]) != 4:
            raise ValueError(f"Résumé invalide : {run_dir}")
        blocks = []
        with logs[0].open(encoding="utf-8") as stream:
            for line in stream:
                event = json.loads(line)
                if event["category"] == "llm_survie_action" and event["data"].get("issue") == "blocage":
                    blocks.append({"agent": event["data"]["agent"], "action": event["data"]["action"], "time": event["elapsed_seconds"]})
        agents = summary["agents"]
        result[arm][seed] = {
            "life_mean": statistics.fmean(min(1200.0, float(a["lifetime_seconds"])) for a in agents),
            "contacts": {kind: sum(a[f"obstacle_contacts_{kind}_total"] for a in agents) for kind in ("tronc", "rocher", "mur")},
            "detours": sum(a["decor_detours_total"] for a in agents),
            "detour_seconds": sum(a["decor_detour_seconds_total"] for a in agents),
            "detour_failures": sum(a["decor_detours_failed_total"] for a in agents),
            "blocked_max": max(a["decor_blocked_seconds_max"] for a in agents),
            "llm_turns": sum(a.get("llm_survie_tours", 0) for a in agents),
            "llm_replis": sum(a.get("llm_survie_replis", 0) for a in agents),
            "llm_refus": sum(a.get("llm_survie_refus", 0) for a in agents),
            "llm_blocks": blocks,
        }
    for arm in ARMS:
        if set(result[arm]) != SEEDS:
            raise ValueError(f"Cartes manquantes pour {arm} : {sorted(SEEDS - set(result[arm]))}")
    return result


def evaluate(rows: dict[str, dict[int, dict]], kind: str) -> dict:
    means = {arm: statistics.fmean(rows[arm][seed]["life_mean"] for seed in sorted(SEEDS)) for arm in ARMS}
    ratio = means["avec_collisions"] / means["sans_collisions"] if means["sans_collisions"] else None
    with_collisions = [rows["avec_collisions"][seed] for seed in sorted(SEEDS)]
    total = lambda key: sum(row[key] for row in with_collisions)
    result = {
        "life_mean_seconds": means,
        "life_ratio": ratio,
        "contacts_with_collisions": {kind_: sum(row["contacts"][kind_] for row in with_collisions) for kind_ in ("tronc", "rocher", "mur")},
        "detours_with_collisions": total("detours"),
        "detour_seconds_with_collisions": total("detour_seconds"),
        "detour_failures_with_collisions": total("detour_failures"),
        "blocked_max_seconds": max(row["blocked_max"] for row in with_collisions),
        "cards": [{"seed": seed, **{arm: rows[arm][seed] for arm in ARMS}} for seed in sorted(SEEDS)],
    }
    if kind == "automate":
        result["gate_life"] = ratio is not None and ratio >= 0.90
        result["gate_blockage"] = result["blocked_max_seconds"] <= 3.0
    else:
        turns = total("llm_turns")
        result["llm_turns"] = turns
        result["llm_replis"] = total("llm_replis")
        result["llm_refus"] = total("llm_refus")
        result["llm_repli_rate"] = result["llm_replis"] / turns if turns else None
        result["llm_blocks"] = [block for row in with_collisions for block in row["llm_blocks"]]
        result["llm_block_counts"] = {
            arm: {
                action: sum(1 for seed in SEEDS for block in rows[arm][seed]["llm_blocks"] if block["action"] == action)
                for action in ("aller_vers", "explorer")
            }
            for arm in ARMS
        }
        result["gate_life"] = ratio is not None and ratio >= 0.80
        result["gate_replis"] = result["llm_repli_rate"] is not None and result["llm_repli_rate"] <= 0.05
    return result


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("kind", choices=("automate", "llm"))
    parser.add_argument("--out", type=Path)
    parser.add_argument("--directory", type=Path)
    args = parser.parse_args()
    default_directory = ROOT / "results" / ("_decor_collisions_v1_llm_realtime" if args.kind == "llm" else "_decor_collisions_v1_automate")
    rows = load_campaign(args.directory or default_directory)
    report = evaluate(rows, args.kind)
    rendered = json.dumps(report, ensure_ascii=False, indent=2)
    if args.out:
        args.out.write_text(rendered + "\n", encoding="utf-8")
    print(rendered)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
