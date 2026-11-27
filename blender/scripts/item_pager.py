"""Loot: Dead Pager (0.8 x 0.4 x 1.2 studs, lying on its back).
Chunky rounded body, a dead grey-green screen as its one accent, belt clip."""
import math
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent / "lib"))

import kit  # noqa: E402
from kit import cf, deg  # noqa: E402

body = kit.Mesh("Body", "worn_plastic", (40, 40, 44))
body.box((0.78, 0.3, 1.16), cf(0, 0.17, 0), bevel=0.1, segments=2)
body.box((0.5, 0.06, 0.5), cf(0, 0.03, 0.15), bevel=0.02)  # belt clip underneath
body.cyl(0.1, 0.06, cf(-0.25, 0.2, -0.62, ry=deg(90)), segments=8, bevel=0.02)  # stub antenna
for x in (-0.22, 0, 0.22):
    body.box((0.16, 0.06, 0.12), cf(x, 0.33, 0.38), bevel=0.025)  # buttons
screen = kit.Mesh("Screen", "worn_plastic", (104, 122, 92))
screen.box((0.56, 0.04, 0.36), cf(0, 0.32, -0.15), bevel=0.015)
kit.finish([body, screen], "item_pager")
