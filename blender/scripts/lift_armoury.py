"""The armoury in the exit lift (ExitLift.luau): a steel cabinet against
the lift's west side, a timber pegboard over it with four sets of hooks
for the weapons on sale, and the housing for the ARMOURY sign (the sign's
lettering stays the game's glowing part). Modelled in the frame the Luau
code builds in: origin on the lift deck under the cabinet's middle, the
front (-Z) facing into the lift. The weapons themselves are their own
models (melee_*.py)."""
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent / "lib"))

import kit  # noqa: E402
from kit import cf, deg  # noqa: E402

W = 6.0
cab = kit.Mesh("Cabinet", "painted_metal", (62, 72, 64))
cab.box((W, 2.9, 1.3), cf(0, 1.55, 0.1), bevel=0.05)  # carcass
cab.box((W - 0.3, 0.12, 1.2), cf(0, 0.06, 0.15), bevel=0.02)  # kick plate, set back
top = kit.Mesh("Worktop", "brushed_metal", (120, 118, 110))
top.box((W + 0.1, 0.12, 1.45), cf(0, 3.04, 0.05), bevel=0.03)
doors = kit.Mesh("Doors", "painted_metal", (74, 86, 76))
for x in (-W / 4, W / 4):
    doors.panel((W / 2 - 0.12, 2.6, 0.06), cf(x, 1.55, -0.58), inset=0.18, depth=0.02)
handles = kit.Mesh("Handles", "brushed_metal", (150, 146, 136))
for x in (-0.25, 0.25):
    handles.box((0.06, 0.6, 0.08), cf(x, 2.1, -0.65), bevel=0.02)
handles.box((0.5, 0.3, 0.06), cf(W / 2 - 0.7, 2.5, -0.64), bevel=0.02)  # cash slot plate
handles.box((0.36, 0.04, 0.03), cf(W / 2 - 0.7, 2.52, -0.68), bevel=0.0)  # the slot
board = kit.Mesh("Board", "wood", (150, 140, 112))
board.box((W, 4.2, 0.2), cf(0, 3 + 2.1, 0.62), bevel=0.03)
frame = kit.Mesh("BoardFrame", "painted_metal", (56, 56, 58))
for s in (-1, 1):
    frame.box((0.16, 4.4, 0.3), cf(s * (W / 2 + 0.02), 5.1, 0.6), bevel=0.02)
    frame.box((W + 0.2, 0.16, 0.3), cf(0, 5.1 + s * 2.15, 0.6), bevel=0.02)
hooks = kit.Mesh("Hooks", "brushed_metal", (140, 138, 130))
for x in (-2.2, -0.75, 0.75, 2.2):
    for y in (4.1, 6.1):  # a pair of pegs for each weapon
        hooks.cyl(0.3, 0.035, cf(x, y, 0.38, ry=deg(90)), segments=6, bevel=0.0)
        hooks.box((0.07, 0.12, 0.05), cf(x, y + 0.04, 0.24), bevel=0.0)
    hooks.box((0.5, 0.18, 0.02), cf(x, 3.5, 0.51), bevel=0.0)  # price tag
sign = kit.Mesh("SignHousing", "painted_metal", (36, 34, 30))
sign.box((4.3, 1.05, 0.14), cf(0, 7.75, 0.62), bevel=0.03)  # back plate (the lit sign sits in front)
for s in (-1, 1):
    sign.box((0.08, 0.5, 0.08), cf(s * 1.8, 8.5, 0.62), bevel=0.0)  # hangers into the header
kit.finish([cab, top, doors, handles, board, frame, hooks, sign], "lift_armoury", budget=2000)
