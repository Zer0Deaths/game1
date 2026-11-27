"""Hospital corridor handrail (17 studs long) on three brackets, the rail
at 3.1 up and 0.45 off the wall. Rounded hardwood rail with its ends
returned into the wall, steel brackets on wall plates.
Frame: on the wall face at floor height, X along the wall, -Z out of it."""
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent / "lib"))

import kit  # noqa: E402
from kit import cf, deg  # noqa: E402

L, Y, Z = 17.0, 3.1, -0.45
rail = kit.Mesh("Rail", "wood", (150, 128, 96))
rail.cyl(L - 0.6, 0.14, cf(0, Y, Z), segments=10, bevel=0.0)
for s in (-1, 1):
    rail.ball(0.14, cf(s * (L / 2 - 0.3), Y, Z), segments=10)  # rounded bend
    rail.cyl(0.42, 0.14, cf(s * (L / 2 - 0.3), Y, Z / 2, ry=deg(90)), segments=10, bevel=0.0)  # return to the wall
brackets = kit.Mesh("Brackets", "brushed_metal", (170, 172, 170))
for x in (-(L - 2) / 2, 0.0, (L - 2) / 2):
    brackets.box((0.16, 0.45, 0.05), cf(x, Y - 0.12, -0.025), bevel=0.015)  # wall plate
    brackets.box((0.08, 0.08, 0.36), cf(x, Y - 0.2, -0.2), bevel=0.02)  # arm
    brackets.box((0.08, 0.14, 0.08), cf(x, Y - 0.14, Z), bevel=0.02)  # saddle
kit.finish([rail, brackets], "handrail")
