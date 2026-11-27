"""Plant-room pump set on a steel skid (4.4 x 2.4 studs): a finned electric
motor with its fan cowl, a coupling guard, a cast pump casing, and the
discharge pipe rising from the casing with a flange and a valve.
Origin on the floor under the skid's centre; motor towards -X."""
import math
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent / "lib"))

import kit  # noqa: E402
from kit import cf, deg  # noqa: E402

base = kit.Mesh("Base", "painted_metal", (70, 70, 66))
for s in (-1, 1):
    base.box((4.4, 0.6, 0.18), cf(0, 0.3, s * 1.1), bevel=0.03)  # channel sides
base.box((4.3, 0.12, 2.2), cf(0, 0.54, 0), bevel=0.02)  # deck plate
for x in (-1.8, 1.8):
    for s in (-1, 1):
        base.cyl(0.12, 0.1, cf(x, 0.66, s * 0.8, rz=deg(90)), segments=6, bevel=0.0)  # hold-down bolts
motor = kit.Mesh("Motor", "painted_metal", (60, 90, 80))
motor.cyl(1.9, 0.78, cf(-0.95, 1.45, 0), segments=18, bevel=0.06)
for k in range(10):  # cooling fins
    a = math.pi * 2 * k / 10
    motor.box((1.7, 0.06, 0.16), cf(-0.95, 1.45 + math.sin(a) * 0.8, math.cos(a) * 0.8, rx=-a), bevel=0.0)
motor.cyl(0.5, 0.82, cf(-2.1, 1.45, 0), segments=18, bevel=0.06)  # fan cowl
motor.box((0.7, 0.5, 0.6), cf(-0.8, 2.3, 0), bevel=0.05)  # terminal box
for s in (-1, 1):
    motor.box((0.4, 0.4, 0.3), cf(-0.95, 0.75, s * 0.55), bevel=0.04)  # feet
guard = kit.Mesh("Guard", "painted_metal", (170, 140, 40))
guard.box((0.6, 0.9, 0.9), cf(0.35, 1.45, 0), bevel=0.08)
casing = kit.Mesh("Casing", "rust", (90, 70, 50))
casing.cyl(0.9, 0.85, cf(1.3, 1.45, 0), segments=18, bevel=0.08)  # volute
casing.cyl(0.5, 0.42, cf(1.95, 1.45, 0), segments=12, bevel=0.04)  # suction eye
casing.cyl(0.14, 0.55, cf(2.22, 1.45, 0), segments=12, bevel=0.03)  # suction flange
casing.box((0.9, 0.6, 1.2), cf(1.3, 0.85, 0), bevel=0.05)  # pedestal
pipe = kit.Mesh("Pipe", "painted_metal", (96, 92, 84))
pipe.cyl(4.8, 0.25, cf(1.3, 3.7, 0, rz=deg(90)), segments=12, bevel=0.0)
for y in (2.35, 4.2, 6.0):
    pipe.cyl(0.14, 0.42, cf(1.3, y, 0, rz=deg(90)), segments=12, bevel=0.03)
pipe.cyl(0.5, 0.32, cf(1.3, 3.4, 0, rz=deg(90)), segments=12, bevel=0.04)  # valve body
wheel = kit.Mesh("Wheel", "painted_metal", (128, 44, 34))
wheel.cyl(0.5, 0.05, cf(1.3, 3.4, -0.55, ry=deg(90)), segments=6, bevel=0.0)  # spindle
wheel.torus(0.34, 0.045, cf(1.3, 3.4, -0.8, ry=deg(90)), segments=14, sides=5)
kit.finish([base, motor, guard, casing, pipe, wheel], "pump")
