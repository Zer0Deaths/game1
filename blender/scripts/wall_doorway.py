"""Wall panel for one maze cell (20 x 11 x 1 studs) with a doorway through
it: a 9 x 8.5 stud opening (Config.DOOR_WIDTH, DOOR_HEIGHT) in the middle,
skirting on both faces running up to the opening. The door model's frame
(door.py, Door_Frame) dresses the opening's edges.
Origin at floor level in the middle of the opening; X along the wall."""
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent / "lib"))

import kit  # noqa: E402
from kit import cf  # noqa: E402

S, H, T = 20.0, 11.0, 1.0
DW, DH = 9.0, 8.5
STUB = (S - DW) / 2

wall = kit.Mesh("Wall", "wallpaper", (201, 181, 104))
for s in (-1, 1):
    wall.box((STUB, H, T), cf(s * (DW / 2 + STUB / 2), H / 2, 0), bevel=0.06)
wall.box((DW + 0.2, H - DH, T), cf(0, (H + DH) / 2, 0), bevel=0.06)  # header, tucked into the stubs

skirt = kit.Mesh("Skirting", "wood", (112, 94, 54))
for s in (-1, 1):
    x = s * (DW / 2 + STUB / 2)
    for z in (-0.54, 0.54):
        skirt.box((STUB, 0.62, 0.08), cf(x, 0.31, z), bevel=0.03)
        skirt.box((STUB, 0.1, 0.12), cf(x, 0.66, z * 1.02), bevel=0.04)
kit.finish([wall, skirt], "wall_doorway")
