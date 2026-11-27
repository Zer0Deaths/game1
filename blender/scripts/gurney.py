"""Hospital trolley (2.6 wide x 6.4 long studs, deck at 2.3, mattress top
2.8), as The Ward parks them: chrome tube frame on four legs with swivel
castors, a vinyl mattress, a rumpled sheet half pulled off one side, side
rails at the head (-Z) end, a push bar at the foot. Origin on the floor
under its middle."""
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent / "lib"))

import kit  # noqa: E402
from kit import cf, deg  # noqa: E402

CHROME = (170, 172, 170)
frame = kit.Mesh("Frame", "brushed_metal", CHROME)
# Deck perimeter tubes and the deck itself.
for s in (-1, 1):
    frame.cyl(6.3, 0.08, cf(s * 1.22, 2.3, 0, ry=deg(90)), segments=8, bevel=0.0)
    frame.cyl(2.44, 0.08, cf(0, 2.3, s * 3.15), segments=8, bevel=0.0)
frame.box((2.3, 0.08, 6.1), cf(0, 2.26, 0), bevel=0.02)
# Legs with a cross bar low down and a basket shelf.
for sx in (-1, 1):
    for sz in (-1, 1):
        frame.cyl(1.95, 0.075, cf(sx * 1.1, 1.22, sz * 2.9, rz=deg(90)), segments=8, bevel=0.0)
        frame.box((0.22, 0.14, 0.28), cf(sx * 1.1, 0.42, sz * 2.9), bevel=0.03)  # castor fork
    frame.cyl(5.8, 0.06, cf(sx * 1.1, 0.75, 0, ry=deg(90)), segments=8, bevel=0.0)
frame.box((2.1, 0.05, 4.8), cf(0, 0.78, 0), bevel=0.015)  # lower shelf
# Side rails at the head end (two bars on posts), push bar at the foot.
for s in (-1, 1):
    for y in (2.75, 3.05):
        frame.cyl(3.6, 0.045, cf(s * 1.3, y, -1.0, ry=deg(90)), segments=6, bevel=0.0)
    for z in (-2.7, 0.7):
        frame.cyl(0.8, 0.04, cf(s * 1.3, 2.68, z, rz=deg(90)), segments=6, bevel=0.0)
frame.cyl(2.3, 0.06, cf(0, 3.3, 3.32), segments=8, bevel=0.0)
for s in (-1, 1):
    frame.cyl(1.05, 0.05, cf(s * 1.15, 2.8, 3.25, rz=deg(90)), segments=6, bevel=0.0)
castors = kit.Mesh("Castors", "rubber", (34, 34, 36))
for sx in (-1, 1):
    for sz in (-1, 1):
        castors.cyl(0.12, 0.2, cf(sx * 1.1, 0.2, sz * 2.9 + 0.08), segments=10, bevel=0.02)
mattress = kit.Mesh("Mattress", "rubber", (110, 140, 130))
mattress.box((2.4, 0.42, 6.1), cf(0, 2.55, 0), bevel=0.12, segments=2)
pillow = kit.Mesh("Pillow", "fabric", (200, 206, 200))
pillow.box((1.7, 0.28, 0.95), cf(0.1, 2.86, -2.45, ry=deg(6), rz=deg(3)), bevel=0.12, segments=2)
sheet = kit.Mesh("Sheet", "fabric", (196, 204, 198))
# Across the mattress, rucked up, and sliding off the +X side to the floor.
sheet.sheet(2.5, 4.2, cf(0.0, 2.8, 0.8, rx=deg(90), rz=deg(3)), curl=0.0, wave=0.12, nx=6, ny=7, thickness=0.03, seed=5)
sheet.sheet(3.6, 1.9, cf(1.33, 1.86, 0.9, ry=deg(90), rz=deg(-4)), curl=0.0, wave=0.1, nx=6, ny=5, thickness=0.03, seed=6)
kit.finish([frame, castors, mattress, pillow, sheet], "gurney")
