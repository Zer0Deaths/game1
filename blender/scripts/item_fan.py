"""Loot: Desk Fan (1.8 x 1.8 x 0.8 studs). Round wire guard and blades on a
motor and stand; the pale painted guard is its one accent. Faces -Z."""
import math
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent / "lib"))

import kit  # noqa: E402
from kit import cf, deg  # noqa: E402

C = 0.95  # height of the hub
guard = kit.Mesh("Guard", "painted_metal", (190, 190, 176))
for z in (-0.28, 0.08):
    guard.torus(0.82, 0.035, cf(0, C, z, ry=deg(90)), segments=28, sides=6)
guard.torus(0.42, 0.025, cf(0, C, -0.3, ry=deg(90)), segments=18, sides=5)
for k in range(10):
    a = k * math.pi / 5
    guard.box((0.03, 0.82, 0.03), cf(-math.sin(a) * 0.41, C + math.cos(a) * 0.41, -0.3, rz=a), bevel=0.01)
blades = kit.Mesh("Blades", "painted_metal", (150, 150, 140))
for k in range(4):
    a = k * math.pi / 2 + 0.4
    blades.box((0.34, 0.66, 0.03), cf(-math.sin(a) * 0.38, C + math.cos(a) * 0.38, -0.1, rz=a, ry=deg(18)), bevel=0.012)
blades.cyl(0.12, 0.12, cf(0, C, -0.12, ry=deg(90)), segments=12, bevel=0.03)
body = kit.Mesh("Body", "painted_metal", (60, 62, 58))
body.lathe((0, C, 0.0), (0, C, 0.36), [(0.0, 0.2), (0.3, 0.25), (0.8, 0.22), (1.0, 0.12)], segments=14)  # motor
body.box((0.14, 0.75, 0.14), cf(0, 0.5, 0.2), bevel=0.04)  # neck
body.box((1.0, 0.14, 0.72), cf(0, 0.07, 0.12), bevel=0.06, segments=2)  # base
kit.finish([guard, blades, body], "item_fan")
