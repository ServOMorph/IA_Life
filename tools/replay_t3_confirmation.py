"""Rejoue les checkpoints de confirmation T3 v3 après rechargement (gate 8)."""

from __future__ import annotations

import argparse
import subprocess
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

from t3_confirmation_results import INITIALIZATIONS, CHECKPOINT

ROOT = Path(__file__).resolve().parents[1]


def replay_one(godot: str, seed: int, cards_mode: str, label: str) -> None:
    workers = ROOT / "experiments" / f"t3_confirmation_{label}_workers"
    checkpoint = workers / f"trained_{seed}.jsonl.{seed}.{CHECKPOINT}.checkpoint.json"
    output = ROOT / "experiments" / f"t3_confirmation_{label}_replay_{seed}.jsonl"
    command = [godot, "--headless", "--fixed-fps", "60", "--path", str(ROOT),
               "--log-file", str(workers / f"replay_{seed}.godot.log"),
               "--scene", "tools/t3_replay.tscn", "--", "--checkpoint", str(checkpoint),
               "--initialization-seed", str(seed), "--output", str(output),
               "--contract", "v3c", "--cards", cards_mode]
    process = subprocess.run(command, cwd=ROOT, capture_output=True, text=True, timeout=3600)
    if process.returncode:
        raise RuntimeError(f"replay {seed}: {process.returncode}\n{process.stdout}\n{process.stderr}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--godot", default="godot")
    parser.add_argument("--cards", choices=("validation", "final"), required=True)
    parser.add_argument("--jobs", type=int, default=3)
    args = parser.parse_args()
    label = "dryrun" if args.cards == "validation" else "final"
    with ThreadPoolExecutor(max_workers=args.jobs) as pool:
        for job in as_completed([pool.submit(replay_one, args.godot, seed, args.cards, label)
                                 for seed in sorted(INITIALIZATIONS)]):
            job.result()
    print(f"replays écrits pour {len(INITIALIZATIONS)} lignées ({label}).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
