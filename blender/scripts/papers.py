"""Scattered papers: six sheets dropped on the floor in a rough fan, some
curling at the corner (about 3.5 x 3 studs)."""
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent / "lib"))

import kit  # noqa: E402
from kit import cf, deg  # noqa: E402

sheets = kit.Mesh("Papers", "paper", (222, 216, 196))
for i, (x, z, yaw) in enumerate(((-1.0, -0.5, 20), (0.2, -0.8, -35), (1.1, 0.2, 60), (-0.4, 0.6, 95), (0.6, 1.0, -10), (-1.3, 0.9, 140))):
    sheets.sheet(1.1, 1.45, cf(x, 0.012 + i * 0.006, z, rx=deg(-90), rz=deg(yaw)), curl=0.08, wave=0.006, seed=i)
kit.finish([sheets], "papers")
