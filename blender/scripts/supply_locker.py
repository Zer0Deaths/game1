"""The safehouse crew supply locker (4 wide x 7 tall x 2 deep studs): a
heavy green steel cabinet with double doors, a padlocked hasp across them
and a stencilled stripe. The CREW SUPPLIES sign above the hasp stays the
game's own part, so nothing here comes off the doors more than a hair.
Front -Z; the game turns it to face into the room."""
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent / "lib"))

import kit  # noqa: E402
from kit import cf, deg  # noqa: E402

W, H, D = 4.0, 7.0, 2.0
body = kit.Mesh("Body", "painted_metal", (70, 84, 76))
body.box((W, H - 0.25, D - 0.04), cf(0, 0.25 + (H - 0.25) / 2, 0.02), bevel=0.06)
body.box((W - 0.2, 0.25, D - 0.2), cf(0, 0.125, 0.05), bevel=0.03)
doors = kit.Mesh("Doors", "painted_metal", (78, 92, 82))
for s in (-1, 1):
    doors.panel((W / 2 - 0.08, H - 0.7, 0.03), cf(s * (W / 4 - 0.01), 0.25 + (H - 0.45) / 2, -D / 2 + 0.005), inset=0.2, depth=0.012, bevel=0.012)
stripe = kit.Mesh("Stripe", "painted_metal", (180, 150, 50))
stripe.box((W - 0.4, 0.3, 0.01), cf(0, 1.2, -D / 2 - 0.012), bevel=0.0)
fittings = kit.Mesh("Fittings", "brushed_metal", (150, 148, 140))
fittings.box((0.9, 0.16, 0.03), cf(0, 3.6, -D / 2 - 0.02), bevel=0.01)  # hasp
fittings.box((0.26, 0.3, 0.12), cf(0, 3.42, -D / 2 - 0.08), bevel=0.04)  # padlock body
fittings.torus(0.08, 0.02, cf(0, 3.6, -D / 2 - 0.08, ry=deg(90)), segments=10, sides=4)  # shackle
for s in (-1, 1):
    for y in (1.0, 6.0):
        fittings.cyl(0.36, 0.045, cf(s * (W / 2 - 0.03), y, -D / 2 - 0.01, rz=deg(90)), segments=8, bevel=0.0)
kit.finish([body, doors, stripe, fittings], "supply_locker")
