"""Office chair, the one LevelBuilder places (seat 1.7 studs square at 1.6
high, back behind it at +Z): padded seat and back, gas post, five-star base."""
import math
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent / "lib"))

import kit  # noqa: E402
from kit import cf, deg  # noqa: E402

FABRIC = (70, 82, 96)
pad = kit.Mesh("Upholstery", "fabric", FABRIC)
pad.box((1.7, 0.3, 1.7), cf(0, 1.6, 0), bevel=0.1, segments=2)
pad.box((1.7, 1.9, 0.25), cf(0, 2.7, 0.8, rx=deg(-8)), bevel=0.1, segments=2)
frame = kit.Mesh("Base", "brushed_metal", (52, 52, 54))
frame.cyl(1.4, 0.11, cf(0, 0.8, 0, rz=deg(90)), segments=12)  # gas post
frame.box((0.14, 1.1, 0.1), cf(0, 1.95, 0.98, rx=deg(-8)), bevel=0.04)  # back support, behind the backrest
for k in range(5):
    a = k * 2 * math.pi / 5
    frame.box((0.14, 0.1, 0.85), cf(math.sin(a) * 0.42, 0.18, math.cos(a) * 0.42, ry=a), bevel=0.035)
casters = kit.Mesh("Casters", "rubber", (34, 34, 36))
for k in range(5):
    a = k * 2 * math.pi / 5
    casters.cyl(0.1, 0.09, cf(math.sin(a) * 0.82, 0.09, math.cos(a) * 0.82, ry=a + math.pi / 2), segments=10, bevel=0.02)
kit.finish([pad, frame, casters], "chair")
