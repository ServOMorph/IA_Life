import subprocess
import sys
from pathlib import Path

GODOT_EXE = Path("D:/Godot/godot.exe")
PROJECT_DIR = Path(__file__).resolve().parent.parent


def main() -> int:
    if not GODOT_EXE.exists():
        print(f"Godot introuvable : {GODOT_EXE}")
        return 1
    return subprocess.run([
        str(GODOT_EXE), "--headless", "--path", str(PROJECT_DIR),
        "--scene", "tools/t0_scenario_tests.tscn",
    ]).returncode


if __name__ == "__main__":
    sys.exit(main())
