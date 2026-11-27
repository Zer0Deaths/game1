"""Double wall socket on a yellowed faceplate (0.55 wide x 0.85 tall,
centred 1.4 up), each socket with its three pin slots and a rocker switch.
Frame: wall face at floor height under it, X along the wall, -Z out."""
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent / "lib"))

import kit  # noqa: E402
from kit import cf  # noqa: E402

plate = kit.Mesh("Plate", "worn_plastic", (226, 220, 200))
plate.box((0.55, 0.85, 0.07), cf(0, 1.4, -0.035), bevel=0.025)
for dy in (0.18, -0.18):
    plate.box((0.3, 0.26, 0.03), cf(-0.04, 1.4 + dy, -0.08), bevel=0.012)  # socket face
    plate.box((0.07, 0.11, 0.04), cf(0.18, 1.4 + dy, -0.08), bevel=0.012)  # switch
holes = kit.Mesh("Holes", "worn_plastic", (34, 32, 30))
for dy in (0.18, -0.18):
    holes.box((0.04, 0.08, 0.01), cf(-0.04, 1.4 + dy + 0.06, -0.096), bevel=0.0)
    for dx in (-0.09, 0.01):
        holes.box((0.07, 0.035, 0.01), cf(dx, 1.4 + dy - 0.05, -0.096), bevel=0.0)
kit.finish([plate, holes], "wall_outlet")
