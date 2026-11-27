"""Lead pipe from the lift armoury (ShopItems melee_pipe): a length of old
steel pipe with a threaded elbow fitting on the end and black tape round
the grip. Modelled like MeleeModels.luau: origin at the bottom of the
handle, the shaft up +Y, the business end facing -Z."""
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent / "lib"))

import kit  # noqa: E402
from kit import cf, deg  # noqa: E402

pipe = kit.Mesh("Pipe", "rust", (120, 116, 108))
pipe.cyl(2.62, 0.12, cf(0, 1.31, 0, rz=deg(90)), segments=12, bevel=0.02)
for y in (0.04, 2.58):  # thread collars
    pipe.cyl(0.08, 0.135, cf(0, y, 0, rz=deg(90)), segments=12, bevel=0.01)
elbow = kit.Mesh("Elbow", "painted_metal", (88, 86, 80))
elbow.cyl(0.3, 0.16, cf(0, 2.72, 0, rz=deg(90)), segments=12, bevel=0.03)
elbow.ball(0.17, cf(0, 2.86, 0), segments=10)
elbow.cyl(0.34, 0.16, cf(0, 2.86, -0.17, ry=deg(90)), segments=12, bevel=0.03)
grip = kit.Mesh("Grip", "rubber", (30, 30, 28))
for k in range(6):  # tape wound in overlapping turns
    grip.cyl(0.14, 0.142, cf(0, 0.18 + k * 0.12, 0, rz=deg(90), rx=deg(6 if k % 2 else -6)), segments=12, bevel=0.01)
kit.finish([pipe, elbow, grip], "melee_pipe", budget=1200)
