"""Packing carton (2.2 wide x 1.5 tall x 1.9 deep studs) for the storage
racks: taped flaps on top, a stencilled code on the end."""
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent / "lib"))

import kit  # noqa: E402
from kit import cf, deg  # noqa: E402

W, H, D = 2.2, 1.5, 1.9
box = kit.Mesh("Box", "cardboard", (168, 130, 84))
box.box((W, H - 0.02, D), cf(0, (H - 0.02) / 2, 0), bevel=0.035)
# Top flaps meeting in the middle, one lifting a little.
box.box((W - 0.04, 0.03, D / 2 - 0.02), cf(0, H - 0.005, -D / 4, rx=deg(-1.5)), bevel=0.01)
box.box((W - 0.04, 0.03, D / 2 - 0.02), cf(0, H - 0.005, D / 4, rx=deg(3)), bevel=0.01)
tape = kit.Mesh("Tape", "worn_plastic", (190, 170, 120))
tape.box((0.36, 0.012, D + 0.02), cf(0, H + 0.012, 0), bevel=0.0)
for z in (-1, 1):
    tape.box((0.36, 0.5, 0.012), cf(0, H - 0.24, z * (D / 2 + 0.006)), bevel=0.0)
marks = kit.Mesh("Marks", "paper", (60, 52, 44))
marks.box((0.9, 0.22, 0.01), cf(0.4, 0.75, -D / 2 - 0.006), bevel=0.0)  # stencilled code
marks.box((0.4, 0.4, 0.01), cf(-0.6, 0.6, -D / 2 - 0.006), bevel=0.0)  # this-way-up arrows block
kit.finish([box, tape, marks], "carton")
