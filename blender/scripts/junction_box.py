"""Electrical junction box on a Plant wall (1.6 x 2.0 x 0.5 studs at 5 up),
with its conduit running up into the ceiling on saddles, a hinged lid
held by four screws, a yellow warning label and a cable gland with a cut
cable hanging out. Frame: wall face at floor height under its centre, X
along the wall, -Z out of it."""
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent / "lib"))

import kit  # noqa: E402
from kit import cf, deg  # noqa: E402
from shapes import tube  # noqa: E402

H = 11.0
box = kit.Mesh("Box", "painted_metal", (90, 96, 90))
box.box((1.6, 2.0, 0.38), cf(0, 5.0, -0.19), bevel=0.05)
box.panel((1.5, 1.9, 0.1), cf(0, 5.0, -0.43), inset=0.12, depth=0.02, bevel=0.03)  # lid
for s in (-1, 1):
    box.box((0.12, 0.3, 0.1), cf(-0.8, 5.0 + s * 0.6, -0.4), bevel=0.03)  # hinges
conduit = kit.Mesh("Conduit", "brushed_metal", (110, 110, 104))
conduit.cyl(H - 6.0 + 0.1, 0.1, cf(0, (6.0 + H) / 2, -0.2, rz=deg(90)), segments=8, bevel=0.0)
conduit.cyl(0.3, 0.16, cf(0, 6.1, -0.2, rz=deg(90)), segments=8, bevel=0.02)  # coupler
for y in (7.6, 9.6):
    conduit.box((0.4, 0.12, 0.26), cf(0, y, -0.14), bevel=0.02)  # saddles
for sx in (-1, 1):
    for sy in (-1, 1):
        conduit.cyl(0.04, 0.05, cf(sx * 0.6, 5.0 + sy * 0.8, -0.49, ry=deg(90)), segments=6, bevel=0.0)  # screws
conduit.cyl(0.18, 0.12, cf(0.3, 3.92, -0.2, rz=deg(90)), segments=8, bevel=0.02)  # gland
cable = kit.Mesh("Cable", "rubber", (36, 34, 32))
tube(cable, [(0.3, 3.85, -0.2), (0.32, 3.3, -0.28), (0.45, 2.85, -0.5), (0.62, 2.7, -0.62)], 0.06, segments=6)
label = kit.Mesh("Label", "worn_plastic", (210, 170, 40))
label.box((0.5, 0.45, 0.01), cf(0, 5.35, -0.49), bevel=0.0)
mark = kit.Mesh("Mark", "worn_plastic", (30, 28, 24))
mark.box((0.08, 0.24, 0.01), cf(0.02, 5.35, -0.495, rz=deg(-20)), bevel=0.0)  # bolt mark on the label
kit.finish([box, conduit, cable, label, mark], "junction_box")
