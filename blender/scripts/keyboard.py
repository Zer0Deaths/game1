"""Beige office keyboard (1.5 x 0.08 x 0.5 studs on the desk): sloped case,
four rows of keys and a space bar along the +Z edge (the desk chair's
side). Origin on the desk under its centre."""
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent / "lib"))

import kit  # noqa: E402
from kit import cf, deg  # noqa: E402
from shapes import slab  # noqa: E402

case = kit.Mesh("Case", "worn_plastic", (186, 180, 162))
case.box((1.5, 0.06, 0.5), cf(0, 0.03, 0, rx=deg(-3)), bevel=0.02)
keys = kit.Mesh("Keys", "worn_plastic", (206, 200, 182))
k = 0.085
for row in range(4):
    z = -0.15 + row * 0.095
    n = 13 - (row % 2)
    x0 = -0.62 + (row % 2) * 0.045
    for i in range(n):
        if row == 3 and 3 <= i <= 8:
            continue
        slab(keys, (k, 0.04, k), cf(x0 + i * 0.1, 0.075 - row * 0.004, z), bevel=0.012, bevel_faces=("top",), drop=("bottom",))
slab(keys, (0.55, 0.04, k), cf(-0.04, 0.062, 0.135), bevel=0.012, bevel_faces=("top",), drop=("bottom",))  # space bar
kit.finish([case, keys], "keyboard")
