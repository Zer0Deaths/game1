"""Steel staff locker (2.4 wide x 6.5 tall x 2 deep studs), door on the front
(-Z) with vent slots, a handle, a number plate and a dent or two of wear."""
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent / "lib"))

import kit  # noqa: E402
from kit import cf, deg  # noqa: E402

BODY = (86, 92, 88)
body = kit.Mesh("Body", "painted_metal", BODY)
body.box((2.4, 6.2, 2.0), cf(0, 0.3 + 3.1, 0), bevel=0.06)
body.box((2.3, 0.3, 1.9), cf(0, 0.15, 0.03), bevel=0.04)  # plinth
door = kit.Mesh("Door", "painted_metal", (96, 98, 90))
door.panel((2.2, 5.9, 0.08), cf(0, 3.45, -1.02), inset=0.22, depth=0.025, faces=("front",), bevel=0.03)
slots = kit.Mesh("Vents", "painted_metal", (30, 30, 28))
for k in range(5):
    slots.box((1.3, 0.07, 0.03), cf(0, 5.6 + k * 0.17, -1.07), bevel=0.012)
    slots.box((1.3, 0.07, 0.03), cf(0, 0.9 + k * 0.17, -1.07), bevel=0.012)
fittings = kit.Mesh("Fittings", "brushed_metal", (170, 168, 160))
fittings.box((0.14, 0.7, 0.1), cf(0.82, 3.5, -1.1), bevel=0.04)  # handle
fittings.box((0.55, 0.3, 0.02), cf(0, 4.9, -1.075), bevel=0.01)  # number plate
for y in (1.0, 5.9):
    fittings.cyl(0.4, 0.05, cf(-1.12, y, -1.04, rz=deg(90)), segments=8, bevel=0.01)  # hinges
kit.finish([body, door, slots, fittings], "locker")
