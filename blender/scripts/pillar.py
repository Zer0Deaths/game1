"""Room pillar (2.4 x 11 x 2.4 studs) with a skirted base and a cornice,
matching LevelBuilder's pillars at the inner grid corners of open rooms."""
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent / "lib"))

import kit  # noqa: E402
from kit import cf, deg  # noqa: E402

shaft = kit.Mesh("Pillar", "wallpaper", (190, 170, 96))
shaft.box((2.4, 11, 2.4), cf(0, 5.5, 0), bevel=0.15, segments=2)
trim = kit.Mesh("Trim", "painted_metal", (112, 94, 54))
trim.box((2.8, 0.7, 2.8), cf(0, 0.35, 0), bevel=0.06, segments=2)  # base
trim.box((2.7, 0.35, 2.7), cf(0, 10.82, 0), bevel=0.06)  # cornice under the ceiling
kit.finish([shaft, trim], "pillar")
