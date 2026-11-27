"""The safehouse supplies counter (12 long x 3.5 tall x 4 deep studs): a
worn timber counter, slatted front (-Z, the customer side), a worktop with
an overhang, a lift-up flap at one end, a brass bell and a cash tray, and
the housing for the SUPPLIES screen standing on it (the screen itself
stays the game's glowing part). Origin on the floor under its middle;
the game turns it so the front faces into the room."""
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent / "lib"))

import kit  # noqa: E402
from kit import cf, deg  # noqa: E402

L, H, D = 12.0, 3.5, 4.0
body = kit.Mesh("Body", "wood", (70, 56, 40))
body.box((L - 0.3, H - 0.4, D - 0.5), cf(0, (H - 0.4) / 2 + 0.2, 0.1), bevel=0.04)
body.box((L - 0.6, 0.2, D - 0.9), cf(0, 0.1, 0.25), bevel=0.02)  # plinth, set back
for k in range(23):  # slatted front
    body.box((0.44, H - 0.7, 0.08), cf(-L / 2 + 0.5 + k * 0.48, 0.3 + (H - 0.7) / 2, -D / 2 + 0.2), bevel=0.02)
for s in (-1, 1):
    body.box((0.3, H - 0.45, D - 0.3), cf(s * (L / 2 - 0.15), (H - 0.45) / 2 + 0.05, 0.05), bevel=0.04)  # end panels
top = kit.Mesh("Top", "wood", (96, 74, 50))
top.box((L - 2.0, 0.22, D), cf(-1.0, H - 0.11, 0), bevel=0.06, segments=2)
top.box((1.9, 0.22, D), cf(L / 2 - 1.0, H - 0.11 + 0.01, 0, rz=deg(-1.5)), bevel=0.06, segments=2)  # the flap, not quite down
hinge = kit.Mesh("Fittings", "brushed_metal", (176, 150, 80))
for z in (-1.2, 1.2):
    hinge.box((0.3, 0.06, 0.3), cf(L / 2 - 2.0, H + 0.02, z), bevel=0.01)
hinge.cyl(0.12, 0.28, cf(-3.8, H + 0.06, -0.9, rz=deg(90)), segments=12, bevel=0.02)  # bell base
hinge.ball(0.22, cf(-3.8, H + 0.18, -0.9), segments=10, scale=(1, 0.8, 1))  # bell dome
hinge.cyl(0.1, 0.04, cf(-3.8, H + 0.38, -0.9, rz=deg(90)), segments=6, bevel=0.0)  # plunger
tray = kit.Mesh("Tray", "painted_metal", (60, 62, 60))
tray.box((1.2, 0.12, 0.9), cf(2.6, H + 0.06, -0.7), bevel=0.04)
# Housing and stand for the SUPPLIES screen (4 wide x 2.4 tall, centred
# 1.3 above the top; the screen's 0.3 thick slab faces -Z).
housing = kit.Mesh("ScreenHousing", "worn_plastic", (40, 40, 38))
for s in (-1, 1):
    housing.box((0.16, 2.7, 0.5), cf(s * 2.08, H + 1.3, 0.08), bevel=0.04)
    housing.box((4.32, 0.16, 0.5), cf(0, H + 1.3 + s * 1.27, 0.08), bevel=0.04)
housing.box((4.0, 2.4, 0.2), cf(0, H + 1.3, 0.27), bevel=0.04)  # back
housing.box((0.5, 0.25, 0.3), cf(0, H + 0.0 + 0.125 - 0.02, 0.3), bevel=0.04)  # neck
housing.box((1.4, 0.06, 0.9), cf(0, H + 0.03, 0.3), bevel=0.02)  # foot
kit.finish([body, top, hinge, tray, housing], "shop_counter", budget=2400)
