import subprocess
import sys
from pathlib import Path

GODOT_EXE = Path("D:/Godot/godot.exe")
PROJECT_DIR = Path(__file__).resolve().parent.parent
LOG_PATH = PROJECT_DIR / "logs" / "godot_t0_scenario_tests.log"
SUCCESS_MARKER = "SUCCÈS : scénario alimentaire T0 validé."


def main() -> int:
    if not GODOT_EXE.exists():
        print(f"Godot introuvable : {GODOT_EXE}")
        return 1
    completed = subprocess.run([
        str(GODOT_EXE), "--headless", "--path", str(PROJECT_DIR),
        "--log-file", str(LOG_PATH),
        "--scene", "tools/t0_scenario_tests.tscn",
    ])
    log = LOG_PATH.read_text(encoding="utf-8") if LOG_PATH.exists() else ""
    if SUCCESS_MARKER in log and "SCRIPT ERROR:" not in log:
        return 0
    return completed.returncode or 1


if __name__ == "__main__":
    sys.exit(main())
