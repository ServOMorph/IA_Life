"""Exécute et valide la campagne T2 v1."""

from __future__ import annotations

import argparse
import json
import subprocess
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

from t2_results import load_jsonl, result_key, validate_records

ROOT = Path(__file__).resolve().parents[1]
KINDS = ("baseline", "trained_memory", "trained_observation", "reset")
COUNTS = {"baseline": 96, "trained_memory": 160, "trained_observation": 160, "reset": 160}
SEEDS = (380001001, 380001002, 380001003)


def run_one(godot: str, kind: str, seed: int, resume: bool, workers: Path) -> Path:
    workers.mkdir(parents=True, exist_ok=True)
    output = workers / f"{kind}_{seed}.jsonl"
    if resume and output.exists() and len(load_jsonl(output)) == COUNTS[kind]:
        return output
    log = workers / f"{kind}_{seed}.godot.log"
    command = [godot, "--headless", "--fixed-fps", "60", "--path", str(ROOT),
               "--log-file", str(log), "--scene", "tools/t2_campaign.tscn", "--",
               "--output", str(output), "--kind", kind, "--initialization-seed", str(seed)]
    process = subprocess.run(command, cwd=ROOT, capture_output=True, text=True, timeout=900)
    if process.returncode:
        raise RuntimeError(f"{kind}/{seed}: {process.returncode}\n{process.stdout}\n{process.stderr}")
    if len(load_jsonl(output)) != COUNTS[kind]:
        raise RuntimeError(f"{kind}/{seed}: nombre de résultats invalide")
    return output


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--godot", default="godot")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--resume", action="store_true")
    args = parser.parse_args()
    if args.jobs < 1 or args.jobs > 9:
        parser.error("--jobs doit être compris entre 1 et 9")
    workers = ROOT / "experiments" / "t2_v1_workers"
    paths: list[Path] = []
    with ThreadPoolExecutor(max_workers=args.jobs) as pool:
        jobs = [pool.submit(run_one, args.godot, kind, seed, args.resume, workers) for seed in SEEDS for kind in KINDS]
        for job in as_completed(jobs):
            paths.append(job.result())
    records = [record for path in sorted(paths) for record in load_jsonl(path)]
    errors = validate_records(records)
    if errors:
        raise RuntimeError("\n".join(errors[:40]))
    records.sort(key=result_key)
    output = ROOT / "experiments" / "t2_v1_results.jsonl"
    output.write_text("".join(json.dumps(record, sort_keys=True) + "\n" for record in records), encoding="utf-8")
    print(f"{len(records)} résultats T2 v1 conformes : {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
