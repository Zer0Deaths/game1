"""Sledgehammer from the lift armoury (ShopItems melee_sledge): a heavy
square steel head with chamfered faces on an ash handle, rubber grip at
the end. Origin at the bottom of the handle, handle up +Y, one face of
the head toward -Z."""
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent / "lib"))

import kit  # noqa: E402
from kit import cf, deg  # noqa: E402

handle = kit.Mesh("Handle", "wood", (176, 150, 96))
handle.box((0.17, 2.85, 0.17), cf(0, 1.43, 0), bevel=0.05, segments=2)
head = kit.Mesh("Head", "painted_metal", (52, 52, 50))
head.box((0.5, 0.5, 1.0), cf(0, 3.0, 0), bevel=0.06, segments=2)
faces = kit.Mesh("Faces", "brushed_metal", (130, 128, 122))
for s in (-1, 1):
    faces.box((0.44, 0.44, 0.1), cf(0, 3.0, s * 0.53), bevel=0.04)  # struck faces, worn bright
wedge = kit.Mesh("Wedge", "brushed_metal", (100, 98, 92))
wedge.box((0.06, 0.04, 0.14), cf(0, 3.27, 0), bevel=0.0)  # the wedge in the top of the eye
grip = kit.Mesh("Grip", "rubber", (30, 30, 28))
grip.cyl(0.7, 0.11, cf(0, 0.4, 0, rz=deg(90)), segments=12, bevel=0.02)
kit.finish([handle, head, faces, wedge, grip], "melee_sledge", budget=1000)
