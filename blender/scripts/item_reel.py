"""Loot: Film Reel (1.6 studs across, 0.4 thick, standing on its edge like
the Cylinder part along X): spoked metal flanges round a dark film pack."""
import math
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent / "lib"))

import kit  # noqa: E402
from kit import cf, deg  # noqa: E402

R = 0.8
metal = kit.Mesh("Flanges", "brushed_metal", (120, 120, 126))
for x in (-0.17, 0.17):
    metal.torus(R - 0.06, 0.05, cf(x, R, 0), segments=24, sides=6)  # rims
    metal.cyl(0.04, 0.2, cf(x, R, 0), segments=12, bevel=0.01)  # hub plate
    for k in range(3):
        a = k * 2 * math.pi / 3
        metal.box((0.04, R - 0.2, 0.16), cf(x, R + math.cos(a) * (R / 2), math.sin(a) * (R / 2), rx=-a), bevel=0.015)  # spokes
metal.cyl(0.4, 0.09, cf(0, R, 0), segments=10, bevel=0.02)  # spindle
film = kit.Mesh("Film", "worn_plastic", (48, 38, 30))
film.cyl(0.3, 0.55, cf(0, R, 0), segments=20, bevel=0.02)
kit.finish([metal, film], "item_reel")
