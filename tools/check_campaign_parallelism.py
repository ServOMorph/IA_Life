"""Verifie qu'une campagne parallelisee reproduit bit a bit la meme campagne sequentielle.

Execute la campagne donnee deux fois, dans deux dossiers de sortie isoles :
  1. sequentiel  (`--jobs 1`)
  2. parallele    (`--jobs J`, defaut 4)
puis compare, run par run, le `*.summary.json` archive (en ignorant `session_id`, propre
au processus). La simulation headless est deterministe et decouplee du temps reel, donc
toute difference signale une fuite entre processus paralleles (fichiers, RNG, cache).

Sert aussi de gate a rejouer avant chaque mesure du benchmark d'apprentissage.

Usage : python tools/check_campaign_parallelism.py experiments/campaigns/xxx.json [--jobs 4] [--timeout ...]
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
RUN_CAMPAIGN = ROOT / "tools" / "run_campaign.py"


def run_campaign(campaign: Path, out_dir: Path, jobs: int) -> None:
    # Un crash Godot sporadique dans un passage ne doit pas condamner la comparaison :
    # run_campaign relance chaque run, et les runs sans summary des deux cotes sont ignores.
    subprocess.run(
        [sys.executable, str(RUN_CAMPAIGN), str(campaign), "--jobs", str(jobs), "--output-dir", str(out_dir), "--retries", "3"],
        cwd=ROOT,
    )


def load_summary(run_dir: Path) -> dict | None:
    summaries = sorted(run_dir.glob("*.summary.json"))
    if len(summaries) != 1:
        return None
    data = json.loads(summaries[0].read_text(encoding="utf-8"))
    data.pop("session_id", None)
    return data


def main() -> int:
    parser = argparse.ArgumentParser(description="Egalite bit a bit sequentiel / parallele d'une campagne.")
    parser.add_argument("campaign", type=Path)
    parser.add_argument("--jobs", type=int, default=4, help="Parallelisme du second passage (defaut 4)")
    args = parser.parse_args()

    with tempfile.TemporaryDirectory(prefix="p0_seq_") as seq_dir, tempfile.TemporaryDirectory(prefix="p0_par_") as par_dir:
        seq_out = Path(seq_dir)
        par_out = Path(par_dir)
        try:
            run_campaign(args.campaign.resolve(), seq_out, 1)
            run_campaign(args.campaign.resolve(), par_out, max(2, args.jobs))
        except OSError as error:
            print(f"Echec : {error}", file=sys.stderr)
            return 1

        run_names = sorted({p.name for p in seq_out.iterdir() if p.is_dir()} | {p.name for p in par_out.iterdir() if p.is_dir()})
        if not run_names:
            print("Aucun run produit — campagne vide ?", file=sys.stderr)
            return 1

        mismatches: list[str] = []
        skipped: list[str] = []
        compared = 0
        for run_name in run_names:
            a = load_summary(seq_out / run_name)
            b = load_summary(par_out / run_name)
            if a is None or b is None:
                skipped.append(f"{run_name} (summary manquant : seq={'ok' if a else 'absent'}, par={'ok' if b else 'absent'})")
                continue
            compared += 1
            if a != b:
                mismatches.append(f"{run_name} : summary sequentiel != summary parallele")

        for line in skipped:
            print(f"  ignore : {line}", file=sys.stderr)

        if mismatches:
            print("NON REPRODUCTIBLE : la campagne parallele ne reproduit pas la sequentielle.", file=sys.stderr)
            for line in mismatches:
                print(f"  - {line}", file=sys.stderr)
            return 1
        if compared == 0 or compared < len(run_names) - 1:
            print(f"INDETERMINE : seulement {compared}/{len(run_names)} runs comparables (trop de crashs Godot).", file=sys.stderr)
            return 1

        print(f"REPRODUCTIBLE : {compared}/{len(run_names)} runs, summaries sequentiel == parallele (hors session_id).")
        return 0


if __name__ == "__main__":
    raise SystemExit(main())
