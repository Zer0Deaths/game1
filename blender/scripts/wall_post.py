"""Wall post: the joint piece of the modular wall (1.2 x 11 x 1.2 studs).

Stands on every grid point a wall touches. It is a little wider than a
wall panel (1 stud), so it hides panel ends, corners and T-junctions
without any faces fighting.
"""
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent / "lib"))

import kit  # noqa: E402
from kit import cf, deg  # noqa: E402

WALLPAPER = (201, 181, 104)
SKIRTING = (112, 94, 54)

post = kit.Mesh("Post", "wallpaper", (194, 175, 100))
post.box((1.2, 11, 1.2), cf(0, 5.5, 0), bevel=0.12, segments=2)  # rounded corner bead
skirt = kit.Mesh("Skirting", "wood", SKIRTING)
skirt.box((1.34, 0.62, 1.34), cf(0, 0.31, 0), bevel=0.04)
skirt.box((1.38, 0.1, 1.38), cf(0, 0.66, 0), bevel=0.04)
kit.finish([post, skirt], "wall_post")
