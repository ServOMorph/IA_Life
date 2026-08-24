import os
import subprocess
import sys
from pathlib import Path

GODOT_EXE = Path("D:/Godot/godot.exe")
PROJECT_DIR = Path(__file__).resolve().parent


def main() -> int:
    if not GODOT_EXE.exists():
        print(f"Godot introuvable : {GODOT_EXE}")
        return 1

    env = os.environ.copy()
    env["IA_LIFE_RL_MODE"] = "1"

    result = subprocess.run([str(GODOT_EXE), "--path", str(PROJECT_DIR)], env=env)
    return result.returncode


if __name__ == "__main__":
    sys.exit(main())
