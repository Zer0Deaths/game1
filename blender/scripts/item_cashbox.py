"""Loot: Locked Cash Box (1.6 x 0.9 x 1.2 studs). Green-grey steel box with a
lid seam, fold-down handle and a brass lock plate (its one accent)."""
import math
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent / "lib"))

import kit  # noqa: E402
from kit import cf, deg  # noqa: E402

box = kit.Mesh("Box", "painted_metal", (60, 80, 60))
box.box((1.6, 0.58, 1.2), cf(0, 0.29, 0), bevel=0.06, segments=2)
box.box((1.62, 0.24, 1.22), cf(0, 0.72, 0), bevel=0.08, segments=2)  # lid, a hair wider
handle = kit.Mesh("Handle", "brushed_metal", (110, 110, 104))
handle.box((0.7, 0.06, 0.08), cf(0, 0.88, 0), bevel=0.025)
for x in (-0.38, 0.38):
    handle.box((0.08, 0.1, 0.1), cf(x, 0.86, 0), bevel=0.03)
lock = kit.Mesh("Lock", "brushed_metal", (150, 124, 70))
lock.box((0.34, 0.3, 0.04), cf(0, 0.55, -0.61), bevel=0.02)
lock.cyl(0.03, 0.06, cf(0, 0.55, -0.64, ry=deg(90)), segments=8, bevel=0.008)
kit.finish([box, handle, lock], "item_cashbox")
