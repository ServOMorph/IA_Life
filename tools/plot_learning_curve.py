"""Genere un graphique SVG de la courbe d'apprentissage du decideur adaptatif.

Trace le taux de decisions de faim reussies (reward > 0) par fenetre glissante, en
fonction du temps simule, une ligne par (run, agent). Sans dependance externe, meme
esprit que tools/plot_campaign.py.

Usage:
    python tools/aggregate_results.py results/apprentissage_faim_v1 --learning-curve results/apprentissage_faim_v1/curve
    python tools/plot_learning_curve.py results/apprentissage_faim_v1/curve/learning_curve.csv results/apprentissage_faim_v1/charts
"""

from __future__ import annotations

import argparse
import csv
import json
from pathlib import Path

WIDTH = 820
HEIGHT = 460
MARGIN_LEFT = 70
MARGIN_RIGHT = 220
MARGIN_TOP = 50
MARGIN_BOTTOM = 50
COLORS = ["#3366cc", "#cc3333", "#33aa55", "#cc8800", "#8844cc", "#118899"]


def load_rows(csv_path: Path) -> list[dict[str, str]]:
    with csv_path.open(encoding="utf-8") as file:
        return list(csv.DictReader(file))


def _short_params(raw: str) -> str:
    raw = (raw or "").strip()
    if not raw or raw in ("{}", "null"):
        return ""
    try:
        data = json.loads(raw)
    except (ValueError, TypeError):
        return raw
    return ", ".join(f"{key.rsplit('.', 1)[-1]}={value}" for key, value in sorted(data.items()))


def series_from(rows: list[dict[str, str]], metric: str) -> dict[str, list[tuple[float, float]]]:
    series: dict[str, list[tuple[float, float]]] = {}
    for row in rows:
        label = _short_params(row.get("params", "")) or row["run"]
        key = f'{label} / {row["agent"]}'
        series.setdefault(key, []).append((float(row["center_elapsed"]), float(row[metric])))
    for points in series.values():
        points.sort()
    return series


def render_line_chart(title: str, series: dict[str, list[tuple[float, float]]], y_label: str = "valeur") -> str:
    plot_w = WIDTH - MARGIN_LEFT - MARGIN_RIGHT
    plot_h = HEIGHT - MARGIN_TOP - MARGIN_BOTTOM
    all_x = [x for points in series.values() for x, _ in points]
    all_y = [y for points in series.values() for _, y in points]
    max_x = max(all_x) if all_x else 1.0
    min_x = min(all_x) if all_x else 0.0
    span_x = (max_x - min_x) or 1.0
    max_y = max(all_y) if all_y else 1.0
    min_y = min(all_y) if all_y else 0.0
    if min_y >= 0.0 and max_y <= 1.0:
        min_y, max_y = 0.0, 1.0
    else:
        pad = (max_y - min_y) * 0.1 or 0.1
        min_y, max_y = min_y - pad, max_y + pad
    span_y = (max_y - min_y) or 1.0

    def sx(x: float) -> float:
        return MARGIN_LEFT + (x - min_x) / span_x * plot_w

    def sy(y: float) -> float:
        return MARGIN_TOP + (1.0 - (y - min_y) / span_y) * plot_h

    parts = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{WIDTH}" height="{HEIGHT}" font-family="Arial, sans-serif">',
        f'<rect width="{WIDTH}" height="{HEIGHT}" fill="white"/>',
        f'<text x="{MARGIN_LEFT}" y="24" font-size="16" font-weight="bold" fill="#1a1a1a">{title}</text>',
        f'<rect x="{MARGIN_LEFT}" y="{MARGIN_TOP}" width="{plot_w}" height="{plot_h}" fill="none" stroke="#cccccc"/>',
    ]
    for frac in (0.0, 0.25, 0.5, 0.75, 1.0):
        value = min_y + frac * span_y
        y = sy(value)
        parts.append(f'<line x1="{MARGIN_LEFT}" y1="{y:.1f}" x2="{MARGIN_LEFT + plot_w}" y2="{y:.1f}" stroke="#eeeeee"/>')
        parts.append(f'<text x="{MARGIN_LEFT - 8}" y="{y + 4:.1f}" font-size="11" text-anchor="end" fill="#666666">{value:.2f}</text>')
    parts.append(f'<text x="{MARGIN_LEFT + plot_w / 2:.1f}" y="{HEIGHT - 14}" font-size="12" text-anchor="middle" fill="#666666">temps simule au centre de la fenetre (s)</text>')
    parts.append(f'<text x="16" y="{MARGIN_TOP + plot_h / 2:.1f}" font-size="12" text-anchor="middle" fill="#666666" transform="rotate(-90 16 {MARGIN_TOP + plot_h / 2:.1f})">{y_label}</text>')
    for x_frac in (0.0, 0.5, 1.0):
        xv = min_x + x_frac * span_x
        parts.append(f'<text x="{sx(xv):.1f}" y="{MARGIN_TOP + plot_h + 16:.1f}" font-size="11" text-anchor="middle" fill="#666666">{xv:.0f}</text>')

    for index, (key, points) in enumerate(sorted(series.items())):
        color = COLORS[index % len(COLORS)]
        path = " ".join(
            ("M" if i == 0 else "L") + f"{sx(x):.1f},{sy(y):.1f}"
            for i, (x, y) in enumerate(points)
        )
        parts.append(f'<path d="{path}" fill="none" stroke="{color}" stroke-width="2"/>')
        legend_y = MARGIN_TOP + 6 + index * 18
        parts.append(f'<line x1="{MARGIN_LEFT + plot_w + 14}" y1="{legend_y}" x2="{MARGIN_LEFT + plot_w + 34}" y2="{legend_y}" stroke="{color}" stroke-width="2"/>')
        label = key if len(key) <= 40 else key[:37] + "..."
        parts.append(f'<text x="{MARGIN_LEFT + plot_w + 40}" y="{legend_y + 4}" font-size="11" fill="#1a1a1a">{label}</text>')
    parts.append("</svg>")
    return "\n".join(parts)


def main() -> int:
    parser = argparse.ArgumentParser(description="Trace la courbe d'apprentissage SVG du decideur adaptatif.")
    parser.add_argument("csv_path", type=Path, help="learning_curve.csv produit par aggregate_results.py --learning-curve")
    parser.add_argument("output_dir", type=Path)
    args = parser.parse_args()

    rows = load_rows(args.csv_path)
    if not rows:
        print("Aucune ligne dans le CSV.")
        return 1
    args.output_dir.mkdir(parents=True, exist_ok=True)
    for metric, title, y_label, filename in (
        ("success_rate", "Courbe d'apprentissage - taux de decisions de faim reussies", "taux de reussite (reward > 0)", "learning_curve.svg"),
        ("mean_reward", "Courbe d'apprentissage - reward moyen par fenetre", "reward moyen", "learning_curve_reward.svg"),
    ):
        if metric not in rows[0]:
            continue
        svg = render_line_chart(title, series_from(rows, metric), y_label)
        out_path = args.output_dir / filename
        out_path.write_text(svg, encoding="utf-8")
        print(f"Ecrit : {out_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
