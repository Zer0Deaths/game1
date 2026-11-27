"""EXIT sign box (3.4 x 1 x 0.4 studs) on two ceiling rods. The lettering
is drawn by the game on its face, so "Face" is a plain diffuser."""
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent / "lib"))

import kit  # noqa: E402
from kit import cf, deg  # noqa: E402

box = kit.Mesh("Housing", "worn_plastic", (40, 42, 38))
box.panel((3.4, 1.0, 0.4), cf(0, 0, 0), inset=0.1, depth=0.05, faces=("front", "back"), bevel=0.06)
face = kit.Mesh("Face", "neon", (70, 120, 80), shadow=False)
for z in (-0.16, 0.16):
    face.box((3.15, 0.75, 0.02), cf(0, 0, z), bevel=0.008)
mount = kit.Mesh("Mount", "brushed_metal", (140, 138, 130))
for x in (-1.2, 1.2):
    mount.cyl(0.6, 0.04, cf(x, 0.8, 0, rz=deg(90)), segments=8)
    mount.cyl(0.05, 0.14, cf(x, 1.1, 0, rz=deg(90)), segments=10, bevel=0.01)  # ceiling rose
kit.finish([box, face, mount], "exit_sign")
