"""Ward medicine cabinet (3 wide x 5.4 tall x 1.4 deep studs): white
enamelled steel on a plinth, glazed doors on the top half with shelves of
bottles and boxes behind them, solid doors below, a label plate, and a
yellow sharps bin with a red lid left on top. Front -Z."""
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent / "lib"))

import kit  # noqa: E402
from kit import cf, deg  # noqa: E402
from shapes import frame_box  # noqa: E402

W, H, D = 3.0, 5.4, 1.4
body = kit.Mesh("Body", "painted_metal", (210, 212, 204))
body.box((W, H - 0.3, D), cf(0, 0.3 + (H - 0.3) / 2, 0), bevel=0.05)
body.box((W - 0.2, 0.3, D - 0.2), cf(0, 0.15, 0.05), bevel=0.03)  # plinth
for s in (-1, 1):
    frame_box(body, (1.45, 2.5), (1.2, 2.25), 0.08, cf(s * 0.74, 3.8, -D / 2 - 0.03), bevel=0.02)  # glazed door frames
    body.panel((1.45, 2.2, 0.08), cf(s * 0.74, 1.4, -D / 2 - 0.03), inset=0.12, depth=0.02, bevel=0.02)  # lower doors
inside = kit.Mesh("Inside", "painted_metal", (150, 154, 150))
inside.box((W - 0.2, 2.4, 0.04), cf(0, 3.8, D / 2 - 0.2), bevel=0.0)  # back wall seen through the glass
for y in (3.0, 3.85, 4.7):
    inside.box((W - 0.2, 0.05, D - 0.3), cf(0, y, -0.05), bevel=0.01)
glass = kit.Mesh("Glass", "glass", (150, 170, 170), transparency=0.5, shadow=False)
for s in (-1, 1):
    glass.box((1.22, 2.27, 0.02), cf(s * 0.74, 3.8, -D / 2 - 0.03), bevel=0.0)
stock = kit.Mesh("Stock", "worn_plastic", (150, 100, 50))
for k, (x, y, r, h) in enumerate(((-1.1, 3.03, 0.12, 0.45), (-0.8, 3.03, 0.1, 0.35), (-0.5, 3.03, 0.13, 0.55), (0.6, 3.03, 0.11, 0.4),
                                  (-0.9, 3.88, 0.1, 0.3), (0.3, 3.88, 0.12, 0.45), (0.65, 3.88, 0.1, 0.38), (1.1, 4.73, 0.12, 0.5))):
    stock.cyl(h, r, cf(x, y + h / 2, -0.15 + (k % 2) * 0.25, rz=deg(90)), segments=8, bevel=0.0)
boxes = kit.Mesh("Boxes", "cardboard", (214, 210, 196))
boxes.box((0.7, 0.5, 0.6), cf(0.2, 3.28, 0.0, ry=deg(8)), bevel=0.02)
boxes.box((0.5, 0.65, 0.5), cf(-0.4, 4.05, 0.05, ry=deg(-5)), bevel=0.02)
boxes.box((0.9, 0.35, 0.6), cf(-0.6, 4.9, 0.0), bevel=0.02)
fittings = kit.Mesh("Fittings", "brushed_metal", (176, 176, 170))
for s in (-1, 1):
    fittings.box((0.06, 0.4, 0.08), cf(s * 0.12, 3.6, -D / 2 - 0.1), bevel=0.02)
    fittings.box((0.06, 0.4, 0.08), cf(s * 0.12, 1.7, -D / 2 - 0.1), bevel=0.02)
fittings.box((0.9, 0.25, 0.02), cf(0, 5.25, -D / 2 - 0.01), bevel=0.005)  # label plate
sharps = kit.Mesh("SharpsBin", "worn_plastic", (200, 170, 40))
sharps.box((0.8, 0.75, 0.6), cf(1.0, H + 0.375, 0, ry=deg(-7)), bevel=0.06)
lid = kit.Mesh("SharpsLid", "worn_plastic", (160, 40, 34))
lid.box((0.84, 0.16, 0.64), cf(1.0, H + 0.82, 0, ry=deg(-7)), bevel=0.05)
kit.finish([body, inside, glass, stock, boxes, fittings, sharps, lid], "med_cabinet")
