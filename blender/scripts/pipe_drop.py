"""A drop off the Plant's wall pipe run: a tee in the run (at 8.7 studs,
where the game hangs pipe_run when it has a drop), a 0.45 pipe down the
wall to a gate valve with a red handwheel at 3.6, a drain below it, and a
pressure gauge on a siphon loop beside it.
Frame: on the wall face at floor height under the drop, X along the wall,
-Z out of the wall (the run's centre line is 0.6 off the wall)."""
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent / "lib"))

import kit  # noqa: E402
from kit import cf, deg  # noqa: E402
from shapes import tube  # noqa: E402

TOP, Z = 8.7, -0.6
pipe = kit.Mesh("Pipe", "painted_metal", (96, 92, 84))
pipe.cyl(TOP - 3.95, 0.225, cf(0, (TOP + 3.95) / 2, Z, rz=deg(90)), segments=12, bevel=0.0)
pipe.cyl(0.9, 0.42, cf(0, TOP, Z), segments=12, bevel=0.05)  # tee body round the run
pipe.cyl(0.14, 0.36, cf(0, TOP - 0.55, Z, rz=deg(90)), segments=12, bevel=0.03)  # flange under the tee
pipe.cyl(0.14, 0.36, cf(0, 4.0, Z, rz=deg(90)), segments=12, bevel=0.03)  # flange on the valve
pipe.box((0.62, 0.7, 0.5), cf(0, 3.6, Z), bevel=0.12, segments=2)  # valve body
pipe.cyl(0.55, 0.09, cf(0, 3.6, Z - 0.4, ry=deg(90)), segments=8, bevel=0.0)  # spindle
pipe.cyl(0.14, 0.36, cf(0, 3.2, Z, rz=deg(90)), segments=12, bevel=0.03)
pipe.cyl(0.55, 0.16, cf(0, 2.85, Z, rz=deg(90)), segments=10, bevel=0.0)  # drain
pipe.cyl(0.2, 0.22, cf(0, 2.56, Z, rz=deg(90)), segments=10, bevel=0.03)  # cap
for y in (5.0, 7.2):  # wall brackets
    pipe.box((0.6, 0.18, 0.5), cf(0, y, -0.3), bevel=0.03)
tube(pipe, [(0, 4.8, Z - 0.1), (0.4, 4.8, Z - 0.1), (0.62, 4.65, Z - 0.12), (0.75, 4.8, -0.75)], 0.05, segments=6)  # siphon
wheel = kit.Mesh("ValveWheel", "painted_metal", (128, 44, 34))
wheel.torus(0.6, 0.06, cf(0, 3.6, Z - 0.68, ry=deg(90)), segments=16, sides=5)
for a in (0, 60, 120):
    wheel.box((1.15, 0.07, 0.05), cf(0, 3.6, Z - 0.68, rz=deg(a)), bevel=0.0)
gauge = kit.Mesh("Gauge", "brushed_metal", (150, 146, 136))
gauge.cyl(0.14, 0.38, cf(0.75, 4.8, -0.82, ry=deg(90)), segments=14, bevel=0.03)
face = kit.Mesh("GaugeFace", "paper", (214, 208, 190))
face.cyl(0.02, 0.32, cf(0.75, 4.8, -0.9, ry=deg(90)), segments=14, bevel=0.0)
needle = kit.Mesh("Needle", "worn_plastic", (150, 30, 24))
needle.box((0.025, 0.26, 0.01), cf(0.79, 4.85, -0.915, rz=deg(-35)), bevel=0.0)
kit.finish([pipe, wheel, gauge, face, needle], "pipe_drop")
