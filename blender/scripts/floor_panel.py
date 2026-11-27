"""Carpet-tile floor panel for one maze cell (20 x 20 studs): sixteen worn
5-stud carpet tiles with hairline gaps. Origin at the underside."""
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent / "lib"))

import kit  # noqa: E402
from kit import cf, deg  # noqa: E402

carpet = kit.Mesh("Carpet", "carpet", (128, 110, 62))
for i in range(4):
    for j in range(4):
        carpet.box((4.96, 0.12, 4.96), cf(-7.5 + i * 5, 0.06, -7.5 + j * 5), bevel=0.03)
kit.finish([carpet], "floor_panel")
