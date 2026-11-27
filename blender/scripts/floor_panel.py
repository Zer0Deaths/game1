"""Floor for one maze cell (20 x 20 studs): sixteen 5-stud tiles butted
together, each with a soft chamfer on its top edges so the seams read as
grooves. Carpet tiles on The Carpet; the game copies the level's own floor
material and colour onto it (vinyl on The Ward, steel plate in the Plant).

Origin at the underside; the game sinks it 0.12 so the tile tops are flush
with the floor slab (the slab stays as the invisible floor you walk on).
The tiles' sides and undersides are never seen, so they aren't built."""
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent / "lib"))

import kit  # noqa: E402
from kit import cf  # noqa: E402
from shapes import slab  # noqa: E402

T = 0.12  # tile thickness

carpet = kit.Mesh("Carpet", "carpet", (128, 110, 62))
for i in range(4):
    for j in range(4):
        slab(carpet, (5.0, T, 5.0), cf(-7.5 + i * 5, T / 2, -7.5 + j * 5), bevel=0.06,
             bevel_faces=("top",), drop=("bottom", "left", "right", "front", "back"))
kit.finish([carpet], "floor_panel")
