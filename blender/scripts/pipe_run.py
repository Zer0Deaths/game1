"""Wall pipe run for one maze cell (20 studs): a main pipe and a smaller
return line on clamps, flanged at both ends so runs join up, with a
rusty band where it has leaked. Built against a wall at z = 0, front -Z,
main pipe centre at y = 0 (the game sets the height)."""
import math
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent / "lib"))

import kit  # noqa: E402
from kit import cf, deg  # noqa: E402

PIPE = (96, 92, 84)
pipe = kit.Mesh("Pipe", "painted_metal", PIPE)
pipe.cyl(20, 0.35, cf(0, 0, -0.6), segments=14)
pipe.cyl(20, 0.2, cf(0, -0.75, -0.42), segments=10)
flange = kit.Mesh("Flanges", "rust", (80, 74, 66))
for x in (-9.85, 9.85, 1.5):
    flange.cyl(0.3, 0.48, cf(x, 0, -0.6), segments=14, bevel=0.04)
    for k in range(4):  # bolt heads round the flange
        a = k * math.pi / 2 + math.pi / 4
        flange.box((0.36, 0.08, 0.08), cf(x, math.cos(a) * 0.4, -0.6 + math.sin(a) * 0.4), bevel=0.02)
clamps = kit.Mesh("Clamps", "painted_metal", (50, 48, 44))
for x in (-7.5, -2.5, 2.5, 7.5):
    clamps.box((0.25, 1.7, 0.12), cf(x, -0.35, -0.06), bevel=0.03)  # wall plate
    clamps.box((0.22, 0.12, 0.62), cf(x, 0.42, -0.36), bevel=0.03)  # arm over the main pipe
    clamps.box((0.22, 0.12, 0.62), cf(x, -0.42, -0.36), bevel=0.03)
    clamps.box((0.22, 0.1, 0.5), cf(x, -0.98, -0.3), bevel=0.03)
kit.finish([pipe, flange, clamps], "pipe_run")
