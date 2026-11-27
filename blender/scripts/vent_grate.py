"""Wall vent grate (2.6 x 1.3 studs) with angled louvres and corner screws,
as LevelBuilder puts on walls. Wall at z = 0, front -Z."""
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent / "lib"))

import kit  # noqa: E402
from kit import cf, deg  # noqa: E402

frame = kit.Mesh("VentFrame", "painted_metal", (176, 172, 160))
frame.box((2.6, 0.14, 0.1), cf(0, 0.58, -0.05), bevel=0.03)
frame.box((2.6, 0.14, 0.1), cf(0, -0.58, -0.05), bevel=0.03)
frame.box((0.14, 1.3, 0.1), cf(-1.23, 0, -0.05), bevel=0.03)
frame.box((0.14, 1.3, 0.1), cf(1.23, 0, -0.05), bevel=0.03)
back = kit.Mesh("VentBack", "painted_metal", (34, 33, 30))
back.box((2.36, 1.06, 0.03), cf(0, 0, -0.015), bevel=0.01)  # dark duct behind the slats
louvres = kit.Mesh("Louvres", "painted_metal", (160, 156, 146))
for k in range(7):
    louvres.box((2.34, 0.16, 0.03), cf(0, -0.45 + k * 0.15, -0.07, rx=deg(-40)), bevel=0.01)
for x in (-1.15, 1.15):
    for y in (-0.5, 0.5):
        frame.cyl(0.03, 0.045, cf(x, y, -0.11, ry=deg(90)), segments=8, bevel=0.01)  # screws
kit.finish([frame, back, louvres], "vent_grate")
