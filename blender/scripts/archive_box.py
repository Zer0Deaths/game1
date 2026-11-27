"""Archive box (1.35 wide x 1.05 tall x 1.9 deep studs): a lidded card file
box with hand holes and a label on its end, for the storage racks. Stands
on its base; the front (-Z) end faces out of the rack."""
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent / "lib"))

import kit  # noqa: E402
from kit import cf, deg  # noqa: E402

W, H, D = 1.35, 1.05, 1.9
box = kit.Mesh("Box", "cardboard", (168, 130, 84))
box.box((W - 0.04, H - 0.12, D - 0.04), cf(0, (H - 0.12) / 2, 0), bevel=0.03)
lid = kit.Mesh("Lid", "cardboard", (156, 120, 76))
lid.box((W, 0.2, D), cf(0, H - 0.1, 0, rz=deg(1.2)), bevel=0.03)  # sits a touch crooked
holes = kit.Mesh("Holes", "cardboard", (40, 30, 22))
for z in (-1, 1):
    holes.box((0.42, 0.13, 0.02), cf(0, H - 0.42, z * (D / 2 - 0.01)), bevel=0.04)
label = kit.Mesh("Label", "paper", (222, 214, 190))
label.box((0.8, 0.32, 0.01), cf(0, 0.36, -D / 2 + 0.012, rz=deg(-2)), bevel=0.0)
kit.finish([box, lid, holes, label], "archive_box")
