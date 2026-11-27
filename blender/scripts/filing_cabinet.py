"""Four-drawer steel filing cabinet, the one LevelBuilder stands against
office walls (1.8 wide x 4.4 tall x 2.2 deep studs, drawers on the front,
-Z). Recessed plinth, drawer fronts with pull handles and card holders,
the second drawer left a little open."""
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent / "lib"))

import kit  # noqa: E402
from kit import cf  # noqa: E402

W, H, D = 1.8, 4.4, 2.2
GREY = (140, 138, 126)

body = kit.Mesh("Body", "painted_metal", GREY)
body.box((W, H - 0.22, D - 0.06), cf(0, 0.22 + (H - 0.22) / 2, 0.03), bevel=0.05)
body.box((W - 0.16, 0.22, D - 0.3), cf(0, 0.11, 0.1), bevel=0.03)  # plinth, set back
drawers = kit.Mesh("Drawers", "painted_metal", (150, 148, 136))
handles = kit.Mesh("Handles", "brushed_metal", (180, 178, 170))
labels = kit.Mesh("Labels", "paper", (214, 206, 180))
for i in range(4):
    y0 = 0.3 + i * 1.03
    ajar = 0.45 if i == 2 else 0.0
    z = -D / 2 - 0.02 - ajar
    drawers.panel((W - 0.1, 0.97, 0.1), cf(0, y0 + 0.5, z), inset=0.1, depth=0.02, bevel=0.025)
    if ajar:
        # The drawer's sides showing where it's pulled out.
        for s in (-1, 1):
            drawers.box((0.04, 0.8, ajar), cf(s * (W / 2 - 0.12), y0 + 0.48, -D / 2 - ajar / 2), bevel=0.01)
    handles.box((0.62, 0.09, 0.1), cf(0, y0 + 0.62, z - 0.1), bevel=0.035)
    for s in (-1, 1):
        handles.box((0.06, 0.09, 0.1), cf(s * 0.28, y0 + 0.62, z - 0.05), bevel=0.02)
    handles.box((0.46, 0.22, 0.02), cf(0, y0 + 0.82, z - 0.06), bevel=0.008)  # card holder frame
    labels.box((0.4, 0.16, 0.01), cf(0, y0 + 0.82, z - 0.072), bevel=0.0)
kit.finish([body, drawers, handles, labels], "filing_cabinet")
