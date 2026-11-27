"""Large wooden crate (3 x 2.6 x 3 studs), planked, framed and braced.

Safehouse dressing only: Jason's rule is no loot-sized boxes on level floors."""
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent / "lib"))

import kit  # noqa: E402
from kit import cf, deg  # noqa: E402

W, H, D = 3.0, 2.6, 3.0
WOOD = (120, 100, 64)
TRIM = (96, 78, 50)
boards = kit.Mesh("Boards", "wood", WOOD)
# Planked sides with hairline gaps between the planks.
planks = 4
for k in range(planks):
    ph = H / planks
    y = ph * (k + 0.5)
    boards.box((W - 0.24, ph - 0.05, D - 0.24), cf(0, y, 0), bevel=0.03)
boards.box((W - 0.16, 0.12, D - 0.16), cf(0, H - 0.06, 0), bevel=0.03)  # lid
frame = kit.Mesh("Frame", "wood", TRIM)
for x in (-1, 1):
    for z in (-1, 1):
        frame.box((0.24, H, 0.24), cf(x * (W / 2 - 0.12), H / 2, z * (D / 2 - 0.12)), bevel=0.04)  # corner posts
for y in (0.12, H - 0.12):
    for z in (-1, 1):
        frame.box((W, 0.24, 0.14), cf(0, y, z * (D / 2 - 0.07)), bevel=0.04)  # rails front/back
    for x in (-1, 1):
        frame.box((0.14, 0.24, D), cf(x * (W / 2 - 0.07), y, 0), bevel=0.04)  # rails sides
import math
diag = math.atan2(H - 0.4, W - 0.4)
for z in (-1, 1):
    frame.box((math.hypot(W - 0.4, H - 0.4), 0.2, 0.1), cf(0, H / 2, z * (D / 2 - 0.02), rz=diag), bevel=0.03)  # cross brace
kit.finish([boards, frame], "crate_large")
