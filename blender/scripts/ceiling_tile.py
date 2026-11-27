"""Suspended-ceiling panel for one maze cell (20 x 20 studs): sixteen 5-stud
tiles sitting in a T-bar grid, the same layout LevelBuilder draws.
Origin at the bottom of the grid; the game hangs it just under the slab."""
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent / "lib"))

import kit  # noqa: E402
from kit import cf, deg  # noqa: E402

tiles = kit.Mesh("Tiles", "ceiling", (206, 201, 178))
for i in range(4):
    for j in range(4):
        tiles.box((4.82, 0.22, 4.82), cf(-7.5 + i * 5, 0.17, -7.5 + j * 5), bevel=0.06)
grid = kit.Mesh("Grid", "painted_metal", (150, 146, 128))
for k in range(5):
    p = -10 + k * 5
    grid.box((20, 0.08, 0.26), cf(0, 0.04, p), bevel=0.02)  # T-bar flange
    grid.box((0.26, 0.08, 20), cf(p, 0.04, 0), bevel=0.02)
kit.finish([tiles, grid], "ceiling_tile")
