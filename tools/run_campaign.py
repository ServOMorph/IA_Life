"""Exécute une campagne IA_Life archivable, séquentielle ou parallélisée.

Le format de campagne contient un fichier de base, une grille de paramètres, des seeds,
un timeout Python et un dossier de sortie. Chaque run reçoit sa propre configuration et
copie les résultats Godot dans son sous-dossier.

Bras (`"arms"`, optionnel) : liste de jeux d'overrides nommés appliqués par-dessus la
config de base, avant la grille. Chaque entrée est
`{"name": "<slug>", "overrides": {"<chemin.pointe>": valeur, ...}}`. Le plan devient le
produit bras × grille × seeds × répétitions ; `metadata.arm` porte le nom du bras. Sans
`"arms"`, comportement inchangé (un seul bras implicite, run_name identique à l'historique).
Sert les mesures benchmark M0..Mf de roadmap_apprentissage_v2 (6 bras appariés au seed).

Parallélisme (`--jobs N`, defaut 1) : N processus Godot tournent de front. Chaque run
ecrit dans son propre `run_dir` (config.json, manifest.json, archives) et chaque instance
Godot horodate sa session avec son PID (`session_<stamp>_pidXXXX`), donc les fichiers de
`logs/` ne se chevauchent jamais. La simulation headless est deterministe et ne depend pas
du temps reel (physique a pas fixe jusqu'a `max_simulation_seconds` de temps *simule*),
donc une campagne parallelisee doit reproduire la meme campagne sequentielle a seeds fixes
— egalite verifiee par `tools/check_campaign_parallelism.py`. `--jobs 1` conserve
exactement le comportement et l'ordre d'origine.

Note : apres avoir ajoute ou retire un script `class_name`, lancer une fois
`godot --headless --import` avant la campagne (l'option `--warmup` le fait) pour que le
cache de classes globales soit a jour dans chaque processus.
"""

from __future__ import annotations

import argparse
import itertools
import json
import re
import shutil
import subprocess
import sys
import threading
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from copy import deepcopy
from pathlib import Path
from typing import Any


PROJECT_DIR = Path(__file__).resolve().parent.parent
RUNNER = PROJECT_DIR / "run_headless.py"
LOG_DIR = PROJECT_DIR / "logs"

_LIVE_PROCS: set[subprocess.Popen] = set()
_LIVE_PROCS_LOCK = threading.Lock()
_INTERRUPTED = threading.Event()


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


_ARM_NAME_RE = re.compile(r"^[A-Za-z0-9_.-]+$")


def parse_arms(raw: Any) -> list[dict[str, Any]]:
    """Normalise le champ optionnel `"arms"`. Absent -> un bras implicite sans override
    (run_name identique a l'historique). Present -> liste de bras nommes, noms uniques et
    surs pour un chemin de fichier, chacun portant un dict d'overrides chemin.pointe -> valeur."""
    if raw is None:
        return [{"name": "", "overrides": {}}]
    if not isinstance(raw, list) or not raw:
        raise ValueError("arms doit être une liste non vide")
    arms: list[dict[str, Any]] = []
    seen: set[str] = set()
    for index, entry in enumerate(raw):
        if not isinstance(entry, dict):
            raise ValueError(f"arms[{index}] doit être un objet")
        name = entry.get("name")
        if not isinstance(name, str) or not _ARM_NAME_RE.match(name):
            raise ValueError(f"arms[{index}].name doit correspondre à [A-Za-z0-9_.-]+")
        if name in seen:
            raise ValueError(f"arms : nom de bras dupliqué '{name}'")
        seen.add(name)
        overrides = entry.get("overrides", {})
        if not isinstance(overrides, dict):
            raise ValueError(f"arms[{index}].overrides doit être un objet")
        arms.append({"name": name, "overrides": overrides})
    return arms


