"""Genere des graphiques SVG simples a partir du CSV agrege d'une campagne IA_Life.

Usage:
    python tools/plot_campaign.py results/memory_capacity_campaign_v1/agents.csv results/memory_capacity_campaign_v1/charts
    python tools/plot_campaign.py results/contrasted_profiles_campaign_v1/agents.csv results/contrasted_profiles_campaign_v1/charts --group-by agent
"""

from __future__ import annotations

import argparse
import csv
import statistics
from pathlib import Path

DEFAULT_METRICS = [
    "distance_travelled_total",
    "lifetime_seconds",
    "zone_discoveries_total",
    "memorized_ronces",
    "berries_picked_total",
    "berries_eaten_total",
]

WIDTH = 760
BAR_HEIGHT = 32
BAR_GAP = 14
MARGIN_LEFT = 280
MARGIN_RIGHT = 100
MARGIN_TOP = 50
MARGIN_BOTTOM = 20


def load_rows(csv_path: Path) -> list[dict[str, str]]:
    with csv_path.open(encoding="utf-8") as file:
        return list(csv.DictReader(file))


def group_rows(rows: list[dict[str, str]], group_by: str) -> dict[str, list[dict[str, str]]]:
    groups: dict[str, list[dict[str, str]]] = {}
    for row in rows:
        groups.setdefault(row[group_by], []).append(row)
    return groups


def metric_value(rows: list[dict[str, str]], metric: str) -> float:
    if metric == "survival_rate":
        values = [1.0 if row["alive"] == "True" else 0.0 for row in rows]
    else:
        values = [float(row[metric]) for row in rows]
    return statistics.fmean(values) if values else 0.0


def render_bar_chart(title: str, categories: list[str], values: list[float]) -> str:
    height = MARGIN_TOP + MARGIN_BOTTOM + len(categories) * (BAR_HEIGHT + BAR_GAP)
    max_value = max(values) if values and max(values) > 0 else 1.0
    plot_width = WIDTH - MARGIN_LEFT - MARGIN_RIGHT
    parts = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{WIDTH}" height="{height}" font-family="Arial, sans-serif">',
        f'<rect width="{WIDTH}" height="{height}" fill="white"/>',
        f'<text x="{MARGIN_LEFT}" y="24" font-size="16" font-weight="bold" fill="#1a1a1a">{title}</text>',
    ]
    for index, (category, value) in enumerate(zip(categories, values)):
        y = MARGIN_TOP + index * (BAR_HEIGHT + BAR_GAP)
        bar_width = (value / max_value) * plot_width if max_value else 0.0
        label = category if len(category) <= 42 else category[:39] + "..."
        parts.append(
            f'<text x="{MARGIN_LEFT - 10}" y="{y + BAR_HEIGHT * 0.65:.1f}" font-size="13" '
            f'text-anchor="end" fill="#1a1a1a">{label}</text>'
        )
        parts.append(
            f'<rect x="{MARGIN_LEFT}" y="{y}" width="{bar_width:.1f}" height="{BAR_HEIGHT}" fill="#3366cc"/>'
        )
        parts.append(
            f'<text x="{MARGIN_LEFT + bar_width + 8:.1f}" y="{y + BAR_HEIGHT * 0.65:.1f}" '
            f'font-size="13" fill="#1a1a1a">{value:.2f}</text>'
        )
    parts.append("</svg>")
    return "\n".join(parts)


def main() -> int:
    parser = argparse.ArgumentParser(description="Genere des graphiques SVG a partir du CSV agrege d'une campagne.")
    parser.add_argument("csv_path", type=Path)
    parser.add_argument("output_dir", type=Path)
    parser.add_argument("--group-by", default="comparison_group")
    parser.add_argument("--metric", action="append", dest="metrics", help="Repetable ; par defaut survival_rate + jeu standard")
    args = parser.parse_args()

    rows = load_rows(args.csv_path)
    if not rows:
        print("Aucune ligne dans le CSV.")
        return 1
    metrics = args.metrics or (["survival_rate"] + [m for m in DEFAULT_METRICS if m in rows[0]])
    groups = group_rows(rows, args.group_by)
    categories = sorted(groups)
    labels = [category.split(" | ", 1)[-1] for category in categories]
    args.output_dir.mkdir(parents=True, exist_ok=True)
    for metric in metrics:
        values = [metric_value(groups[category], metric) for category in categories]
        svg = render_bar_chart(metric, labels, values)
        out_path = args.output_dir / f"{metric}.svg"
        out_path.write_text(svg, encoding="utf-8")
        print(f"Ecrit : {out_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
