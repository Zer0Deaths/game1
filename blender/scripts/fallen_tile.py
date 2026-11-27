"""A ceiling tile that's come down (about 5 x 5 studs): cracked in two,
a corner snapped off, crumbs of mineral fibre round it. Lies on the floor;
origin under its middle."""
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent / "lib"))

import kit  # noqa: E402
from kit import cf, deg  # noqa: E402

tile = kit.Mesh("Tile", "ceiling", (198, 190, 166))
t = 0.16
# The bigger half lies flat; the other half has landed on it, tilted.
tile.box((4.8, t, 2.7), cf(0, t / 2, -1.05, ry=deg(3)), bevel=0.03)
tile.box((3.6, t, 2.1), cf(0.5, 0.36, 1.25, rx=deg(-9), rz=deg(5)), bevel=0.03)
tile.box((1.1, t, 1.2), cf(-1.9, t / 2, 1.6, ry=deg(28)), bevel=0.03)  # snapped-off corner
for k, (x, z, s) in enumerate(((2.6, 0.4, 0.35), (-2.7, -0.6, 0.28), (1.4, -2.7, 0.3), (-0.8, 2.9, 0.22), (2.9, 2.2, 0.2))):
    tile.box((s, 0.12, s * 0.8), cf(x, 0.06, z, ry=deg(k * 37)), bevel=0.02)
kit.finish([tile], "fallen_tile")
