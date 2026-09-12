import argparse
import json
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

from t0_results import validate_records

GODOT_EXE = Path("D:/Godot/godot.exe")
PROJECT_DIR = Path(__file__).resolve().parent.parent
INITIALIZATION_SEEDS = [310001001, 310001002, 310001003]
VALIDATION_CARDS = list(range(310000101, 310000133))
CHECKPOINTS = [0, 10, 50, 200, 1000]
KINDS = ["baseline", "trained", "reset"]


def result_key(record: dict) -> tuple[str, str, int, int, int]:
    return (record["experiment_id"], record["arm"], record["initialization_seed"], record["card_seed"], record["checkpoint"])


def expected_records() -> list[dict]:
    records: list[dict] = []
    for seed in INITIALIZATION_SEEDS:
        for arm in ("scripted", "initial_frozen", "random_valid"):
            for card_seed in VALIDATION_CARDS:
                records.append(_expected_record(arm, seed, card_seed, 0))
        for arm in ("trained", "reset_each_episode"):
            for checkpoint in CHECKPOINTS:
                for card_seed in VALIDATION_CARDS:
                    records.append(_expected_record(arm, seed, card_seed, checkpoint))
    return records


def _expected_record(arm: str, initialization_seed: int, card_seed: int, checkpoint: int) -> dict:
    return {
        "experiment_id": "t0_contract_v2", "arm": arm, "initialization_seed": initialization_seed,
        "card_seed": card_seed, "checkpoint": checkpoint, "success": False, "terminated": False,
        "truncated": True, "table_checksum": "expected", "config_fingerprint": "expected",
    }


def worker_command(output: Path, kind: str, initialization_seed: int) -> list[str]:
    return [str(GODOT_EXE), "--headless", "--path", str(PROJECT_DIR), "--log-file", str(output.with_suffix(".godot.log")), "--scene", "tools/t0_campaign.tscn", "--", "--output", str(output), "--kind", kind, "--initialization-seed", str(initialization_seed)]


def run_worker(output: Path, kind: str, initialization_seed: int) -> tuple[Path, bool, int]:
    completed = subprocess.run(worker_command(output, kind, initialization_seed), cwd=PROJECT_DIR, capture_output=True, text=True)
    succeeded = output.exists() and "SUCCÈS : campagne T0 terminée" in completed.stdout
    if not succeeded:
        sys.stderr.write(completed.stdout + completed.stderr)
    return output, succeeded, completed.returncode


def load_jsonl(path: Path) -> list[dict]:
    return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line]


def main() -> int:
    parser = argparse.ArgumentParser(description="Exécute les lignées T0 en processus Godot isolés.")
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()
    if not GODOT_EXE.exists():
        print(f"Godot introuvable : {GODOT_EXE}", file=sys.stderr)
        return 1
    output = args.output.resolve()
    worker_dir = output.with_suffix(output.suffix + ".workers")
    tasks = [(worker_dir / f"{kind}_{seed}.jsonl", kind, seed) for kind in KINDS for seed in INITIALIZATION_SEEDS]
    if args.dry_run:
        for path, kind, seed in tasks:
            print(f"Planifié : {kind}, seed={seed}, sortie={path}")
        print(f"{len(tasks)} lignées isolées, jobs={max(1, args.jobs)}, game_speed=1")
        return 0
    worker_dir.mkdir(parents=True, exist_ok=True)
    failures: list[str] = []
    with ThreadPoolExecutor(max_workers=max(1, args.jobs)) as executor:
        futures = [executor.submit(run_worker, path, kind, seed) for path, kind, seed in tasks]
        for future in as_completed(futures):
            path, succeeded, returncode = future.result()
            if not succeeded:
                failures.append(f"{path.name}: code={returncode}")
    if failures:
        print("Lignées incomplètes : " + ", ".join(failures), file=sys.stderr)
        return 1
    records = [record for path, _, _ in tasks for record in load_jsonl(path)]
    expected = expected_records()
    errors = validate_records(records, {result_key(record) for record in expected})
    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text("".join(json.dumps(record) + "\n" for record in records), encoding="utf-8")
    output.with_suffix(output.suffix + ".expected.json").write_text(json.dumps(expected, indent=2), encoding="utf-8")
    print(f"SUCCÈS : {len(records)} résultats T0 agrégés dans {output}.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