def find_summary_by_experiment_id(experiment_id: str, since: float, attempts: int = 15) -> Path | None:
    """Cherche le summary d'un run par son experiment_id (globalement unique :
    `campaign_id--run_name`). Contrairement a une detection par mtime, ce critere est
    robuste a l'entrelacement des runs paralleles. Quelques essais espacés couvrent la
    latence du systeme de fichiers juste apres la fin du process Godot."""
    floor = since - 5.0
    for attempt in range(attempts):
        candidates = sorted(LOG_DIR.glob("*.summary.json"), key=lambda path: path.stat().st_mtime, reverse=True)
        for path in candidates:
            if path.stat().st_mtime < floor:
                break
            try:
                payload = load_json(path)
            except (OSError, ValueError, json.JSONDecodeError):
                continue
            if payload.get("experiment", {}).get("experiment_id") == experiment_id:
                return path
        if attempt < attempts - 1:
            time.sleep(0.2)
    return None


def archive_result(summary_path: Path, run_dir: Path) -> None:
    stem = summary_path.name.removesuffix(".summary.json")
    for suffix in (".summary.json", ".jsonl", ".log"):
        source = LOG_DIR / f"{stem}{suffix}"
        if source.exists():
            shutil.copy2(source, run_dir / source.name)


def build_run_config(campaign: dict[str, Any], base: dict[str, Any], arm: dict[str, Any], values: dict[str, Any], seed: int, run_name: str) -> dict[str, Any]:
    config = deepcopy(base)
    config["seed"] = seed
    config["experiment_id"] = f"{campaign['campaign_id']}--{run_name}"
    metadata = config.setdefault("metadata", {})
    if not isinstance(metadata, dict):
        raise ValueError("metadata du fichier de base doit être un objet")
    metadata["campaign_id"] = campaign["campaign_id"]
    metadata["arm"] = arm["name"]
    metadata["arm_overrides"] = arm["overrides"]
    metadata["campaign_parameters"] = values
    # Bras d'abord, grille ensuite : sur un chemin commun, le balayage l'emporte.
    for path, value in arm["overrides"].items():
        set_path(config, path, value)
    for path, value in values.items():
        set_path(config, path, value)
    return config


def _godot_attempt(config_path: Path, experiment_id: str, timeout_seconds: int) -> tuple[bool, Path | None, int, bool]:
    """Un lancement Godot. Retourne (ok, summary_path, return_code, timed_out)."""
    started_at = time.time()
    timed_out = False
    return_code = 1
    proc = subprocess.Popen(
        [sys.executable, str(RUNNER), str(config_path), str(timeout_seconds)],
        cwd=PROJECT_DIR,
    )
    with _LIVE_PROCS_LOCK:
        _LIVE_PROCS.add(proc)
    try:
        return_code = proc.wait(timeout=timeout_seconds + 60)
    except subprocess.TimeoutExpired:
        timed_out = True
        proc.kill()
        proc.wait()
    finally:
        with _LIVE_PROCS_LOCK:
            _LIVE_PROCS.discard(proc)
    summary_path = None if timed_out else find_summary_by_experiment_id(experiment_id, started_at)
    return (return_code == 0 and summary_path is not None, summary_path, return_code, timed_out)


