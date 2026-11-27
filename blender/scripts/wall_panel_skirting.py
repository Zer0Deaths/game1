"""Wall panel with a skirting board on both faces (20 x 11 x 1 studs)."""
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent / "lib"))

import kit  # noqa: E402
from kit import cf, deg  # noqa: E402

WALLPAPER = (201, 181, 104)
SKIRTING = (112, 94, 54)

wall = kit.Mesh("Wall", "wallpaper", WALLPAPER)
wall.box((20, 11, 1), cf(0, 5.5, 0), bevel=0.06)
skirt = kit.Mesh("Skirting", "wood", SKIRTING)
for z in (-0.54, 0.54):
    skirt.box((20, 0.62, 0.08), cf(0, 0.31, z), bevel=0.03)  # board
    skirt.box((20, 0.1, 0.12), cf(0, 0.66, z * 1.02), bevel=0.04)  # rounded top moulding
kit.finish([wall, skirt], "wall_panel_skirting")
