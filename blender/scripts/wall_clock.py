"""Wall clock (2.1 studs across), stopped at 3:17. The face is plain so the
game's second hand can twitch in front of it. Front -Z.

Seen from the front (-Z) the viewer's right is -X, so clockwise angles go
toward -X: a point at angle a is (-sin a, cos a)."""
import math
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent / "lib"))

import kit  # noqa: E402
from kit import cf, deg  # noqa: E402

rim = kit.Mesh("Rim", "worn_plastic", (40, 38, 34))
rim.cyl(0.22, 1.05, cf(0, 0, 0.05, ry=deg(90)), segments=28, bevel=0.06)
rim.torus(0.98, 0.08, cf(0, 0, -0.07, ry=deg(90)), segments=28, sides=8)
face = kit.Mesh("Face", "paper", (214, 208, 188))
face.cyl(0.02, 0.92, cf(0, 0, -0.07, ry=deg(90)), segments=28, bevel=0.005)
marks = kit.Mesh("Marks", "worn_plastic", (40, 38, 34))
for k in range(12):
    a = k * math.pi / 6
    long = k % 3 == 0
    marks.box((0.05, 0.2 if long else 0.11, 0.015), cf(-math.sin(a) * 0.76, math.cos(a) * 0.76, -0.085, rz=a), bevel=0.006)
hands = kit.Mesh("Hands", "worn_plastic", (30, 28, 26))
minute = 17 / 60 * 2 * math.pi
hour = (3 + 17 / 60) / 12 * 2 * math.pi
hands.box((0.06, 0.66, 0.02), cf(-math.sin(minute) * 0.3, math.cos(minute) * 0.3, -0.1, rz=minute), bevel=0.008)
hands.box((0.08, 0.44, 0.02), cf(-math.sin(hour) * 0.2, math.cos(hour) * 0.2, -0.105, rz=hour), bevel=0.008)
hands.cyl(0.04, 0.06, cf(0, 0, -0.115, ry=deg(90)), segments=10, bevel=0.01)
kit.finish([rim, face, marks, hands], "wall_clock")
