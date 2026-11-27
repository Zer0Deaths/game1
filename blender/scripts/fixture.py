"""Fluorescent ceiling fixture with visible tubes: a surface-mounted twin
batten (8 x 0.55 x 2.4 studs), the safehouse layout's size.

"Tubes" is its own mesh so the game can make it glow, flicker and die.
Origin at the bottom centre (the underside of the tubes); the top of the
housing goes against the ceiling.
"""
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent / "lib"))

import kit  # noqa: E402
from kit import cf, deg  # noqa: E402

TOP = 0.0  # build down from the ceiling, kit.finish moves the origin to the bottom

body = kit.Mesh("Housing", "painted_metal", (176, 172, 160))
body.box((8.0, 0.2, 1.7), cf(0, TOP - 0.1), bevel=0.05, segments=2)
for z, a in ((-1.0, 28), (1.0, -28)):
    body.box((7.9, 0.04, 0.55), cf(0, TOP - 0.27, z, rx=deg(a)), bevel=0.012)  # reflector wings
body.box((7.6, 0.03, 1.5), cf(0, TOP - 0.21), bevel=0.01)
caps = kit.Mesh("Caps", "worn_plastic", (150, 146, 136))
for s in (-1, 1):
    caps.box((0.3, 0.38, 2.0), cf(s * 3.85, TOP - 0.42), bevel=0.05, segments=2)
    for dz in (-0.55, 0.55):
        caps.cyl(0.16, 0.17, cf(s * 3.66, TOP - 0.48, dz), segments=12, bevel=0.02)  # lamp holders
tubes = kit.Mesh("Tubes", "neon", (252, 236, 186), shadow=False)
for dz in (-0.55, 0.55):
    tubes.cyl(7.4, 0.13, cf(0, TOP - 0.48, dz), segments=12, bevel=0.03)
kit.finish([body, caps, tubes], "fixture")
