"""Exécute une campagne IA_Life séquentielle et archivable.

Le format de campagne contient un fichier de base, une grille de paramètres, des seeds,
un timeout Python et un dossier de sortie. Chaque run reçoit sa propre configuration et
copie les résultats Godot dans son sous-dossier avant de passer au suivant.
"""

from __future__ import annotations

import argparse
import itertools
import json
import shutil
import subprocess
import sys
import time
from copy import deepcopy
from pathlib import Path
from typing import Any


PROJECT_DIR = Path(__file__).resolve().parent.parent
RUNNER = PROJECT_DIR / "run_headless.py"
LOG_DIR = PROJECT_DIR / "logs"


def load_json(path: Path) -> dict[str, Any]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(payload, dict):
        raise ValueError(f"{path} doit contenir un objet JSON")
    return payload


def set_path(payload: dict[str, Any], dotted_path: str, value: Any) -> None:
    parts = dotted_path.split(".")
    if not all(parts):
        raise ValueError(f"Chemin de paramètre invalide : {dotted_path}")
    target: dict[str, Any] = payload
    for part in parts[:-1]:
        current = target.get(part)
        if current is None:
            current = {}
            target[part] = current
        if not isinstance(current, dict):
            raise ValueError(f"{dotted_path} traverse une valeur non objet à {part}")
        target = current
    target[parts[-1]] = value


def grid_combinations(grid: dict[str, list[Any]]) -> list[dict[str, Any]]:
    if not isinstance(grid, dict):
        raise ValueError("parameter_grid doit être un objet")
    paths = list(grid)
    values = []
    for path in paths:
        if not isinstance(grid[path], list) or not grid[path]:
            raise ValueError(f"parameter_grid.{path} doit être une liste non vide")
        values.append(grid[path])
    return [dict(zip(paths, combination)) for combination in itertools.product(*values)]


def find_result_after(started_at: float, experiment_id: str) -> Path | None:
    candidates = sorted(LOG_DIR.glob("*.summary.json"), key=lambda path: path.stat().st_mtime, reverse=True)
    for path in candidates:
        if path.stat().st_mtime < started_at - 1.0:
            break
        try:
            payload = load_json(path)
        except (OSError, ValueError, json.JSONDecodeError):
            continue
        if payload.get("experiment", {}).get("experiment_id") == experiment_id:
            return path
    return None


def archive_result(summary_path: Path, run_dir: Path) -> None:
    stem = summary_path.name.removesuffix(".summary.json")
    for suffix in (".summary.json", ".jsonl", ".log"):
        source = LOG_DIR / f"{stem}{suffix}"
        if source.exists():
            shutil.copy2(source, run_dir / source.name)


def run_campaign(campaign_path: Path, resume: bool, dry_run: bool) -> int:
    campaign = load_json(campaign_path)
    required = ("campaign_id", "base_config", "parameter_grid", "seeds", "output_dir")
    missing = [key for key in required if key not in campaign]
    if missing:
        raise ValueError(f"Champs de campagne manquants : {', '.join(missing)}")
    base_path = (campaign_path.parent / campaign["base_config"]).resolve()
    base = load_json(base_path)
    combinations = grid_combinations(campaign["parameter_grid"])
    seeds = campaign["seeds"]
    if not isinstance(seeds, list) or not all(isinstance(seed, int) and seed >= 0 for seed in seeds):
        raise ValueError("seeds doit être une liste d'entiers positifs ou nuls")
    repetitions = campaign.get("repetitions", 1)
    if not isinstance(repetitions, int) or repetitions < 1:
        raise ValueError("repetitions doit être un entier >= 1")
    timeout_seconds = campaign.get("python_timeout_seconds", 150)
    output_dir = (campaign_path.parent / campaign["output_dir"]).resolve()
    output_dir.mkdir(parents=True, exist_ok=True)
    plan = [(values, seed, repetition) for values in combinations for seed in seeds for repetition in range(repetitions)]
    outcomes: list[dict[str, Any]] = []
    for index, (values, seed, repetition) in enumerate(plan, start=1):
        run_name = f"run_{index:04d}_seed_{seed}_rep_{repetition + 1}"
        run_dir = output_dir / run_name
        manifest_path = run_dir / "manifest.json"
        if dry_run:
            print(f"Planifié : {run_name} {values}")
            outcomes.append({
                "campaign_id": campaign["campaign_id"],
                "run_name": run_name,
                "seed": seed,
                "repetition": repetition + 1,
                "parameters": values,
                "status": "planned",
            })
            continue
        if manifest_path.exists():
            manifest = load_json(manifest_path)
            if resume and manifest.get("status") == "completed":
                print(f"Reprise : {run_name} déjà terminé.")
                outcomes.append(manifest)
                continue
            if not resume:
                raise ValueError(f"{run_dir} existe déjà ; utilisez --resume ou choisissez un autre output_dir")
        config = deepcopy(base)
        config["seed"] = seed
        config["experiment_id"] = f"{campaign['campaign_id']}--{run_name}"
        metadata = config.setdefault("metadata", {})
        if not isinstance(metadata, dict):
            raise ValueError("metadata du fichier de base doit être un objet")
        metadata["campaign_id"] = campaign["campaign_id"]
        metadata["campaign_parameters"] = values
        for path, value in values.items():
            set_path(config, path, value)
        manifest = {
            "campaign_id": campaign["campaign_id"],
            "run_name": run_name,
            "seed": seed,
            "repetition": repetition + 1,
            "parameters": values,
            "status": "planned",
        }
        run_dir.mkdir(parents=True, exist_ok=True)
        config_path = run_dir / "config.json"
        config_path.write_text(json.dumps(config, ensure_ascii=False, indent=2), encoding="utf-8")
        started_at = time.time()
        result = subprocess.run([sys.executable, str(RUNNER), str(config_path), str(timeout_seconds)], cwd=PROJECT_DIR)
        summary_path = find_result_after(started_at, config["experiment_id"])
        if result.returncode == 0 and summary_path is not None:
            archive_result(summary_path, run_dir)
            manifest["status"] = "completed"
            manifest["summary"] = summary_path.name
        else:
            manifest["status"] = "failed"
            manifest["return_code"] = result.returncode
            manifest["error"] = "summary_missing" if summary_path is None else "runner_failed"
        manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")
        outcomes.append(manifest)
        print(f"{run_name} : {manifest['status']}")
    if dry_run:
        return 0
    report = {
        "campaign_id": campaign["campaign_id"],
        "total_runs": len(outcomes),
        "completed_runs": sum(item.get("status") == "completed" for item in outcomes),
        "failed_runs": sum(item.get("status") == "failed" for item in outcomes),
        "runs": outcomes,
    }
    (output_dir / "campaign_report.json").write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    return 0 if report["failed_runs"] == 0 else 1


def main() -> int:
    parser = argparse.ArgumentParser(description="Exécute une campagne IA_Life.")
    parser.add_argument("campaign", type=Path)
    parser.add_argument("--resume", action="store_true", help="Ignore les runs déjà terminés")
    parser.add_argument("--dry-run", action="store_true", help="Affiche le plan sans exécuter")
    args = parser.parse_args()
    try:
        return run_campaign(args.campaign.resolve(), args.resume, args.dry_run)
    except (OSError, ValueError, json.JSONDecodeError) as error:
        print(f"Campagne refusée : {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
