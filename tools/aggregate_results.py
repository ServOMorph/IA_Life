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
    "social_shares_total": int,
    "memories_received_total": int,
    "food_shared_total": int,
    "food_received_total": int,
    "aggression_incidents_total": int,
    "aggression_received_total": int,
}
DECIDER_AGENT_FIELDS = {
    "llm_calls_total": int,
    "llm_errors_total": int,
    "llm_total_latency_ms": (int, float),
}
VISION_AGENT_FIELDS = {
    "vision_detections_total": int,
    "ronces_discovered_by_vision_total": int,
    "vision_to_contact_delay_seconds_total": (int, float),
    "vision_to_contact_events_total": int,
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
                **{key: agent.get(key, 0) for key in DECIDER_AGENT_FIELDS},
                **{key: agent.get(key, 0) for key in VISION_AGENT_FIELDS},
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
        social_shares = [float(row["social_shares_total"]) for row in group]
        food_shared = [float(row["food_shared_total"]) for row in group]
        aggression_incidents = [float(row["aggression_incidents_total"]) for row in group]
        llm_calls = [float(row["llm_calls_total"]) for row in group]
        llm_errors = [float(row["llm_errors_total"]) for row in group]
        llm_total_latency = [float(row["llm_total_latency_ms"]) for row in group]
        llm_calls_sum = sum(llm_calls)
        vision_detections = [float(row["vision_detections_total"]) for row in group]
        ronces_discovered_by_vision = [float(row["ronces_discovered_by_vision_total"]) for row in group]
        vision_to_contact_delay_sum = sum(float(row["vision_to_contact_delay_seconds_total"]) for row in group)
        vision_to_contact_events_sum = sum(float(row["vision_to_contact_events_total"]) for row in group)
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
            "mean_social_shares": mean(social_shares),
            "mean_food_shared": mean(food_shared),
            "mean_aggression_incidents": mean(aggression_incidents),
            "mean_llm_calls": mean(llm_calls),
            "llm_error_rate": (sum(llm_errors) / llm_calls_sum) if llm_calls_sum > 0 else 0.0,
            "mean_llm_latency_ms": (sum(llm_total_latency) / llm_calls_sum) if llm_calls_sum > 0 else 0.0,
            "mean_vision_detections": mean(vision_detections),
            "mean_ronces_discovered_by_vision": mean(ronces_discovered_by_vision),
            "mean_vision_to_contact_delay_seconds": (vision_to_contact_delay_sum / vision_to_contact_events_sum) if vision_to_contact_events_sum > 0 else 0.0,
            "distance_standard_deviation": statistics.pstdev(distances) if len(distances) > 1 else 0.0,
        }
    return {"schema_version": 1, "experiments": experiments}


def _jsonl_sources(source: Path) -> list[Path]:
    if source.is_file():
        return [source]
    return sorted(source.rglob("*.jsonl"))


def _learning_series(jsonl_path: Path) -> dict[str, list[dict[str, Any]]]:
    """Extrait, par agent, la suite chronologique des mises à jour de score non terminales
    du décideur adaptatif (événements apprentissage_maj)."""
    series: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for line in jsonl_path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            event = json.loads(line)
        except json.JSONDecodeError:
            continue
        if event.get("category") != "apprentissage_maj":
            continue
        data = event.get("data", {})
        if data.get("terminal", False):
            continue
        series[str(data.get("agent", ""))].append({
            "elapsed_seconds": float(event.get("elapsed_seconds", 0.0)),
            "reward": float(data.get("reward", 0.0)),
        })
    return series


