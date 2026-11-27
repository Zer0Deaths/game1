"""Crowbar from the lift armoury (ShopItems melee_crowbar): a red hex bar
with a curved claw at the top and a flat chisel at the bottom. Origin at
the bottom end, shaft up +Y, the claw curling toward -Z."""
import math
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent / "lib"))

import kit  # noqa: E402
from kit import cf, deg  # noqa: E402

bar = kit.Mesh("Shaft", "painted_metal", (150, 32, 26))
bar.cyl(2.2, 0.08, cf(0, 1.2, 0, rz=deg(90)), segments=6, bevel=0.01)  # hex bar
# The claw: the bar bends through ~150 degrees toward -Z in short pieces.
R, steps = 0.26, 7
cx, cy = 0.0, 2.3
for i in range(steps):
    a0 = math.radians(i * 150 / steps)
    a1 = math.radians((i + 1) * 150 / steps)
    am = (a0 + a1) / 2
    y = cy + R * math.sin(am)
    z = -R + R * math.cos(am)
    bar.cyl(R * (a1 - a0) + 0.03, 0.08, cf(0, y, z, rx=-am, rz=deg(90)), segments=6, bevel=0.0)
tips = kit.Mesh("Tips", "brushed_metal", (110, 108, 102))
for x in (-0.06, 0.06):  # the forked claw end, flattened
    tips.box((0.08, 0.2, 0.06), cf(x, 2.36, -0.5, rx=deg(-30)), bevel=0.01)
tips.box((0.2, 0.22, 0.06), cf(0, 0.06, -0.03, rx=deg(-20)), bevel=0.01)  # chisel end
kit.finish([bar, tips], "melee_crowbar", budget=1000)
