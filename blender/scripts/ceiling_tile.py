"""Suspended ceiling for one maze cell (20 x 20 studs): sixteen 5-stud tiles
resting in a T-bar grid, the same layout the light fittings and the
ceiling damage are placed on. Origin at the bottom of the grid; the game
hangs it so the tile tops touch the ceiling slab (which stays, invisible).

Only what you can see from the floor is built: tile undersides and edges,
the bars' flanges. Each cell owns the bars on its west and north edges;
the next cell's panel brings the east and south ones. The cross bars sit
a hair higher than the main ones so the crossings never flicker."""
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent / "lib"))

import kit  # noqa: E402
from kit import cf  # noqa: E402
from shapes import slab  # noqa: E402

TILE_LOW, TILE_HIGH = 0.04, 0.2  # tile underside and top above the grid bottom


def build(skip=(), name="ceiling_tile", extra=()):
    tiles = kit.Mesh("Tiles", "ceiling", (206, 201, 178))
    for i in range(4):
        for j in range(4):
            if (i, j) in skip:
                continue
            near = any(abs(i - a) + abs(j - b) == 1 for a, b in skip)
            slab(tiles, (4.86, TILE_HIGH - TILE_LOW, 4.86), cf(-7.5 + i * 5, (TILE_LOW + TILE_HIGH) / 2, -7.5 + j * 5),
                 bevel=0.03, bevel_faces=("bottom",), drop=() if near else ("top",))
    grid = kit.Mesh("Grid", "painted_metal", (150, 146, 128))
    for k in range(4):
        p = -10 + k * 5
        slab(grid, (20, 0.08, 0.26), cf(0, 0.04, p), bevel=0.0, drop=("top", "left", "right"))  # main runners
        slab(grid, (0.26, 0.08, 20), cf(p, 0.044, 0), bevel=0.0, drop=("top", "front", "back"))  # cross tees
    return kit.finish([tiles, grid, *extra(tiles)] if extra else [tiles, grid], name)


if __name__ == "__main__":
    build()
