"""Old hospital wheelchair: sling seat at 2.0, back at +Z, two big rear
wheels (2.6 across) with hand rims, front castors and footrests at -Z,
armrests and push handles. Origin on the floor under the seat."""
import math
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent / "lib"))

import kit  # noqa: E402
from kit import cf, deg  # noqa: E402
from shapes import tube  # noqa: E402

frame = kit.Mesh("Frame", "brushed_metal", (170, 172, 170))
for s in (-1, 1):
    x = s * 0.95
    tube(frame, [(x, 0.45, -1.0), (x, 1.9, -0.85), (x, 1.9, 0.85), (x, 3.9, 1.05), (x, 3.95, 1.45)], 0.06, segments=6)  # side frame + back post + handle
    tube(frame, [(x, 1.9, -0.85), (x * 0.95, 0.75, -1.55), (x * 0.6, 0.55, -1.75)], 0.05, segments=6)  # footrest hanger
    tube(frame, [(x, 1.9, -0.4), (x, 2.75, -0.4), (x, 2.75, 0.7), (x, 1.9, 0.7)], 0.045, segments=6)  # armrest
    frame.cyl(0.32, 0.06, cf(s * 1.1, 1.3, 0.3), segments=8, bevel=0.0)  # axle
    frame.torus(1.12, 0.03, cf(s * 1.3, 1.3, 0.3), segments=18, sides=4)  # hand rim
    for k in range(6):  # spokes
        a = math.pi * k / 6
        frame.cyl(2.2, 0.012, cf(s * 1.15, 1.3, 0.3, rx=a, rz=0) @ cf(0, 0, 0, rz=deg(90)), segments=4, bevel=0.0)
    frame.box((0.12, 0.2, 0.2), cf(x * 0.8, 0.42, -1.0), bevel=0.03)  # castor fork
frame.cyl(1.9, 0.04, cf(0, 1.75, 0.6), segments=6, bevel=0.0)  # cross brace
upholstery = kit.Mesh("Upholstery", "fabric", (40, 42, 44))
upholstery.box((1.9, 0.12, 1.75), cf(0, 1.98, -0.05), bevel=0.05)
upholstery.box((1.9, 1.7, 0.1), cf(0, 2.95, 0.92, rx=deg(-10)), bevel=0.05)
for s in (-1, 1):
    upholstery.box((0.2, 0.12, 1.0), cf(s * 0.95, 2.8, 0.15), bevel=0.04)  # arm pads
    upholstery.box((0.14, 0.14, 0.42), cf(s * 0.95, 3.97, 1.48), bevel=0.05)  # handle grips
tyres = kit.Mesh("Tyres", "rubber", (30, 30, 32))
for s in (-1, 1):
    tyres.torus(1.22, 0.08, cf(s * 1.15, 1.3, 0.3), segments=20, sides=5)
    tyres.cyl(0.14, 0.2, cf(s * 0.76, 0.2, -1.05), segments=10, bevel=0.02)  # castors
for s in (-1, 1):
    tyres.box((0.55, 0.05, 0.42), cf(s * 0.35, 0.55, -1.85, rx=deg(8)), bevel=0.02)  # footplates
kit.finish([frame, upholstery, tyres], "wheelchair")
