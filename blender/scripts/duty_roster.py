"""Duty roster sheet (2.3 x 3 studs) pinned to the wall with its bottom
corner curling away. The game writes the roster on it."""
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent / "lib"))

import kit  # noqa: E402
from kit import cf, deg  # noqa: E402

sheet = kit.Mesh("Sheet", "paper", (226, 222, 206))
sheet.sheet(2.3, 3.0, cf(0, 1.5, 0), curl=0.12, wave=0.01, nx=8, ny=10, seed=7)
pins = kit.Mesh("Pins", "worn_plastic", (40, 90, 160))
for x in (-0.95, 0.95):
    pins.ball(0.07, cf(x, 2.85, -0.05), segments=8)
kit.finish([sheet, pins], "duty_roster")
