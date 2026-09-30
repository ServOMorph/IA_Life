"""Analyse le diagnostic de navigation T1 v4 sur cartes d'entraînement."""

from __future__ import annotations

import argparse
import json
from collections import Counter
from pathlib import Path


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("path", type=Path)
    args = parser.parse_args()
    records = [json.loads(line) for line in args.path.read_text(encoding="utf-8").splitlines() if line]
    expected = {(seed, mode) for seed in range(360000001, 360000033)
                for mode in ("learned", "hold_first", "retarget")}
    keys = [(row["card_seed"], row["mode"]) for row in records]
    if len(records) != 96 or set(keys) != expected or len(set(keys)) != len(keys):
        raise RuntimeError("Lot de diagnostic incomplet ou dupliqué")
    summary: dict[str, Counter] = {}
    for mode in ("learned", "hold_first", "retarget"):
        rows = [row for row in records if row["mode"] == mode]
        summary[mode] = Counter(
            total=len(rows),
            first_correct=sum(row["first_selected_available"] for row in rows),
            consumed=sum(row["consumed"] for row in rows),
            regressed=sum(any(after > before + 1e-4 for before, after in zip(row["distances"], row["distances"][1:]))
                          for row in rows),
        )
    learned_failures = [row for row in records if row["mode"] == "learned" and not row["consumed"]]
    print(json.dumps({mode: dict(counts) for mode, counts in summary.items()}, indent=2, sort_keys=True))
    print(json.dumps({"learned_failure_examples": [
        {"card_seed": row["card_seed"], "target": row["available_sector"],
         "actions": row["actions"], "distances": [round(value, 3) for value in row["distances"]]}
        for row in learned_failures[:5]
    ]}, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
