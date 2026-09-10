import json
import os
import subprocess
import sys
import tempfile
import uuid
from pathlib import Path

GODOT_EXE = Path("D:/Godot/godot.exe")
PROJECT_DIR = Path(__file__).resolve().parent


def project_revision() -> str:
    try:
        result = subprocess.run(
            ["git", "rev-parse", "HEAD"],
            cwd=PROJECT_DIR,
            capture_output=True,
            text=True,
            check=True,
        )
    except (OSError, subprocess.SubprocessError):
        return "unknown"
    return result.stdout.strip() or "unknown"


def run_headless(overrides: dict, timeout_seconds: int = 150) -> int:
    if not GODOT_EXE.exists():
        print(f"Godot introuvable : {GODOT_EXE}")
        return 1

    config_path = Path(tempfile.gettempdir()) / f"ia_life_headless_config_{uuid.uuid4().hex}.json"
    config_path.write_text(json.dumps(overrides), encoding="utf-8")

    env = os.environ.copy()
    env["IA_LIFE_HEADLESS_CONFIG"] = str(config_path)
    env["IA_LIFE_PROJECT_REVISION"] = project_revision()

    command = [str(GODOT_EXE), "--headless", "--path", str(PROJECT_DIR)]
    fixed_fps = env.get("IA_LIFE_HEADLESS_FIXED_FPS", "")
    if fixed_fps:
        if fixed_fps != "60":
            config_path.unlink(missing_ok=True)
            raise ValueError("IA_LIFE_HEADLESS_FIXED_FPS doit valoir 60 ou etre absent.")
        command.extend(["--fixed-fps", fixed_fps])

    try:
        result = subprocess.run(
            command,
            env=env,
            timeout=timeout_seconds,
        )
        return result.returncode
    except subprocess.TimeoutExpired:
        print("Timeout Python atteint : le process Godot a été tué.")
        return 1
    finally:
        config_path.unlink(missing_ok=True)


def main() -> int:
    overrides = {}
    if len(sys.argv) > 1:
        argument = sys.argv[1]
        config_file = Path(argument)
        overrides = json.loads(config_file.read_text(encoding="utf-8")) if config_file.is_file() else json.loads(argument)
    timeout_seconds = int(sys.argv[2]) if len(sys.argv) > 2 else 150
    return run_headless(overrides, timeout_seconds)


if __name__ == "__main__":
    sys.exit(main())
