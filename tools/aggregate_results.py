"""Valide et agrège les résumés d'expériences IA_Life.

Usage:
    python tools/aggregate_results.py logs --output results.csv --report report.json
    python tools/aggregate_results.py logs --validate-only
"""

from __future__ import annotations

import argparse
import csv
import json
import statistics
import sys
from collections import defaultdict
from pathlib import Path
from typing import Any


ROOT_FIELDS = {
    "schema_version": int,
    "session_id": str,
    "status": str,
    "reason": str,
    "elapsed_seconds": (int, float),
    "experiment": dict,
    "agents": list,
}
AGENT_FIELDS = {
    "name": str,
    "alive": bool,
    "parameters": dict,
    "hunger": (int, float),
    "berries_picked_total": int,
    "berries_eaten_total": int,
    "memorized_ronces": int,
    "wander_reorientations_total": int,
    "distance_travelled_total": (int, float),
    "visited_zones_total": int,
    "zone_discoveries_total": int,
    "zone_revisits_total": int,
    "lifetime_seconds": (int, float),
}
SOCIAL_AGENT_FIELDS = {
    "social_encounters_total": int,
    "social_contact_seconds": (int, float),
    "current_social_neighbors": int,
    "social_follow_decisions_total": int,
    "social_avoid_decisions_total": int,
}


def summaries_in(source: Path) -> list[Path]:
    if source.is_file():
        return [source]
    return sorted(source.rglob("*.summary.json"))


def validate_summary(payload: Any) -> list[str]:
    errors: list[str] = []
    if not isinstance(payload, dict):
        return ["la racine doit être un objet JSON"]
    for field, expected in ROOT_FIELDS.items():
        if field not in payload:
            errors.append(f"champ racine manquant : {field}")
        elif not isinstance(payload[field], expected):
            errors.append(f"champ racine invalide : {field}")
    experiment = payload.get("experiment")
    if isinstance(experiment, dict):
        for field in ("experiment_id", "seed"):
            if field not in experiment:
                errors.append(f"champ experiment manquant : {field}")
    for index, agent in enumerate(payload.get("agents", [])):
        if not isinstance(agent, dict):
            errors.append(f"agent {index} : objet attendu")
            continue
        for field, expected in AGENT_FIELDS.items():
            if field not in agent:
                errors.append(f"agent {index} : champ manquant {field}")
            elif not isinstance(agent[field], expected):
                errors.append(f"agent {index} : champ invalide {field}")
    return errors


def load_valid_summaries(source: Path) -> list[dict[str, Any]]:
    files = summaries_in(source)
    if not files:
        raise ValueError(f"Aucun fichier *.summary.json dans {source}")
    summaries: list[dict[str, Any]] = []
    failures: list[str] = []
    for path in files:
        try:
            payload = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            failures.append(f"{path}: JSON illisible ({error})")
            continue
        experiment = payload.get("experiment") if isinstance(payload, dict) else None
        if isinstance(experiment, dict) and "config_sha256" not in experiment:
            print(f"Archive ignorée (contrat de résultats antérieur) : {path}", file=sys.stderr)
            continue
        errors = validate_summary(payload)
        if errors:
            failures.extend(f"{path}: {error}" for error in errors)
            continue
        payload["_source"] = str(path)
        summaries.append(payload)
    if failures:
        raise ValueError("\n".join(failures))
    return summaries