def execute_run(
    campaign: dict[str, Any],
    base: dict[str, Any],
    arm: dict[str, Any],
    values: dict[str, Any],
    seed: int,
    repetition: int,
    index: int,
    output_dir: Path,
    timeout_seconds: int,
    resume: bool,
    retries: int = 2,
) -> dict[str, Any]:
    arm_tag = f"{arm['name']}_" if arm["name"] else ""
    run_name = f"run_{index:04d}_{arm_tag}seed_{seed}_rep_{repetition + 1}"
    run_dir = output_dir / run_name
    manifest_path = run_dir / "manifest.json"
    base_manifest = {
        "campaign_id": campaign["campaign_id"],
        "run_name": run_name,
        "arm": arm["name"],
        "seed": seed,
        "repetition": repetition + 1,
        "parameters": values,
    }

    if manifest_path.exists():
        manifest = load_json(manifest_path)
        if manifest.get("status") == "completed":
            if resume:
                print(f"Reprise : {run_name} déjà terminé.")
                return manifest
            raise ValueError(f"{run_dir} existe déjà ; utilisez --resume ou choisissez un autre output_dir")
        if not resume:
            raise ValueError(f"{run_dir} existe déjà ; utilisez --resume ou choisissez un autre output_dir")

    if _INTERRUPTED.is_set():
        return {**base_manifest, "status": "skipped", "error": "interrupted"}

    config = build_run_config(campaign, base, arm, values, seed, run_name)
    run_dir.mkdir(parents=True, exist_ok=True)
    config_path = run_dir / "config.json"
    config_path.write_text(json.dumps(config, ensure_ascii=False, indent=2), encoding="utf-8")

    running_manifest = {**base_manifest, "status": "running", "started_at": time.time()}
    manifest_path.write_text(json.dumps(running_manifest, ensure_ascii=False, indent=2), encoding="utf-8")

    # Godot headless crashe sporadiquement sous Windows (sortie -1, aucun summary), sans
    # lien avec la config : un crash isole ne doit pas condamner un run reproductible.
    # Nouvel essai tant qu'il reste des tentatives et que l'interruption n'est pas demandee.
    attempts = 0
    ok = False
    summary_path = None
    return_code = 1
    timed_out = False
    while attempts <= retries and not _INTERRUPTED.is_set():
        attempts += 1
        ok, summary_path, return_code, timed_out = _godot_attempt(config_path, config["experiment_id"], timeout_seconds)
        if ok:
            break
        if attempts <= retries:
            print(f"{run_name} : echec (code {return_code}{', timeout' if timed_out else ''}), nouvel essai {attempts}/{retries}")

    manifest = dict(base_manifest)
    manifest["attempts"] = attempts
    if ok:
        archive_result(summary_path, run_dir)
        manifest["status"] = "completed"
        manifest["summary"] = summary_path.name
    else:
        manifest["status"] = "failed"
        manifest["return_code"] = return_code
        manifest["error"] = "timeout" if timed_out else ("summary_missing" if summary_path is None else "runner_failed")
    manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"{run_name} : {manifest['status']}")
    return manifest


def warmup_import() -> None:
    if str(PROJECT_DIR) not in sys.path:
        sys.path.insert(0, str(PROJECT_DIR))
    from run_headless import GODOT_EXE

    if not Path(GODOT_EXE).exists():
        print(f"Warmup ignoré : Godot introuvable ({GODOT_EXE})", file=sys.stderr)
        return
    print("Warmup : godot --headless --import")
    subprocess.run([str(GODOT_EXE), "--headless", "--import", "--path", str(PROJECT_DIR)], cwd=PROJECT_DIR)


def kill_live_procs() -> None:
    with _LIVE_PROCS_LOCK:
        procs = list(_LIVE_PROCS)
    for proc in procs:
        proc.terminate()
    for proc in procs:
        try:
            proc.wait(timeout=10)
        except subprocess.TimeoutExpired:
            proc.kill()


