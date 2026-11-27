"""Plant-room boiler (5 across, 9 tall to the top of its dome, on a 5.6
stud plinth) for the 11-stud ceilings: a lagged steel shell with banding
and rivets, a manway, a pressure gauge on a stub at the front (-Z), a
valve and a drain cock, and a flue going up into the ceiling. Origin on
the floor under its centre."""
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent / "lib"))

import kit  # noqa: E402
from kit import cf, deg  # noqa: E402

H = 11.0
R = 2.5
TOP = H - 2.0  # top of the shell (dome) at 9

plinth = kit.Mesh("Plinth", "concrete", (120, 116, 108))
plinth.box((5.6, 0.5, 5.6), cf(0, 0.25, 0), bevel=0.06)
tank = kit.Mesh("Tank", "painted_metal", (104, 100, 90))
tank.cyl(TOP - 1.3, R, cf(0, 0.5 + (TOP - 1.3) / 2, 0, rz=deg(90)), segments=24, bevel=0.05)
tank.lathe((0, TOP - 0.85, 0), (0, TOP, 0), [(0.0, R), (0.4, R * 0.86), (0.8, R * 0.5), (1.0, 0.6)], segments=24)
for y in (1.2, 3.6, 6.0):
    tank.torus(R + 0.01, 0.06, cf(0, y, 0, rz=deg(90)), segments=24, sides=4)  # lagging bands
tank.box((1.5, 1.9, 0.2), cf(0, 2.2, -R - 0.02), bevel=0.15, segments=2)  # manway
for k in range(8):
    import math
    a = math.pi * 2 * k / 8
    tank.cyl(0.12, 0.07, cf(math.cos(a) * 0.62, 2.2 + math.sin(a) * 0.8, -R - 0.14, ry=deg(90)), segments=6, bevel=0.0)
for k in range(4):  # feet
    import math
    a = math.pi / 4 + math.pi / 2 * k
    tank.box((0.5, 0.5, 0.5), cf(math.cos(a) * (R - 0.4), 0.7, math.sin(a) * (R - 0.4), ry=-a), bevel=0.05)
pipes = kit.Mesh("Pipes", "rust", (96, 92, 84))
pipes.cyl(H - TOP + 0.4, 0.3, cf(0, (TOP + H) / 2 - 0.1, 0, rz=deg(90)), segments=12, bevel=0.0)  # flue
pipes.cyl(0.14, 0.48, cf(0, TOP + 0.3, 0, rz=deg(90)), segments=12, bevel=0.03)  # its flange
pipes.cyl(0.14, 0.48, cf(0, H - 0.07, 0, rz=deg(90)), segments=12, bevel=0.03)  # ceiling collar
pipes.cyl(0.6, 0.12, cf(0, 4.0, -R - 0.25, ry=deg(90)), segments=8, bevel=0.0)  # gauge stub
pipes.cyl(1.2, 0.2, cf(R + 0.5, 5.2, 0), segments=10, bevel=0.0)  # side outlet
pipes.cyl(0.14, 0.34, cf(R + 0.2, 5.2, 0), segments=10, bevel=0.03)
pipes.cyl(1.0, 0.1, cf(1.4, 0.95, -R + 0.25, ry=deg(90)), segments=8, bevel=0.0)  # drain line
wheel = kit.Mesh("Wheel", "painted_metal", (128, 44, 34))
wheel.torus(0.38, 0.05, cf(R + 0.75, 5.2, 0, rz=deg(0)), segments=14, sides=5)
wheel.box((0.04, 0.7, 0.06), cf(R + 0.75, 5.2, 0), bevel=0.0)
wheel.box((0.04, 0.06, 0.7), cf(R + 0.75, 5.2, 0), bevel=0.0)
gauge = kit.Mesh("Gauge", "brushed_metal", (150, 146, 136))
gauge.cyl(0.14, 0.48, cf(0, 4.0, -R - 0.6, ry=deg(90)), segments=14, bevel=0.03)
face = kit.Mesh("GaugeFace", "paper", (220, 214, 196))
face.cyl(0.02, 0.4, cf(0, 4.0, -R - 0.68, ry=deg(90)), segments=14, bevel=0.0)
needle = kit.Mesh("Needle", "worn_plastic", (150, 30, 24))
needle.box((0.03, 0.32, 0.01), cf(0.06, 4.08, -R - 0.7, rz=deg(-55)), bevel=0.0)
kit.finish([plinth, tank, pipes, wheel, gauge, face, needle], "boiler", budget=2600)
