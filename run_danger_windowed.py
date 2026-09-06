import os
import subprocess
import sys
from pathlib import Path

GODOT_EXE = Path("D:/Godot/godot.exe")
PROJECT_DIR = Path(__file__).resolve().parent
CONFIG_PATH = PROJECT_DIR / "experiments" / "danger_zone_windowed_v1.json"


def main() -> int:
    if not GODOT_EXE.exists():
        print(f"Godot introuvable : {GODOT_EXE}")
        return 1
    if not CONFIG_PATH.exists():
        print(f"Config introuvable : {CONFIG_PATH}")
        return 1

    env = os.environ.copy()
    env["IA_LIFE_DEV_MODE"] = "1"
    env["IA_LIFE_HEADLESS_CONFIG"] = str(CONFIG_PATH)

    result = subprocess.run([str(GODOT_EXE), "--path", str(PROJECT_DIR)], env=env)
    return result.returncode


if __name__ == "__main__":
    sys.exit(main())