def run_campaign(campaign_path: Path, resume: bool, dry_run: bool, jobs: int, warmup: bool, output_dir_override: Path | None = None, retries: int = 2) -> int:
    campaign = load_json(campaign_path)
    required = ("campaign_id", "base_config", "parameter_grid", "seeds", "output_dir")
    missing = [key for key in required if key not in campaign]
    if missing:
        raise ValueError(f"Champs de campagne manquants : {', '.join(missing)}")
    base_path = (campaign_path.parent / campaign["base_config"]).resolve()
    base = load_json(base_path)
    combinations = grid_combinations(campaign["parameter_grid"])
    arms = parse_arms(campaign.get("arms"))
    seeds = campaign["seeds"]
    if not isinstance(seeds, list) or not all(isinstance(seed, int) and seed >= 0 for seed in seeds):
        raise ValueError("seeds doit être une liste d'entiers positifs ou nuls")
    repetitions = campaign.get("repetitions", 1)
    if not isinstance(repetitions, int) or repetitions < 1:
        raise ValueError("repetitions doit être un entier >= 1")
    timeout_seconds = campaign.get("python_timeout_seconds", 150)
    if output_dir_override is not None:
        output_dir = output_dir_override.resolve()
    else:
        output_dir = (campaign_path.parent / campaign["output_dir"]).resolve()
    output_dir.mkdir(parents=True, exist_ok=True)
    plan = [(arm, values, seed, repetition) for arm in arms for values in combinations for seed in seeds for repetition in range(repetitions)]

    if dry_run:
        for index, (arm, values, seed, repetition) in enumerate(plan, start=1):
            arm_tag = f"{arm['name']}_" if arm["name"] else ""
            run_name = f"run_{index:04d}_{arm_tag}seed_{seed}_rep_{repetition + 1}"
            print(f"Planifié : {run_name} arm={arm['name'] or '-'} {values}")
        print(f"{len(plan)} runs planifiés ({len(arms)} bras x {len(combinations)} combos x {len(seeds)} seeds x {repetitions} rep), jobs={max(1, jobs)}")
        return 0

    if warmup:
        warmup_import()

    outcomes: list[dict[str, Any]] = []
    jobs = max(1, jobs)
    tasks = list(enumerate(plan, start=1))

    if jobs == 1:
        try:
            for index, (arm, values, seed, repetition) in tasks:
                outcomes.append(execute_run(campaign, base, arm, values, seed, repetition, index, output_dir, timeout_seconds, resume, retries))
        except KeyboardInterrupt:
            _INTERRUPTED.set()
            kill_live_procs()
            print("Campagne interrompue — relancer avec --resume.", file=sys.stderr)
    else:
        with ThreadPoolExecutor(max_workers=jobs) as executor:
            futures = {
                executor.submit(execute_run, campaign, base, arm, values, seed, repetition, index, output_dir, timeout_seconds, resume, retries): index
                for index, (arm, values, seed, repetition) in tasks
            }
            try:
                for future in as_completed(futures):
                    outcomes.append(future.result())
            except KeyboardInterrupt:
                _INTERRUPTED.set()
                kill_live_procs()
                for future in futures:
                    future.cancel()
                for future in futures:
                    if future.done() and not future.cancelled():
                        try:
                            outcomes.append(future.result())
                        except Exception:
                            pass
                print("Campagne interrompue — relancer avec --resume.", file=sys.stderr)

    outcomes.sort(key=lambda item: item.get("run_name", ""))
    report = {
        "campaign_id": campaign["campaign_id"],
        "total_runs": len(plan),
        "completed_runs": sum(item.get("status") == "completed" for item in outcomes),
        "failed_runs": sum(item.get("status") == "failed" for item in outcomes),
        "jobs": jobs,
        "runs": outcomes,
    }
    (output_dir / "campaign_report.json").write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    if _INTERRUPTED.is_set():
        return 1
    return 0 if report["failed_runs"] == 0 and report["completed_runs"] == report["total_runs"] else 1


def main() -> int:
    parser = argparse.ArgumentParser(description="Exécute une campagne IA_Life.")
    parser.add_argument("campaign", type=Path)
    parser.add_argument("--resume", action="store_true", help="Ignore les runs déjà terminés")
    parser.add_argument("--dry-run", action="store_true", help="Affiche le plan sans exécuter")
    parser.add_argument("--jobs", type=int, default=1, help="Nombre de processus Godot simultanés (defaut 1 = séquentiel)")
    parser.add_argument("--warmup", action="store_true", help="Lance `godot --headless --import` avant la campagne")
    parser.add_argument("--output-dir", type=Path, default=None, help="Remplace output_dir de la campagne (tests, rejeux isolés)")
    parser.add_argument("--retries", type=int, default=2, help="Nombre de nouveaux essais par run apres un crash Godot (defaut 2)")
    args = parser.parse_args()
    try:
        return run_campaign(args.campaign.resolve(), args.resume, args.dry_run, args.jobs, args.warmup, args.output_dir, args.retries)
    except (OSError, ValueError, json.JSONDecodeError) as error:
        print(f"Campagne refusée : {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
