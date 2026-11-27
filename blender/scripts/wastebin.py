"""Office waste-paper bin (0.9 across, 1.2 tall studs), a tapered steel tub
with a rolled rim, stuffed with crumpled paper. Origin on the floor under
its centre."""
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent / "lib"))

import kit  # noqa: E402
from kit import cf, deg  # noqa: E402

bin_ = kit.Mesh("Bin", "painted_metal", (70, 72, 70))
bin_.cyl(1.12, 0.38, cf(0, 0.56, 0, rz=deg(90)), segments=16, bevel=0.02, radius2=0.45)
bin_.torus(0.45, 0.035, cf(0, 1.12, 0, rz=deg(90)), segments=16, sides=6)
paper = kit.Mesh("Paper", "paper", (226, 222, 206))
for k, (x, y, z, r) in enumerate(((0.14, 1.06, 0.12, 0.17), (-0.2, 1.05, -0.06, 0.16), (0.05, 1.1, -0.22, 0.15),
                                  (-0.08, 1.16, 0.2, 0.14), (0.24, 1.12, -0.12, 0.13), (-0.26, 1.1, 0.16, 0.12),
                                  (0.0, 1.2, 0.0, 0.15))):
    paper.ball(r, cf(x, y, z, rx=deg(k * 40), ry=deg(k * 70)), segments=7, scale=(1.0, 0.75 + 0.06 * k, 0.9))
paper.sheet(0.7, 0.9, cf(0.12, 1.12, 0.28, rx=deg(-62), ry=deg(20)), curl=0.1, wave=0.02, seed=2)  # a sheet half out
kit.finish([bin_, paper], "wastebin")
