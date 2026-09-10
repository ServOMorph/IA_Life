"""Valide la géométrie et la télémétrie du placement approche_roncier."""

from __future__ import annotations

import json
import math
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))

from run_headless import run_headless


def horizontal_distance(first: list[float], second: list[float]) -> float:
    return math.hypot(first[0] - second[0], first[2] - second[2])


def main() -> int:
    config_path = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "experiments" / "danger_zone_approach_smoke_v1.json"
    config = json.loads(config_path.read_text(encoding="utf-8"))
    game_config = config["environment"]["game_config"]
    expected_count = game_config["danger_zone_count"]
    expected_radius = game_config["danger_zone_radius"]
    expected_clearance = game_config["danger_zone_approach_clearance"]
    expected_spawn_index = game_config["danger_zone_approach_spawn_index"]
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
    jsonl_path = summary_path.with_suffix("").with_suffix(".jsonl")
    events = [json.loads(line) for line in jsonl_path.read_text(encoding="utf-8").splitlines() if line]
    placements = [event["data"] for event in events if event.get("category") == "danger_placement"]
    if len(placements) != expected_count or any(event.get("status") != "placed" for event in placements):
        print("Échec : le smoke doit placer exactement toutes les zones demandées.", file=sys.stderr)
        return 1
    for event in placements:
        if event.get("placement_mode") != "approche_roncier" or event.get("approach_spawn_index") != expected_spawn_index:
            print("Échec : la provenance approche_roncier est absente de la télémétrie.", file=sys.stderr)
            return 1
        position = event.get("position")
        spawn = event.get("approach_spawn_position")
        ronce = event.get("source_ronce_position")
        if not all(isinstance(value, list) and len(value) == 3 for value in (position, spawn, ronce)):
            print("Échec : la géométrie source manque dans un événement de placement.", file=sys.stderr)
            return 1
        if not math.isclose(horizontal_distance(position, ronce), expected_radius + expected_clearance, abs_tol=0.001):
            print("Échec : une zone n'est pas à rayon + marge de son roncier source.", file=sys.stderr)
            return 1
        spawn_to_ronce = horizontal_distance(spawn, ronce)
        spawn_to_zone = horizontal_distance(spawn, position)
        if not 0.0 < spawn_to_zone < spawn_to_ronce:
            print("Échec : une zone n'est pas entre le spawn et son roncier source.", file=sys.stderr)
            return 1
    print(f"PLACEMENT APPROCHE VALIDE : {expected_count} zones à rayon + marge, sur le segment spawn-roncier.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
