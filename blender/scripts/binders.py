"""A row of ring binders on a desk (each 0.35 thick x 1.3 tall x 1.0 deep
studs), spines to the front (-Z) with paper labels, the first one leaning.
Origin under the first binder; the row runs along +X."""
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent / "lib"))

import kit  # noqa: E402
from kit import cf, deg  # noqa: E402

COLOURS = [("BinderRed", (120, 40, 36)), ("BinderBlue", (40, 60, 100)), ("BinderGreen", (60, 80, 50)),
           ("BinderGrey", (60, 58, 54))]
meshes = {n: kit.Mesh(n, "worn_plastic", c) for n, c in COLOURS}
pages = kit.Mesh("Pages", "paper", (220, 214, 192))
labels = kit.Mesh("Labels", "paper", (232, 226, 206))
order = ["BinderRed", "BinderBlue", "BinderGreen", "BinderGrey", "BinderBlue"]
for i, name in enumerate(order):
    lean = deg(20) if i == 0 else 0.0
    x = i * 0.38 + (0.22 if i == 0 else 0.0)
    pivot = cf(x, 0, 0, rz=lean)
    m = meshes[name]
    for s in (-1, 1):  # covers
        m.box((0.04, 1.3, 1.0), pivot @ cf(s * 0.155, 0.65, 0), bevel=0.015)
    m.box((0.35, 1.3, 0.05), pivot @ cf(0, 0.65, -0.5), bevel=0.02)  # spine
    pages.box((0.26, 1.18, 0.9), pivot @ cf(0, 0.64, 0.04), bevel=0.01)
    labels.box((0.2, 0.42, 0.01), pivot @ cf(0, 0.85, -0.53), bevel=0.0)
    labels.cyl(0.01, 0.07, pivot @ cf(0, 0.3, -0.53, ry=deg(90)), segments=8, bevel=0.0)  # finger hole ring
kit.finish([*meshes.values(), pages, labels], "binders")
