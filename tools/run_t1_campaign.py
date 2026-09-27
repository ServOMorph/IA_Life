"""Exécute et valide la campagne T1 v2."""

from __future__ import annotations

import argparse
import json
import subprocess
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

from t1_results import expected_t1_keys, load_jsonl, result_key, validate_records


ROOT = Path(__file__).resolve().parents[1]
KINDS = ("baseline", "trained", "reset")
COUNTS = {"baseline": 96, "trained": 160, "reset": 160}


def run_one(godot: str, kind: str, seed: int, resume: bool, contract: str, workers: Path) -> Path:
    workers.mkdir(parents=True, exist_ok=True)
    output = workers / f"{kind}_{seed}.jsonl"
    if resume and output.exists() and len(load_jsonl(output)) == COUNTS[kind]:
        return output
    log = workers / f"{kind}_{seed}.godot.log"
    command = [godot, "--headless", "--fixed-fps", "60", "--path", str(ROOT),
               "--log-file", str(log), "--scene", "tools/t1_campaign.tscn", "--",
               "--output", str(output), "--kind", kind, "--initialization-seed", str(seed)]
    if contract != "v2":
        command += ["--contract", contract]
    process = subprocess.run(command, cwd=ROOT, capture_output=True, text=True, timeout=600)
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
    parser.add_argument("--contract", choices=("v2", "v3", "v4"), default="v2")
    args = parser.parse_args()
    if args.jobs < 1 or args.jobs > 9:
        parser.error("--jobs doit être compris entre 1 et 9")
    seed_base = {"v2": 320001000, "v3": 350001000, "v4": 360001000}[args.contract]
    seeds = tuple(seed_base + index for index in (1, 2, 3))
    workers = ROOT / "experiments" / f"t1_{args.contract}_workers"
    results = ROOT / "experiments" / f"t1_{args.contract}_results.jsonl"
    paths = []
    with ThreadPoolExecutor(max_workers=args.jobs) as pool:
        jobs = [pool.submit(run_one, args.godot, kind, seed, args.resume, args.contract, workers)
                for seed in seeds for kind in KINDS]
        for job in as_completed(jobs):
            paths.append(job.result())
    records = [record for path in sorted(paths) for record in load_jsonl(path)]
    errors = validate_records(records, expected_t1_keys(args.contract), args.contract)
    if errors:
        raise RuntimeError("\n".join(errors[:40]))
    records.sort(key=result_key)
    results.write_text("".join(json.dumps(record, sort_keys=True) + "\n" for record in records), encoding="utf-8")
    print(f"{len(records)} résultats T1 {args.contract} conformes : {results}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
