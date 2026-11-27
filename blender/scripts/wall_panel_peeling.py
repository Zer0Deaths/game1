"""Wall panel with skirting and wallpaper peeling off its front (-Z) face.

The game turns it 180 degrees at random so either side of a corridor peels.
"""
import math
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent / "lib"))

import kit  # noqa: E402
from kit import cf, deg  # noqa: E402

WALLPAPER = (201, 181, 104)
SKIRTING = (112, 94, 54)
PLASTER = (186, 178, 158)
UNDERSIDE = (168, 150, 98)  # back of the paper, a shade darker

wall = kit.Mesh("Wall", "wallpaper", WALLPAPER)
wall.box((20, 11, 1), cf(0, 5.5, 0), bevel=0.06)
skirt = kit.Mesh("Skirting", "wood", SKIRTING)
for z in (-0.54, 0.54):
    skirt.box((20, 0.62, 0.08), cf(0, 0.31, z), bevel=0.03)
    skirt.box((20, 0.1, 0.12), cf(0, 0.66, z * 1.02), bevel=0.04)

# Bare plaster where the paper has come away.
plaster = kit.Mesh("Plaster", "plaster", PLASTER)
for x, y, w, h in ((-5.5, 8.6, 3.2, 3.4), (3.8, 9.3, 2.4, 2.4), (7.6, 2.4, 1.8, 2.2)):
    plaster.box((w, h, 0.03), cf(x, y, -0.515), bevel=0.01)

# Curling strips: the paper hangs off the top of each patch and rolls
# outward, a little more each segment.
peel = kit.Mesh("Peel", "wallpaper", UNDERSIDE)
for x, top, w, length, curl in ((-6.3, 10.3, 1.1, 3.4, 70), (-4.9, 10.2, 0.9, 2.6, 95), (3.6, 10.5, 1.0, 2.2, 120)):
    y, z, a = top, -0.53, 0.0
    step = length / 7
    for i in range(7):
        a += math.radians(curl) / 7
        cy, cz = y - math.cos(a) * step / 2, z - math.sin(a) * step / 2
        peel.box((w * (1 - i * 0.05), step + 0.02, 0.025), cf(x, cy, cz, rx=a), bevel=0.008)
        y, z = y - math.cos(a) * step, z - math.sin(a) * step
kit.finish([wall, skirt, plaster, peel], "wall_panel_peeling")
