"""Diagnostic des campagnes de calibration, sans lancer de simulation."""

import argparse
import json
from collections import Counter, defaultdict
from pathlib import Path


def report(directory):
    rows = []
    for path in sorted(directory.glob("run_*/*.summary.json")):
        summary = json.loads(path.read_text(encoding="utf-8"))
        agent = next(a for a in summary["agents"] if a["name"] == "Rouge")
        trace = path.with_name(path.name.removesuffix(".summary.json") + ".jsonl")
        counts = Counter()
        logged_cost = 0.0
        logged_seconds = 0.0
        for line in trace.read_text(encoding="utf-8").splitlines():
            event = json.loads(line)
            data = event.get("data", {})
            if data.get("agent") != "Rouge":
                continue
            if event.get("category") == "danger_navigation":
                counts[data["phase"] or data["reason"]] += 1
                if data["phase"] and data["reason"]:
                    counts[data["reason"]] += 1
            if event.get("category") == "danger_exposure":
                logged_cost += data["hunger_cost_delta"]
                logged_seconds += data["delta_seconds"]
        if abs(logged_cost - agent["danger_hunger_cost_total"]) > 0.001:
            raise ValueError(f"Cout incoherent : {path}")
        if abs(logged_seconds - agent["danger_exposure_seconds_total"]) > 0.001:
            raise ValueError(f"Exposition incoherente : {path}")
        rows.append(dict(
            arm=summary["experiment"]["metadata"]["arm"], seed=summary["experiment"]["seed"],
            alive=agent["alive"], berries=agent["berries_eaten_total"],
            cost=agent["danger_hunger_cost_total"], navigation=dict(counts),
        ))
    grouped = defaultdict(list)
    for row in rows:
        grouped[row["arm"]].append(row)
    for arm, runs in grouped.items():
        nav = Counter()
        for run in runs:
            nav.update(run["navigation"])
        print(arm, f"n={len(runs)}", f"survie={sum(r['alive'] for r in runs)/len(runs):.3f}",
              f"mures={sum(r['berries'] for r in runs)/len(runs):.2f}",
              f"cout={sum(r['cost'] for r in runs)/len(runs):.2f}", dict(nav))
    return rows


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("directory", type=Path)
    parser.add_argument("--json", type=Path)
    args = parser.parse_args()
    rows = report(args.directory)
    if args.json:
        args.json.write_text(json.dumps(rows, indent=2), encoding="utf-8")
