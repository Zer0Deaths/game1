"""Ladder cable tray for one maze cell (20 studs), on wall brackets, with a
bundle of old cables. Wall at z = 0, front -Z, tray floor at y = 0."""
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent / "lib"))

import kit  # noqa: E402
from kit import cf, deg  # noqa: E402

tray = kit.Mesh("Tray", "brushed_metal", (130, 130, 124))
for z in (-0.25, -1.75):
    tray.box((20, 0.3, 0.06), cf(0, 0.15, z), bevel=0.02)  # side rails
for i in range(10):
    tray.box((0.12, 0.05, 1.5), cf(-9 + i * 2, 0.03, -1.0), bevel=0.015)  # rungs
brackets = kit.Mesh("Brackets", "painted_metal", (60, 58, 54))
for x in (-7.5, 0, 7.5):
    brackets.box((0.2, 0.12, 1.9), cf(x, -0.07, -1.0), bevel=0.03)
    brackets.box((0.2, 1.0, 0.12), cf(x, -0.4, -0.06), bevel=0.03)
    brackets.box((0.12, 0.1, 1.25), cf(x, -0.5, -0.55, rx=deg(-38)), bevel=0.02)  # brace
cables = kit.Mesh("Cables", "rubber", (44, 44, 42))
for k, (z, r) in enumerate(((-0.6, 0.11), (-0.85, 0.09), (-1.1, 0.12), (-1.35, 0.08), (-0.95, 0.07))):
    y = 0.06 + r + (0.18 if k == 4 else 0)
    cables.cyl(20, r, cf(0, y, z), segments=8, bevel=0.02)  # cut ends hide under the next run's
kit.finish([tray, brackets, cables], "cable_tray")
