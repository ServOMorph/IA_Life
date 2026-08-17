import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path

GODOT_EXE = Path("D:/Godot/godot.exe")
PROJECT_DIR = Path(__file__).resolve().parent


def run_headless(overrides: dict, timeout_seconds: int = 150) -> int:
    if not GODOT_EXE.exists():
        print(f"Godot introuvable : {GODOT_EXE}")
        return 1

    config_path = Path(tempfile.gettempdir()) / "ia_life_headless_config.json"
    config_path.write_text(json.dumps(overrides), encoding="utf-8")

    env = os.environ.copy()
    env["IA_LIFE_HEADLESS_CONFIG"] = str(config_path)

    try:
        result = subprocess.run(
            [str(GODOT_EXE), "--headless", "--path", str(PROJECT_DIR)],
            env=env,
            timeout=timeout_seconds,
        )
        return result.returncode
    except subprocess.TimeoutExpired:
        print("Timeout Python atteint : le process Godot a été tué.")
        return 1


def main() -> int:
    overrides = {}
    if len(sys.argv) > 1:
        overrides = json.loads(sys.argv[1])
    timeout_seconds = int(sys.argv[2]) if len(sys.argv) > 2 else 150
    return run_headless(overrides, timeout_seconds)


if __name__ == "__main__":
    sys.exit(main())
