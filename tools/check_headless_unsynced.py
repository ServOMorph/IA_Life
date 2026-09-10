"""Rejoue les runs archivés à pas fixe 60 Hz sans synchronisation murale."""

import argparse
import json
import os
import subprocess
import sys
import time
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))
from tools.run_campaign import find_summary_by_experiment_id
from tools.check_fixed_policy import first_difference


def compare(path):
    original = json.loads(path.read_text(encoding="utf-8"))
    config_path = path.parent / "config.json"
    env = dict(os.environ, IA_LIFE_HEADLESS_FIXED_FPS="60")
    started = time.time()
    subprocess.run([sys.executable, str(ROOT / "run_headless.py"), str(config_path), "300"],
                   cwd=ROOT, env=env, check=True, timeout=320)
    replay = find_summary_by_experiment_id(original["experiment"]["experiment_id"], started)
    if replay is None:
        raise ValueError(f"Summary manquant : {path}")
    actual = json.loads(replay.read_text(encoding="utf-8"))
    original.pop("session_id", None)
    actual.pop("session_id", None)
    difference = first_difference(original, actual)
    if difference:
        raise ValueError(f"{path.parent.name}: {difference}")
    return dict(run=path.parent.name, identical=True, seconds=round(time.time() - started, 3),
                reference=str(path), replay=str(replay))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("directory", type=Path)
    parser.add_argument("--jobs", type=int, default=4)
    args = parser.parse_args()
    paths = sorted(args.directory.glob("run_*/*.summary.json"))
    if not paths:
        raise SystemExit("Aucun run archive.")
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        results = list(executor.map(compare, paths))
    (args.directory / "unsynced_comparison.json").write_text(json.dumps(results, indent=2), encoding="utf-8")
    print(f"IDENTIQUES : {len(results)}/{len(paths)} summaries complets hors session_id.")
