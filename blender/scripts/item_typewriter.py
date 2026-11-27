"""Loot: Typewriter (2 x 1 x 1.6 studs). Black chassis, stepped rows of pale
keys, the platen roller at the back with a sheet still in it (its one accent)."""
import math
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent / "lib"))

import kit  # noqa: E402
from kit import cf, deg  # noqa: E402

body = kit.Mesh("Body", "painted_metal", (30, 34, 30))
body.box((2.0, 0.4, 1.5), cf(0, 0.2, 0.05), bevel=0.1, segments=2)
body.box((1.7, 0.35, 0.6), cf(0, 0.5, 0.45), bevel=0.1, segments=2)  # carriage housing
body.box((0.08, 0.08, 0.5), cf(-0.95, 0.78, 0.25, rx=deg(-20)), bevel=0.03)  # return lever
platen = kit.Mesh("Platen", "rubber", (28, 28, 28))
platen.cyl(1.9, 0.13, cf(0, 0.73, 0.5), segments=14, bevel=0.03)
keys = kit.Mesh("Keys", "worn_plastic", (196, 188, 164))
for row in range(3):
    for k in range(7):
        x = -0.6 + k * 0.2 + row * 0.05
        keys.cyl(0.06, 0.07, cf(x, 0.43 + row * 0.07, -0.52 + row * 0.16, rz=deg(90)), segments=6, bevel=0.0)
keys.box((0.9, 0.06, 0.12), cf(0, 0.42, -0.66), bevel=0.03)  # space bar
paper = kit.Mesh("Paper", "paper", (226, 222, 206))
paper.sheet(1.2, 0.55, cf(0, 0.98, 0.56, rx=deg(-12)), curl=0.03, nx=4, ny=4, seed=5)
kit.finish([body, platen, keys, paper], "item_typewriter")
