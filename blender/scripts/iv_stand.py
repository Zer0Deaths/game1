"""IV drip stand (6.2 studs to the hooks): five-legged castor base, chrome
pole with a height collar, a two-horned hook at the top with a half-empty
fluid bag and its line hanging down. Origin on the floor under the pole."""
import math
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent / "lib"))

import kit  # noqa: E402
from kit import cf, deg  # noqa: E402
from shapes import tube  # noqa: E402

pole = kit.Mesh("Pole", "brushed_metal", (170, 172, 170))
pole.cyl(3.6, 0.07, cf(0, 2.1, 0, rz=deg(90)), segments=8, bevel=0.0)
pole.cyl(2.5, 0.05, cf(0, 5.1, 0, rz=deg(90)), segments=8, bevel=0.0)  # inner tube
pole.cyl(0.25, 0.1, cf(0, 3.95, 0, rz=deg(90)), segments=8, bevel=0.0)  # collar
pole.box((0.08, 0.2, 0.06), cf(0.12, 3.95, 0), bevel=0.02)  # its thumb screw
pole.cyl(0.25, 0.14, cf(0, 0.3, 0, rz=deg(90)), segments=10, bevel=0.0)  # hub
for k in range(5):
    a = 2 * math.pi * k / 5
    x, z = math.cos(a) * 0.42, math.sin(a) * 0.42
    pole.box((0.85, 0.07, 0.12), cf(x, 0.24, z, ry=-a, rz=deg(-8)), bevel=0.02)
# Ram's-horn hooks.
for s in (-1, 1):
    tube(pole, [(0, 6.3, 0), (s * 0.3, 6.25, 0), (s * 0.48, 6.05, 0), (s * 0.5, 6.18, 0)], 0.03, segments=6)
castors = kit.Mesh("Castors", "rubber", (34, 34, 36))
for k in range(5):
    a = 2 * math.pi * k / 5
    castors.cyl(0.08, 0.11, cf(math.cos(a) * 0.82, 0.11, math.sin(a) * 0.82, ry=-a + math.pi / 2), segments=8, bevel=0.01)
bag = kit.Mesh("Bag", "glass", (210, 214, 200), transparency=0.35, shadow=False)
bag.box((0.55, 0.85, 0.12), cf(0.46, 5.55, 0), bevel=0.06, segments=2)
bag.box((0.5, 0.4, 0.16), cf(0.46, 5.3, 0), bevel=0.07, segments=2)  # the fluid settled at the bottom
bag.cyl(0.18, 0.04, cf(0.46, 5.04, 0, rz=deg(90)), segments=6, bevel=0.0)  # drip chamber
tube(bag, [(0.46, 4.95, 0), (0.42, 4.2, 0.05), (0.3, 3.2, 0.15), (0.2, 2.6, 0.12), (0.05, 2.3, 0.0), (-0.12, 2.7, -0.05)], 0.018, segments=5)
kit.finish([pole, castors, bag], "iv_stand")