def build_learning_curves(source: Path, window: int, step: int) -> tuple[list[dict[str, Any]], dict[str, Any]]:
    sources = _jsonl_sources(source)
    if not sources:
        raise ValueError(f"Aucun fichier *.jsonl dans {source}")
    rows: list[dict[str, Any]] = []
    runs: dict[str, Any] = {}
    # Regroupé par (agent, paramètres de campagne) : deux runs ne sont comparables pour la
    # reproductibilité que s'ils partagent la même configuration (même bras de campagne).
    reward_signatures: dict[str, list[str]] = defaultdict(list)
    for jsonl_path in sources:
        run_name = jsonl_path.parent.name if jsonl_path.parent != source and source.is_dir() else jsonl_path.stem
        run_parameters: dict[str, Any] = {}
        manifest_path = jsonl_path.parent / "manifest.json"
        if manifest_path.exists():
            try:
                run_parameters = json.loads(manifest_path.read_text(encoding="utf-8")).get("parameters", {})
            except (OSError, json.JSONDecodeError):
                run_parameters = {}
        param_key = json.dumps(run_parameters, sort_keys=True)
        for agent, decisions in _learning_series(jsonl_path).items():
            rewards = [d["reward"] for d in decisions]
            reward_signatures[f"{agent} | {param_key}"].append(json.dumps([round(r, 6) for r in rewards]))
            n = len(decisions)
            windows: list[dict[str, Any]] = []
            if n >= window:
                for w_index, start in enumerate(range(0, n - window + 1, step)):
                    chunk = decisions[start:start + window]
                    success = mean([1.0 if d["reward"] > 0.0 else 0.0 for d in chunk])
                    center = start + window // 2
                    row = {
                        "run": run_name,
                        "agent": agent,
                        "params": param_key,
                        "n_decisions": n,
                        "window_index": w_index,
                        "center_decision": center,
                        "center_elapsed": decisions[center]["elapsed_seconds"],
                        "success_rate": success,
                        "mean_reward": mean([d["reward"] for d in chunk]),
                    }
                    rows.append(row)
                    windows.append(row)
            start_rate = windows[0]["success_rate"] if windows else 0.0
            end_rate = windows[-1]["success_rate"] if windows else 0.0
            def _slope(key: str) -> float:
                if len(windows) < 2:
                    return 0.0
                xs = [w["window_index"] for w in windows]
                ys = [w[key] for w in windows]
                x_mean = mean(xs)
                y_mean = mean(ys)
                denom = sum((x - x_mean) ** 2 for x in xs)
                return sum((x - x_mean) * (y - y_mean) for x, y in zip(xs, ys)) / denom if denom else 0.0

            def _step_volatility(key: str) -> float:
                # Amplitude moyenne des variations d'une fenêtre à la suivante : mesure
                # « apprend sans osciller » (bas = stable, haut = la courbe zigzague).
                if len(windows) < 2:
                    return 0.0
                deltas = [abs(windows[i][key] - windows[i - 1][key]) for i in range(1, len(windows))]
                return mean(deltas)

            half = len(windows) // 2
            first_half = mean([w["mean_reward"] for w in windows[:half]]) if half else 0.0
            second_half = mean([w["mean_reward"] for w in windows[half:]]) if windows[half:] else 0.0
            runs.setdefault(run_name, {})[agent] = {
                "parameters": run_parameters,
                "n_decisions": n,
                "windows": len(windows),
                "start_success_rate": start_rate,
                "end_success_rate": end_rate,
                "delta_success_rate": end_rate - start_rate,
                "slope_per_window": _slope("success_rate"),
                "mean_reward_slope_per_window": _slope("mean_reward"),
                "success_rate_step_volatility": _step_volatility("success_rate"),
                "mean_reward_step_volatility": _step_volatility("mean_reward"),
                "first_half_mean_reward": first_half,
                "second_half_mean_reward": second_half,
                "second_minus_first_half_mean_reward": second_half - first_half,
                "start_mean_reward": windows[0]["mean_reward"] if windows else 0.0,
                "end_mean_reward": windows[-1]["mean_reward"] if windows else 0.0,
                "overall_success_rate": mean([1.0 if r > 0.0 else 0.0 for r in rewards]) if rewards else 0.0,
                "overall_mean_reward": mean(rewards) if rewards else 0.0,
            }
    reproducible = {
        agent: (len(set(signatures)) == 1 and len(signatures) > 1)
        for agent, signatures in reward_signatures.items()
    }
    summary = {
        "schema_version": 1,
        "window": window,
        "step": step,
        "runs": runs,
        "reproducible_across_runs": reproducible,
    }
    return rows, summary


def main() -> int:
    parser = argparse.ArgumentParser(description="Valide et agrège les résultats IA_Life.")
    parser.add_argument("source", type=Path, help="Fichier summary ou dossier à analyser")
    parser.add_argument("--output", type=Path, help="CSV des résultats par agent")
    parser.add_argument("--report", type=Path, help="Rapport JSON agrégé")
    parser.add_argument("--validate-only", action="store_true", help="Valide sans créer de sortie")
    parser.add_argument("--learning-curve", type=Path, metavar="OUT_DIR",
                        help="Écrit learning_curve.csv + learning_curve_summary.json (taux de décisions de faim réussies du décideur adaptatif, fenêtre glissante) à partir des .jsonl de la source")
    parser.add_argument("--lc-window", type=int, default=20, help="Taille de la fenêtre glissante (décisions), défaut 20")
    parser.add_argument("--lc-step", type=int, default=5, help="Pas de la fenêtre glissante (décisions), défaut 5")
    args = parser.parse_args()

    if args.learning_curve is not None:
        try:
            rows, summary = build_learning_curves(args.source, args.lc_window, args.lc_step)
        except ValueError as error:
            print(f"Courbe d'apprentissage échouée :\n{error}", file=sys.stderr)
            return 1
        args.learning_curve.mkdir(parents=True, exist_ok=True)
        csv_path = args.learning_curve / "learning_curve.csv"
        fieldnames = ["run", "agent", "params", "n_decisions", "window_index", "center_decision", "center_elapsed", "success_rate", "mean_reward"]
        with csv_path.open("w", encoding="utf-8", newline="") as file:
            writer = csv.DictWriter(file, fieldnames=fieldnames)
            writer.writeheader()
            writer.writerows(rows)
        summary_path = args.learning_curve / "learning_curve_summary.json"
        summary_path.write_text(json.dumps(summary, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"Courbe d'apprentissage écrite : {csv_path}")
        print(f"Résumé courbe d'apprentissage écrit : {summary_path}")
        return 0
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
