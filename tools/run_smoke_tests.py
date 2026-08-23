"""Exécute les contrôles minimaux reproductibles du laboratoire IA_Life."""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
LOGS = ROOT / "logs"


def run(command: list[str]) -> None:
    result = subprocess.run(command, cwd=ROOT)
    if result.returncode:
        raise SystemExit(result.returncode)


def main() -> int:
    before = set(LOGS.glob("*.summary.json")) if LOGS.exists() else set()
    run([sys.executable, "tools/run_manual_checks.py"])
    run([sys.executable, "run_headless.py", "experiments/telemetry_smoke_v1.json", "10"])

    after = set(LOGS.glob("*.summary.json"))
    created = sorted(after - before, key=lambda path: path.stat().st_mtime)
    if not created:
        print("Smoke test échoué : aucun résumé n'a été créé.", file=sys.stderr)
        return 1
    run([sys.executable, "tools/aggregate_results.py", str(created[-1]), "--validate-only"])
    print(f"Smoke test réussi : {created[-1].relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
