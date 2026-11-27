"""Old CRT monitor (1.7 wide x 1.25 tall x 1.1 deep studs, as LevelBuilder
sizes it), modelled about its own centre with the SCREEN FACING +Z (towards
the desk chair, the way the desk code places it). Deep tapered back with
vents, a bulged dark screen, a small stand underneath, a power light."""
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent / "lib"))

import kit  # noqa: E402
from kit import cf, deg  # noqa: E402

case = kit.Mesh("Casing", "worn_plastic", (196, 190, 172))
case.panel((1.7, 1.25, 0.32), cf(0, 0.0, 0.39, ry=deg(180)), inset=0.16, depth=0.04, bevel=0.06)  # bezel
case.box((1.42, 1.0, 0.45), cf(0, 0.04, 0.0), bevel=0.08)  # tube housing
case.box((0.95, 0.72, 0.32), cf(0, 0.08, -0.38), bevel=0.08)  # neck
case.box((0.8, 0.12, 0.7), cf(0, -0.6, 0.05), bevel=0.04)  # stand
vents = kit.Mesh("Vents", "worn_plastic", (60, 58, 52))
for k in range(6):
    vents.box((0.04, 0.02, 0.36), cf(-0.3 + k * 0.12, 0.445, -0.36), bevel=0.0)
screen = kit.Mesh("Screen", "glass", (24, 28, 26))
screen.box((1.34, 0.96, 0.1), cf(0, 0.0, 0.5), bevel=0.12, segments=2)  # rounded-corner glass, bowed out of the bezel
led = kit.Mesh("Led", "neon", (90, 200, 90), shadow=False)
led.box((0.05, 0.05, 0.02), cf(0.68, -0.5, 0.56), bevel=0.0)
kit.finish([case, vents, screen, led], "crt_monitor")