def flatten_rows(summaries: list[dict[str, Any]]) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for summary in summaries:
        experiment = summary["experiment"]
        metadata = experiment.get("metadata", {})
        campaign_id = metadata.get("campaign_id", experiment["experiment_id"])
        campaign_parameters = metadata.get("campaign_parameters", {})
        comparison_group = "%s | %s" % (campaign_id, json.dumps(campaign_parameters, ensure_ascii=False, sort_keys=True))
        for agent in summary["agents"]:
            rows.append({
                "source": summary["_source"],
                "session_id": summary["session_id"],
                "experiment_id": experiment["experiment_id"],
                "campaign_id": campaign_id,
                "comparison_group": comparison_group,
                "campaign_parameters": json.dumps(campaign_parameters, ensure_ascii=False, sort_keys=True),
                "seed": experiment["seed"],
                "status": summary["status"],
                "reason": summary["reason"],
                "elapsed_seconds": summary["elapsed_seconds"],
                "agent": agent["name"],
                "alive": agent["alive"],
                "parameters": json.dumps(agent["parameters"], ensure_ascii=False, sort_keys=True),
                **{key: agent[key] for key in AGENT_FIELDS if key not in {"name", "alive", "parameters"}},
                **{key: agent.get(key, 0) for key in SOCIAL_AGENT_FIELDS},
            })
    return rows


def mean(values: list[float]) -> float:
    return statistics.fmean(values) if values else 0.0


def make_report(rows: list[dict[str, Any]]) -> dict[str, Any]:
    groups: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for row in rows:
        groups[row["comparison_group"]].append(row)
    experiments: dict[str, Any] = {}
    for comparison_group, group in groups.items():
        distances = [float(row["distance_travelled_total"]) for row in group]
        lifetimes = [float(row["lifetime_seconds"]) for row in group]
        discoveries = [float(row["zone_discoveries_total"]) for row in group]
        social_follow = [float(row["social_follow_decisions_total"]) for row in group]
        social_avoid = [float(row["social_avoid_decisions_total"]) for row in group]
        social_contacts = [float(row["social_contact_seconds"]) for row in group]
        memorized = [float(row["memorized_ronces"]) for row in group]
        berries_picked = [float(row["berries_picked_total"]) for row in group]
        berries_eaten = [float(row["berries_eaten_total"]) for row in group]
        experiments[comparison_group] = {
            "campaign_id": group[0]["campaign_id"],
            "campaign_parameters": json.loads(group[0]["campaign_parameters"]),
            "agent_records": len(group),
            "runs": len({row["session_id"] for row in group}),
            "survival_rate": mean([1.0 if row["alive"] else 0.0 for row in group]),
            "mean_distance_travelled": mean(distances),
            "mean_lifetime_seconds": mean(lifetimes),
            "mean_zone_discoveries": mean(discoveries),
            "mean_social_contact_seconds": mean(social_contacts),
            "mean_social_follow_decisions": mean(social_follow),
            "mean_social_avoid_decisions": mean(social_avoid),
            "mean_memorized_ronces": mean(memorized),
            "mean_berries_picked": mean(berries_picked),
            "mean_berries_eaten": mean(berries_eaten),
            "distance_standard_deviation": statistics.pstdev(distances) if len(distances) > 1 else 0.0,
        }
    return {"schema_version": 1, "experiments": experiments}


def main() -> int:
    parser = argparse.ArgumentParser(description="Valide et agrège les résultats IA_Life.")
    parser.add_argument("source", type=Path, help="Fichier summary ou dossier à analyser")
    parser.add_argument("--output", type=Path, help="CSV des résultats par agent")
    parser.add_argument("--report", type=Path, help="Rapport JSON agrégé")
    parser.add_argument("--validate-only", action="store_true", help="Valide sans créer de sortie")
    args = parser.parse_args()
    try:
        summaries = load_valid_summaries(args.source)
    except ValueError as error:
        print(f"Validation échouée :\n{error}", file=sys.stderr)
        return 1
    print(f"Validation réussie : {len(summaries)} résumé(s).")
    if args.validate_only:
        return 0
    rows = flatten_rows(summaries)
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        with args.output.open("w", encoding="utf-8", newline="") as file:
            writer = csv.DictWriter(file, fieldnames=list(rows[0]) if rows else [])
            writer.writeheader()
            writer.writerows(rows)
        print(f"CSV écrit : {args.output}")
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(json.dumps(make_report(rows), ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"Rapport écrit : {args.report}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
