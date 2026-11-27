"""The same bin knocked over: lying on its side, mouth to the front (-Z),
its crumpled paper spilled across the floor. Origin on the floor under
where it stood."""
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent / "lib"))

import kit  # noqa: E402
from kit import cf, deg  # noqa: E402

bin_ = kit.Mesh("Bin", "painted_metal", (70, 72, 70))
# Tapered tub along Z: base at +Z, mouth at -Z; lying on its widest edge.
bin_.cyl(1.12, 0.38, cf(0, 0.43, 0, ry=deg(90), rz=deg(-1.5)), segments=16, bevel=0.02, radius2=0.45)
bin_.torus(0.45, 0.035, cf(0, 0.45, -0.56, ry=deg(90)), segments=16, sides=6)
paper = kit.Mesh("Paper", "paper", (226, 222, 206))
for k, (x, z, r) in enumerate(((0.1, -0.75, 0.22), (-0.45, -1.15, 0.2), (0.4, -1.5, 0.19), (-0.1, -1.9, 0.17),
                               (0.65, -0.95, 0.15), (-0.7, -1.7, 0.16))):
    paper.ball(r, cf(x, r * 0.8, z, rx=deg(k * 50), ry=deg(k * 33)), segments=7, scale=(1.0, 0.8, 0.9 + 0.05 * k))
paper.sheet(0.85, 1.1, cf(0.15, 0.02, -2.3, rx=deg(90), ry=deg(25)), curl=0.06, wave=0.01, seed=4)
kit.finish([bin_, paper], "wastebin_tipped")
