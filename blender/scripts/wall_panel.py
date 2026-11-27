"""Wall panel, plain: one maze cell long (20 x 11 x 1 studs, 5.6 x 3.08 x 0.28 m).

Snaps on the maze grid: panels run edge to edge along a wall line, with a
wall_post at every grid point covering the joint and corners.
"""
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent / "lib"))

import kit  # noqa: E402
from kit import cf, deg  # noqa: E402

WALLPAPER = (201, 181, 104)

wall = kit.Mesh("Wall", "wallpaper", WALLPAPER)
wall.box((20, 11, 1), cf(0, 5.5, 0), bevel=0.06)
kit.finish([wall], "wall_panel")
