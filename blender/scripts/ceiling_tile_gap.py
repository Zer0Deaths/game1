"""Suspended ceiling for one maze cell with a tile come down: the corner
tile's gone from the grid, hanging off its edge into the room, and you can
see up into the black void above, where an old cable sags out of the hole.
Same frame as ceiling_tile (origin at the bottom of the grid). Modelled
with the hole in the north-west corner; the game turns it to put the hole
in whichever corner the level's damage picked."""
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent / "lib"))
sys.path.append(str(Path(__file__).resolve().parent))

import kit  # noqa: E402
from kit import cf, deg  # noqa: E402
from shapes import slab  # noqa: E402
import ceiling_tile  # noqa: E402

HX, HZ = -7.5, -7.5  # centre of the hole (tile 0, 0)


def extra(tiles):
    # The fallen tile: hinged on the bar nearest the cell centre, swung down
    # about 55 degrees into the room.
    hinge_x = HX + 2.43
    tiles.box((4.86, 0.16, 4.8), cf(hinge_x, 0.04, HZ + 0.02, rz=deg(55)) @ cf(-2.43, -0.08, 0), bevel=0.03)
    # Broken corner bits still sitting on the flange.
    tiles.box((0.9, 0.14, 0.5), cf(HX - 2.1, 0.13, HZ - 1.6, ry=deg(12)), bevel=0.03)
    tiles.box((0.6, 0.14, 0.7), cf(HX - 1.6, 0.13, HZ + 2.05, ry=deg(-20)), bevel=0.03)
    # Inside the void: a black lining box up into the (invisible) slab.
    void = kit.Mesh("Void", "plaster", (10, 10, 9), shadow=False)
    slab(void, (4.9, 1.2, 4.9), cf(HX, 0.2 + 0.6, HZ), bevel=0.0, drop=("bottom",))
    # Flip its faces to point inwards (seen from inside the box).
    import bmesh
    bmesh.ops.reverse_faces(void.bm, faces=void.bm.faces)
    # An old cable looping down out of the hole, and a scrap of insulation.
    cable = kit.Mesh("Cable", "rubber", (40, 38, 36))
    cable.pipe([(HX - 1.8, 0.9, HZ - 1.2), (HX - 1.3, -0.4, HZ - 0.6), (HX - 0.4, -1.3, HZ + 0.1),
                (HX + 0.5, -1.0, HZ + 0.6), (HX + 1.1, 0.0, HZ + 0.9), (HX + 1.5, 0.9, HZ + 1.4)], 0.07, segments=6)
    fluff = kit.Mesh("Insulation", "fabric", (176, 150, 96))
    fluff.ball(0.55, cf(HX + 0.9, 0.35, HZ - 1.4), segments=8, scale=(1.4, 0.5, 1.0))
    return [void, cable, fluff]


ceiling_tile.build(skip=[(0, 0)], name="ceiling_tile_gap", extra=extra)
