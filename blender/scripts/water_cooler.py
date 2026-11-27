"""Office water cooler (1.4 x 1.4 base, 4.8 studs tall to the top of the
bottle): beige cabinet with a recessed dispensing bay, a blue and a red
tap, a drip tray, and a big half-empty bottle upside down on top.
Front -Z."""
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent / "lib"))

import kit  # noqa: E402
from kit import cf, deg  # noqa: E402

body = kit.Mesh("Body", "worn_plastic", (206, 200, 184))
body.box((1.4, 2.2, 1.4), cf(0, 1.1, 0), bevel=0.08)  # lower cabinet
body.box((1.4, 0.45, 1.4), cf(0, 2.975, 0), bevel=0.08)  # head unit
body.box((1.4, 0.55, 0.9), cf(0, 2.475, 0.25), bevel=0.04)  # back of the dispensing bay
body.cyl(0.25, 0.42, cf(0, 3.3, 0, rz=deg(90)), segments=16, bevel=0.04)  # bottle seat
bay = kit.Mesh("Bay", "worn_plastic", (70, 70, 66))
bay.box((1.2, 0.5, 0.05), cf(0, 2.475, -0.21), bevel=0.02)  # shadowed bay wall
bay.box((1.1, 0.08, 0.5), cf(0, 2.26, -0.45), bevel=0.02)  # drip tray
for k in range(5):
    bay.box((1.0, 0.02, 0.04), cf(0, 2.31, -0.62 + k * 0.08), bevel=0.0)
blue = kit.Mesh("TapCold", "worn_plastic", (60, 90, 170))
blue.box((0.2, 0.25, 0.3), cf(0.3, 2.62, -0.62), bevel=0.05)
red = kit.Mesh("TapHot", "worn_plastic", (170, 50, 40))
red.box((0.2, 0.25, 0.3), cf(-0.3, 2.62, -0.62), bevel=0.05)
bottle = kit.Mesh("Bottle", "glass", (150, 176, 186), transparency=0.45, shadow=False)
prof = [(0.0, 0.12), (0.06, 0.13), (0.12, 0.42), (0.2, 0.56), (0.35, 0.57), (0.42, 0.54), (0.5, 0.57),
        (0.65, 0.57), (0.72, 0.54), (0.8, 0.57), (0.93, 0.55), (1.0, 0.3)]
bottle.lathe((0, 3.3, 0), (0, 4.8, 0), prof, segments=16)
water = kit.Mesh("Water", "glass", (110, 150, 170), transparency=0.25, shadow=False)
water.lathe((0, 3.32, 0), (0, 3.95, 0), [(0.0, 0.1), (0.1, 0.38), (0.3, 0.53), (1.0, 0.53)], segments=14)
kit.finish([body, bay, blue, red, bottle, water], "water_cooler")
