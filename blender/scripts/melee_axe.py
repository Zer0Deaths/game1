"""Fire axe from the lift armoury (ShopItems melee_axe): a long hickory
handle, a red pick-head with a bright ground edge facing -Z and a spike
behind. Origin at the bottom of the handle, handle up +Y."""
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent / "lib"))

import kit  # noqa: E402
from kit import cf, deg  # noqa: E402

handle = kit.Mesh("Handle", "wood", (150, 112, 70))
handle.box((0.2, 3.1, 0.14), cf(0, 1.55, 0), bevel=0.05, segments=2)
handle.box((0.24, 0.22, 0.18), cf(0, 0.11, 0), bevel=0.05, segments=2)  # swell at the end
head = kit.Mesh("Head", "painted_metal", (150, 32, 26))
head.box((0.2, 0.46, 0.62), cf(0, 2.8, -0.15), bevel=0.03)  # eye and cheeks
head.box((0.14, 0.7, 0.3), cf(0, 2.8, -0.5), bevel=0.03)  # widening toward the bit
head.box((0.1, 0.16, 0.46), cf(0, 2.82, 0.4, rx=deg(4)), bevel=0.02)  # spike
head.box((0.06, 0.08, 0.12), cf(0, 2.82, 0.66), bevel=0.0)  # spike tip
edge = kit.Mesh("Edge", "brushed_metal", (170, 170, 164))
edge.box((0.08, 0.84, 0.12), cf(0, 2.8, -0.7), bevel=0.02)
kit.finish([handle, head, edge], "melee_axe", budget=1000)
