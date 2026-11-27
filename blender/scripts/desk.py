"""Office desk, the one LevelBuilder places (top 5.2 x 2.6 studs at 2.6 high):
wood-effect top, grey steel sides and modesty panel, a drawer pedestal."""
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent / "lib"))

import kit  # noqa: E402
from kit import cf, deg  # noqa: E402

top = kit.Mesh("DeskTop", "wood", (150, 120, 82))
top.box((5.2, 0.25, 2.6), cf(0, 2.6, 0), bevel=0.06, segments=2)
steel = kit.Mesh("DeskFrame", "painted_metal", (120, 122, 120))
for s in (-1, 1):
    steel.box((0.2, 2.45, 2.5), cf(s * 2.45, 1.25, 0), bevel=0.04)
steel.box((4.7, 1.4, 0.12), cf(0, 1.7, -1.15), bevel=0.03)
steel.box((1.5, 0.6, 2.3), cf(1.55, 2.17, 0), bevel=0.04)  # drawer under the top
handles = kit.Mesh("DeskHandles", "brushed_metal", (176, 174, 166))
handles.box((0.6, 0.08, 0.08), cf(1.55, 2.17, 1.2), bevel=0.03)
kit.finish([top, steel, handles], "desk")
