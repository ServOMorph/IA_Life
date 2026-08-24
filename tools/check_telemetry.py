"""Vérifie qu'un summary headless correspond aux événements JSONL de sa session.

Usage : python tools/check_telemetry.py [config]
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))

from run_headless import run_headless


def main() -> int:
    config_path = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "experiments" / "telemetry_smoke_v1.json"
    config = json.loads(config_path.read_text(encoding="utf-8"))
    logs = ROOT / "logs"
    before = set(logs.glob("*.summary.json")) if logs.exists() else set()
    if run_headless(config, timeout_seconds=30):
        print("Échec : le run headless a échoué.", file=sys.stderr)
        return 1
    created = set(logs.glob("*.summary.json")) - before
    if len(created) != 1:
        print("Échec : le run doit produire exactement un summary.json.", file=sys.stderr)
        return 1

    summary_path = created.pop()
    summary = json.loads(summary_path.read_text(encoding="utf-8"))
    jsonl_path = summary_path.with_suffix("").with_suffix(".jsonl")
    if not jsonl_path.is_file():
        print(f"Échec : JSONL absent ({jsonl_path.name}).", file=sys.stderr)
        return 1
    events = [json.loads(line) for line in jsonl_path.read_text(encoding="utf-8").splitlines() if line]
    if not any(event.get("category") == "experiment" for event in events):
        print("Échec : la configuration normalisée n'est pas journalisée.", file=sys.stderr)
        return 1

    for agent in summary["agents"]:
        name = agent["name"]
        discoveries = sum(1 for event in events if event.get("category") == "zone" and event.get("data", {}).get("agent") == name and event["data"].get("event") == "discovery")
        revisits = sum(1 for event in events if event.get("category") == "zone" and event.get("data", {}).get("agent") == name and event["data"].get("event") == "revisit")
        if discoveries != agent["zone_discoveries_total"] or revisits != agent["zone_revisits_total"]:
            print(f"Échec : métriques de zone incohérentes pour {name}.", file=sys.stderr)
            return 1
    print(f"TÉLÉMÉTRIE VALIDE : {summary_path.name} correspond aux événements JSONL.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
