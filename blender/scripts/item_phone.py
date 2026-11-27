"""Loot: Rotary Phone (1.4 x 0.9 x 1.2 studs). Oxblood body (its one accent),
handset on the cradle, dial on the sloped front."""
import math
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent / "lib"))

import kit  # noqa: E402
from kit import cf, deg  # noqa: E402

RED = (132, 38, 34)
body = kit.Mesh("Body", "worn_plastic", RED)
body.box((1.36, 0.36, 1.16), cf(0, 0.18, 0), bevel=0.1, segments=2)
body.box((1.0, 0.24, 0.8), cf(0, 0.44, 0.08, rx=deg(-14)), bevel=0.1, segments=2)  # sloped top
handset = kit.Mesh("Handset", "worn_plastic", RED)
handset.box((1.3, 0.12, 0.24), cf(0, 0.8, 0.28), bevel=0.06, segments=2)  # grip
for x in (-0.58, 0.58):
    handset.cyl(0.2, 0.16, cf(x, 0.72, 0.28, rz=deg(90)), segments=12, bevel=0.03)  # ear and mouth cups
dial = kit.Mesh("Dial", "brushed_metal", (150, 146, 136))
dial.cyl(0.05, 0.3, cf(0, 0.52, -0.38, rx=deg(-14), ry=deg(90)), segments=18, bevel=0.015)
dark = kit.Mesh("DialFace", "worn_plastic", (34, 30, 28))
for k in range(8):
    a = deg(40 + k * 32)
    dark.cyl(0.03, 0.04, cf(-math.sin(a) * 0.21, 0.52 + math.cos(a) * 0.21 * 0.97, -0.43 - math.cos(a) * 0.05, rx=deg(-14), ry=deg(90)), segments=6, bevel=0.005)
kit.finish([body, handset, dial, dark], "item_phone")
