"""The safehouse wardrobe (6 wide x 8 tall x 3 deep studs): a tall double
steel locker for the crew's overalls, with long vented doors, a locking
handle bar, a stencilled plate and a dent. Front -Z; the game turns it to
face into the room."""
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent / "lib"))

import kit  # noqa: E402
from kit import cf, deg  # noqa: E402

W, H, D = 6.0, 8.0, 3.0
body = kit.Mesh("Body", "painted_metal", (80, 74, 64))
body.box((W, H - 0.3, D), cf(0, 0.3 + (H - 0.3) / 2, 0), bevel=0.06)
body.box((W - 0.2, 0.3, D - 0.2), cf(0, 0.15, 0.05), bevel=0.03)
body.box((W + 0.1, 0.18, D + 0.1), cf(0, H - 0.09, 0), bevel=0.04)  # top cornice
doors = kit.Mesh("Doors", "painted_metal", (92, 86, 74))
for s in (-1, 1):
    doors.panel((W / 2 - 0.12, H - 0.9, 0.08), cf(s * (W / 4 - 0.02), 0.3 + (H - 0.6) / 2, -D / 2 - 0.04), inset=0.25, depth=0.03, bevel=0.03)
vents = kit.Mesh("Vents", "painted_metal", (30, 28, 26))
for s in (-1, 1):
    for k in range(6):
        vents.box((1.4, 0.08, 0.03), cf(s * (W / 4 - 0.02), 6.4 + k * 0.2, -D / 2 - 0.1), bevel=0.012)
        vents.box((1.4, 0.08, 0.03), cf(s * (W / 4 - 0.02), 0.9 + k * 0.2, -D / 2 - 0.1), bevel=0.012)
fittings = kit.Mesh("Fittings", "brushed_metal", (170, 168, 160))
fittings.box((0.14, 1.4, 0.12), cf(0.3, 4.0, -D / 2 - 0.16), bevel=0.04)  # handle bar
fittings.box((0.3, 0.3, 0.06), cf(0.3, 4.9, -D / 2 - 0.12), bevel=0.02)  # lock
fittings.box((1.6, 0.5, 0.02), cf(-1.5, 6.0, -D / 2 - 0.09), bevel=0.01)  # name plate
for s in (-1, 1):
    for y in (1.2, 4.0, 6.8):
        fittings.cyl(0.4, 0.05, cf(s * (W / 2 - 0.04), y, -D / 2 - 0.02, rz=deg(90)), segments=8, bevel=0.0)  # hinges
kit.finish([body, doors, vents, fittings], "wardrobe")
