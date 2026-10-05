"""Rapproche les blocages aller_vers des troncs sur les cartes de contrôle."""

from __future__ import annotations

import bisect
import json
import math
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
RESULTS = ROOT / "results" / "_decor_collisions_v1_llm_realtime"
TREES = json.loads((RESULTS / "tree_positions.json").read_text(encoding="utf-8"))


def inspect(run_dir: Path) -> list[dict]:
    config = json.loads((run_dir / "config.json").read_text(encoding="utf-8"))
    seed = config["seed"]
    positions: dict[str, list[tuple[float, float, float]]] = {}
    blocks: list[tuple[str, float]] = []
    log_path = next(run_dir.glob("*.jsonl"))
    with log_path.open(encoding="utf-8") as stream:
        for line in stream:
            event = json.loads(line)
            data = event["data"]
            if event["category"] == "position":
                x, _, z = data["position"]
                positions.setdefault(data["agent"], []).append((event["elapsed_seconds"], x, z))
            elif event["category"] == "llm_survie_action" and data.get("action") == "aller_vers" and data.get("issue") == "blocage":
                blocks.append((data["agent"], event["elapsed_seconds"]))
    result = []
    for agent, timestamp in blocks:
        samples = positions[agent]
        times = [sample[0] for sample in samples]
        index = bisect.bisect_left(times, timestamp)
        closest = min(samples[max(0, index - 1):min(len(samples), index + 1)], key=lambda sample: abs(sample[0] - timestamp))
        distance = min(math.hypot(closest[1] - tree["x"], closest[2] - tree["z"]) - tree["radius"] - 0.35 for tree in TREES[str(seed)])
        gap = abs(closest[0] - timestamp)
        result.append({"seed": seed, "agent": agent, "time": timestamp, "sample_gap": gap, "clearance_to_trunk": distance, "clearance_lower_bound": distance - 2.5 * gap})
    return result


def main() -> None:
    blocks = []
    for run_dir in sorted(RESULTS.glob("run_*_avec_collisions_*")):
        blocks.extend(inspect(run_dir))
    print(json.dumps(blocks, ensure_ascii=False, indent=2))
    if len(blocks) != 9 or min(block["clearance_lower_bound"] for block in blocks) <= 1.0:
        raise SystemExit("Audit de proximité des blocages de cible non conforme")


if __name__ == "__main__":
    main()
