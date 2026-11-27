"""Steel oil drum (2.2 across x 3.4 tall studs): rolled chimes top and
bottom, two rolling hoops, a big and a small bung in the lid. Modelled standing up, origin on the floor under its centre; the
Plant lays some on their side. The game paints it each drum's colour."""
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent / "lib"))

import kit  # noqa: E402
from kit import cf, deg  # noqa: E402

R, H = 1.08, 3.4
drum = kit.Mesh("Drum", "rust", (70, 84, 70))
drum.cyl(H - 0.08, R - 0.02, cf(0, H / 2, 0, rz=deg(90)), segments=20, bevel=0.03)
for y in (0.06, H - 0.06):
    drum.torus(R - 0.02, 0.05, cf(0, y, 0, rz=deg(90)), segments=20, sides=5)  # chimes
for y in (H * 0.33, H * 0.67):
    drum.torus(R + 0.0, 0.04, cf(0, y, 0, rz=deg(90)), segments=20, sides=5)  # rolling hoops
bungs = kit.Mesh("Bungs", "brushed_metal", (120, 118, 110))
bungs.cyl(0.08, 0.2, cf(0.5, H + 0.01, 0.3, rz=deg(90)), segments=10, bevel=0.02)
bungs.cyl(0.08, 0.12, cf(-0.55, H + 0.01, -0.35, rz=deg(90)), segments=8, bevel=0.02)
kit.finish([drum, bungs], "oil_drum")
