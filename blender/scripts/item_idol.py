"""Loot: Humming Idol (1.2 x 2.2 x 1.2 studs). An original, featureless
figure: a hunched, seated shape with a tall blank head on a square plinth,
all in tarnished gold (its one accent), with a single vertical groove where
a face should be."""
import math
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent / "lib"))

import kit  # noqa: E402
from kit import cf, deg  # noqa: E402

GOLD = (196, 150, 60)
fig = kit.Mesh("Figure", "foil", GOLD)
fig.box((1.16, 0.3, 1.16), cf(0, 0.15, 0), bevel=0.08, segments=2)  # plinth
fig.lathe((0, 0.3, 0.02), (0, 1.35, -0.04), [(0.0, 0.5), (0.3, 0.52), (0.65, 0.4), (1.0, 0.22)], segments=14, flat=(1.0, 0.85))  # hunched body
fig.lathe((0, 1.25, -0.06), (0, 2.18, -0.12), [(0.0, 0.16), (0.25, 0.27), (0.7, 0.26), (1.0, 0.12)], segments=14, flat=(0.85, 1.0))  # tall head
for s in (-1, 1):
    fig.lathe((s * 0.38, 1.15, -0.05), (s * 0.3, 0.42, -0.3), [(0.0, 0.1), (0.5, 0.09), (1.0, 0.07)], segments=8)  # arms folded to the knees
groove = kit.Mesh("Groove", "foil", (60, 44, 20))
groove.box((0.05, 0.5, 0.04), cf(0, 1.78, -0.34), bevel=0.015)
kit.finish([fig, groove], "item_idol")
