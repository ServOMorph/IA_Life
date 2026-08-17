import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path

GODOT_EXE = Path("D:/Godot/godot.exe")
PROJECT_DIR = Path(__file__).resolve().parent


def take_screenshot(output_path: str, delay_seconds: float = 4.0, overrides: dict | None = None, timeout_seconds: int = 60) -> int:
    if not GODOT_EXE.exists():
        print(f"Godot introuvable : {GODOT_EXE}")
        return 1

    config = dict(overrides or {})
    config["screenshot"] = {"path": output_path, "delay_seconds": delay_seconds}

    config_path = Path(tempfile.gettempdir()) / "ia_life_screenshot_config.json"
    config_path.write_text(json.dumps(config), encoding="utf-8")

    env = os.environ.copy()
    env["IA_LIFE_HEADLESS_CONFIG"] = str(config_path)

    try:
        result = subprocess.run(
            [str(GODOT_EXE), "--path", str(PROJECT_DIR)],
            env=env,
            timeout=timeout_seconds,
        )
        return result.returncode
    except subprocess.TimeoutExpired:
        print("Timeout Python atteint : le process Godot a été tué.")
        return 1


def main() -> int:
    if len(sys.argv) < 2:
        print("Usage: run_screenshot.py <output_path> [delay_seconds] [overrides_json]")
        return 1
    output_path = sys.argv[1]
    delay_seconds = float(sys.argv[2]) if len(sys.argv) > 2 else 4.0
    overrides = json.loads(sys.argv[3]) if len(sys.argv) > 3 else {}
    return take_screenshot(output_path, delay_seconds, overrides)


if __name__ == "__main__":
    sys.exit(main())
