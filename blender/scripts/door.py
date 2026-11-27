"""Doorway with frame and two leaves, sized to the maze's 9 x 8.5 stud
openings in a 1-stud wall (Config.DOOR_WIDTH / DOOR_HEIGHT).

Same build as the test door (painted metal slabs with a sloped recessed
panel, steel kick plate and lever) at double-door size, so loot can be
hauled through. Leaves are separate meshes (Door_LeafL, Door_LeafR) with
their hinges at the jambs, so the game can swing them open.
"""
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent / "lib"))

import kit  # noqa: E402
from kit import cf, deg  # noqa: E402

W, H, T = 9.0, 8.5, 1.0
PAINT = (88, 98, 90)
FRAME = (112, 94, 54)
STEEL = (150, 150, 146)

frame = kit.Mesh("Door_Frame", "painted_metal", FRAME)
for s in (-1, 1):
    frame.box((0.35, H, T + 0.3), cf(s * (W / 2 + 0.175), H / 2, 0), bevel=0.05)  # jambs
    for z in (-1, 1):
        frame.box((0.45, H + 0.45, 0.1), cf(s * (W / 2 + 0.3), (H + 0.45) / 2, z * (T / 2 + 0.18)), bevel=0.03)  # architrave
frame.box((W + 0.7, 0.35, T + 0.3), cf(0, H + 0.175, 0), bevel=0.05)  # head
for z in (-1, 1):
    frame.box((W + 1.05, 0.45, 0.1), cf(0, H + 0.225, z * (T / 2 + 0.18)), bevel=0.03)

leaves = []
hardware = kit.Mesh("Door_Hardware", "brushed_metal", STEEL)
for side, name in ((-1, "Door_LeafL"), (1, "Door_LeafR")):
    leaf = kit.Mesh(name, "painted_metal", PAINT)
    lw = W / 2 - 0.03
    cx = side * (lw / 2 + 0.015)
    leaf.panel((lw, H - 0.04, 0.18), cf(cx, (H - 0.04) / 2 + 0.02, 0), inset=0.45, depth=0.04, faces=("front", "back"))
    leaves.append(leaf)
    # Kick plate and a lever on each face, near the meeting edge.
    for z in (-1, 1):
        hardware.box((lw - 0.4, 0.9, 0.02), cf(cx, 0.55, z * 0.1), bevel=0.008)
        hx = side * 0.45
        hardware.cyl(0.08, 0.1, cf(hx, 3.6, z * 0.13, ry=deg(90)), segments=12, bevel=0.01)  # rose
        hardware.box((0.55, 0.07, 0.07), cf(hx + side * 0.26, 3.6, z * 0.2), bevel=0.025)  # lever
kit.finish([frame, *leaves, hardware], "door")
