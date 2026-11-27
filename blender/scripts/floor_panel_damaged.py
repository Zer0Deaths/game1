"""Floor for one maze cell (20 x 20 studs) where the tiles have given up:
one tile gone, showing the grey screed and old adhesive under it, and one
with a corner curled up off the floor. Otherwise the same as floor_panel
(origin at the underside, sunk 0.12 by the game; the floor material and
colour come from the level). Turned at random so the damage moves about."""
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent / "lib"))

import kit  # noqa: E402
from kit import cf, deg  # noqa: E402
from shapes import slab  # noqa: E402

T = 0.12
GONE = (2, 1)  # tile index (i, j) that's missing
CURLED = (0, 3)  # tile with a corner lifting

carpet = kit.Mesh("Carpet", "carpet", (128, 110, 62))
for i in range(4):
    for j in range(4):
        if (i, j) in (GONE, CURLED):
            continue
        x, z = -7.5 + i * 5, -7.5 + j * 5
        # Tiles round the hole show their cut edges.
        near = abs(i - GONE[0]) + abs(j - GONE[1]) == 1 or abs(i - CURLED[0]) + abs(j - CURLED[1]) == 1
        slab(carpet, (5.0, T, 5.0), cf(x, T / 2, z), bevel=0.06, bevel_faces=("top",),
             drop=("bottom",) if near else ("bottom", "left", "right", "front", "back"))

# The curled tile: lying flat at the back edge, its front corner lifting
# about a third of a stud, a little skewed where it came unstuck.
cx, cz = -7.5 + CURLED[0] * 5, -7.5 + CURLED[1] * 5
carpet.sheet(4.94, 4.94, cf(cx + 0.04, T - 0.004, cz - 0.03, rx=deg(90), ry=deg(2.5)),
             curl=0.3, wave=0.01, nx=8, ny=8, thickness=T * 0.9, seed=3)

# Under the missing tile: screed, a crack, dried glue.
gx, gz = -7.5 + GONE[0] * 5, -7.5 + GONE[1] * 5
screed = kit.Mesh("Screed", "concrete", (118, 114, 106))
screed.box((5.0, 0.04, 5.0), cf(gx, 0.02, gz), bevel=0.0)
screed.box((5.0, 0.04, 5.0), cf(cx, 0.02, cz), bevel=0.0)  # under the curled one too
glue = kit.Mesh("Adhesive", "worn_plastic", (92, 80, 52))
for k, (dx, dz, w, d) in enumerate(((-1.2, -0.9, 1.6, 0.7), (0.9, 0.6, 1.9, 0.5), (-0.4, 1.5, 1.1, 0.6), (1.4, -1.6, 0.9, 0.9))):
    glue.box((w, 0.02, d), cf(gx + dx, 0.05, gz + dz, ry=deg(k * 23)), bevel=0.008)
kit.finish([carpet, screed, glue], "floor_panel_damaged")
