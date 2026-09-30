"""Exécute et valide le lot de confirmation T3 v3 (Phase 5).

--cards validation : essai à blanc sur les cartes de validation.
--cards final      : lot final sur les cartes fermées 410000201..264.
"""

from __future__ import annotations

import argparse
import json
import subprocess
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

from t3_confirmation_results import INITIALIZATIONS, CARDS, load_jsonl, result_key, validate_records

ROOT = Path(__file__).resolve().parents[1]
FROZEN_PATHS = ("tools", "scripts", "scenes", "project.godot",
                "experiments/apprentissage_t3_contrat_v3.md",
                "experiments/apprentissage_t3_confirmation_contrat_v1.md")
KINDS = ("baseline", "trained", "reset")
PER_CARD = {"baseline": 3, "trained": 1, "reset": 1}


def run_one(godot: str, kind: str, seed: int, cards_mode: str, resume: bool, workers: Path) -> Path:
    workers.mkdir(parents=True, exist_ok=True)
    output = workers / f"{kind}_{seed}.jsonl"
    expected = PER_CARD[kind] * len(CARDS[cards_mode])
    if resume and output.exists() and len(load_jsonl(output)) == expected:
        return output
    command = [godot, "--headless", "--fixed-fps", "60", "--path", str(ROOT),
               "--log-file", str(workers / f"{kind}_{seed}.godot.log"),
               "--scene", "tools/t3_campaign.tscn", "--", "--output", str(output),
               "--kind", kind, "--initialization-seed", str(seed),
               "--contract", "v3c", "--cards", cards_mode]
    process = subprocess.run(command, cwd=ROOT, capture_output=True, text=True, timeout=3600)
    if process.returncode:
        raise RuntimeError(f"{kind}/{seed}: {process.returncode}\n{process.stdout}\n{process.stderr}")
    if len(load_jsonl(output)) != expected:
        raise RuntimeError(f"{kind}/{seed}: nombre de résultats invalide")
    return output


def git(*arguments: str) -> subprocess.CompletedProcess:
    return subprocess.run(["git", *arguments], cwd=ROOT, capture_output=True, text=True)


def frozen_commit() -> str:
    """Refuse le lot final si le code gelé diffère du dernier commit."""
    tracked = git("ls-files", "--error-unmatch", "tools/t3_confirmation_results.py",
                  "tools/run_t3_confirmation.py", "tools/analyze_t3_confirmation.py",
                  FROZEN_PATHS[-1])
    if tracked.returncode:
        raise RuntimeError("Outillage ou contrat de confirmation non commité : gel absent.")
    if git("diff", "--quiet", "HEAD", "--", *FROZEN_PATHS).returncode:
        raise RuntimeError("Le code ou le contrat gelé diffère de HEAD : commiter avant le lot final.")
    return git("rev-parse", "HEAD").stdout.strip()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--godot", default="godot")
    parser.add_argument("--cards", choices=("validation", "final"), required=True)
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--resume", action="store_true")
    parser.add_argument("--confirm-freeze", action="store_true",
                        help="requis pour --cards final : atteste que le gel est commité")
    args = parser.parse_args()
    if args.cards == "final":
        if not args.confirm_freeze:
            parser.error("--cards final exige --confirm-freeze")
        commit = frozen_commit()
        manifest = ROOT / "experiments" / "t3_confirmation_final_manifest.json"
        if manifest.exists() and not args.resume:
            parser.error("un lot final existe déjà : seule --resume est permise")
        if manifest.exists() and json.loads(manifest.read_text(encoding="utf-8"))["commit"] != commit:
            parser.error("reprise avec un commit différent de celui du premier lancement")
        manifest.write_text(json.dumps({"commit": commit}, indent=2) + "\n", encoding="utf-8")
    if args.jobs < 1 or args.jobs > 9:
        parser.error("--jobs doit être compris entre 1 et 9")
    label = "dryrun" if args.cards == "validation" else "final"
    workers = ROOT / "experiments" / f"t3_confirmation_{label}_workers"
    paths: list[Path] = []
    with ThreadPoolExecutor(max_workers=args.jobs) as pool:
        jobs = [pool.submit(run_one, args.godot, kind, seed, args.cards, args.resume, workers)
                for seed in sorted(INITIALIZATIONS) for kind in KINDS]
        for job in as_completed(jobs):
            paths.append(job.result())
    records = [record for path in sorted(paths) for record in load_jsonl(path)]
    errors = validate_records(records, args.cards)
    if errors:
        raise RuntimeError("\n".join(errors[:40]))
    records.sort(key=result_key)
    output = ROOT / "experiments" / f"t3_confirmation_{label}_results.jsonl"
    output.write_text("".join(json.dumps(record, sort_keys=True) + "\n" for record in records), encoding="utf-8")
    print(f"{len(records)} résultats de confirmation conformes : {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
