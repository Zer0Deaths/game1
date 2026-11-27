"""Loot: Rusted Stapler (0.6 x 0.6 x 1.6 studs). Rust-red top arm (its one
accent) on a dark base, hinge at the back, jaw slightly open."""
import math
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent / "lib"))

import kit  # noqa: E402
from kit import cf, deg  # noqa: E402

base = kit.Mesh("Base", "rust", (70, 60, 52))
base.box((0.56, 0.12, 1.56), cf(0, 0.06, 0), bevel=0.04)
base.box((0.3, 0.32, 0.3), cf(0, 0.2, 0.62), bevel=0.06)  # hinge block
base.cyl(0.5, 0.08, cf(0, 0.36, 0.65), segments=10, bevel=0.02)  # hinge pin
arm = kit.Mesh("Arm", "rust", (110, 40, 36))
arm.box((0.46, 0.24, 1.42), cf(0, 0.44, -0.04, rx=deg(4)), bevel=0.1, segments=2)
arm.box((0.36, 0.08, 0.3), cf(0, 0.17, -0.62), bevel=0.03)  # anvil plate
kit.finish([base, arm], "item_stapler")
