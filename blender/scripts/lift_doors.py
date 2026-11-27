"""Descent lift double doors: a steel frame for an 8 x 8.5 stud opening that
fits between the lift cage posts (10 apart), two sliding leaves with
wired-glass windows, and a floor indicator on the header."""
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent / "lib"))

import kit  # noqa: E402
from kit import cf, deg  # noqa: E402

W, H = 8.0, 8.5
STEEL = (108, 108, 104)
LEAF = (130, 128, 120)
AMBER_DIM = (150, 112, 52)

frame = kit.Mesh("Lift_Frame", "painted_metal", STEEL)
for s in (-1, 1):
    frame.box((0.6, H + 0.6, 0.7), cf(s * (W / 2 + 0.3), (H + 0.6) / 2, 0), bevel=0.06)
frame.box((W + 1.2, 0.6, 0.7), cf(0, H + 0.3, 0), bevel=0.06)
frame.box((W + 1.2, 0.1, 0.9), cf(0, 0.05, 0), bevel=0.03)  # sill
frame.box((1.6, 0.6, 0.25), cf(0, H + 1.2, -0.25), bevel=0.06)  # indicator box
frame.cyl(0.6, 0.07, cf(0, H + 0.85, -0.2, rx=deg(90)), segments=8)  # its bracket

glass = kit.Mesh("Lift_Glass", "glass", (150, 160, 150), transparency=0.45, shadow=False)
leaves = []
for side, name in ((-1, "Lift_LeafL"), (1, "Lift_LeafR")):
    leaf = kit.Mesh(name, "brushed_metal", LEAF)
    lw = W / 2 - 0.02
    cx = side * (lw / 2 + 0.01)
    leaf.panel((lw, H - 0.05, 0.16), cf(cx, H / 2, -0.15), inset=0.3, depth=0.03, faces=("front",))
    for k in range(3):  # pressed stiffening ribs
        leaf.box((lw - 0.8, 0.12, 0.05), cf(cx, 1.2 + k * 0.6, -0.25), bevel=0.02)
    glass.box((0.9, 1.6, 0.04), cf(cx, 5.8, -0.24), bevel=0.01)
    leaves.append(leaf)
lamp = kit.Mesh("Lift_Indicator", "neon", AMBER_DIM, shadow=False)
lamp.box((1.2, 0.3, 0.04), cf(0, H + 1.2, -0.39), bevel=0.01)
kit.finish([frame, *leaves, glass, lamp], "lift_doors")
