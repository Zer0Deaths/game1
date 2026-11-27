"""Hospital bay curtain on its ceiling track (8 studs long, for the 11-stud
Ward ceilings): a chrome C-track hung on two drop rods, gliders, and
pleated curtains: a long run drawn half across, a panel bunched at one
end, and one torn off short. Origin on the floor under the middle of the
track, the track along X."""
import math
import random
import sys
from pathlib import Path

import bmesh

sys.path.append(str(Path(__file__).resolve().parent.parent / "lib"))

import kit  # noqa: E402
from kit import cf, deg  # noqa: E402

H = 11.0
TRACK_Y = H - 0.6

track = kit.Mesh("Track", "brushed_metal", (170, 172, 170))
track.box((8.0, 0.12, 0.16), cf(0, TRACK_Y, 0), bevel=0.03)
for s in (-1, 1):
    track.box((0.14, 0.22, 0.22), cf(s * 4.0, TRACK_Y, 0), bevel=0.04)  # end stops
    track.cyl(0.6, 0.035, cf(s * 2.8, TRACK_Y + 0.33, 0, rz=deg(90)), segments=6, bevel=0.0)  # drop rods
    track.cyl(0.04, 0.16, cf(s * 2.8, H - 0.02, 0, rz=deg(90)), segments=8, bevel=0.0)  # ceiling roses


def pleats(mesh, x0, x1, top, bottom, depth, folds, seed, flare=0.0, ragged=0.0, sway=0.0):
    """A pleated curtain from x0 to x1, hanging from `top` to `bottom`:
    a zig-zag folded sheet, the folds opening out a little towards the hem
    (flare), the hem torn uneven (ragged), the bottom swung aside (sway)."""
    rnd = random.Random(seed)
    bm = bmesh.new()
    rows = 5
    cols = folds * 2 + 1
    grid = []
    hem = [bottom + (rnd.random() - 0.5) * ragged * 2 for _ in range(cols)]
    for r in range(rows + 1):
        t = r / rows  # 0 at the top
        row = []
        for c in range(cols):
            u = c / (cols - 1)
            x = x0 + (x1 - x0) * u + sway * t * t
            z = (depth * (1 + flare * t)) * (1 if c % 2 else -1) * 0.5
            y = top + (hem[c] - top) * t
            row.append(bm.verts.new((x, y, z)))
        grid.append(row)
    for r in range(rows):
        for c in range(cols - 1):
            bm.faces.new((grid[r][c], grid[r][c + 1], grid[r + 1][c + 1], grid[r + 1][c]))
    bmesh.ops.solidify(bm, geom=list(bm.faces), thickness=0.025)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return mesh._add(bm, cf())


cloth = kit.Mesh("Curtain", "fabric", (150, 176, 168))
top = TRACK_Y - 0.12
pleats(cloth, -3.85, 0.6, top, 0.95, 0.32, 9, seed=1, flare=0.6, sway=0.25)  # drawn half across
pleats(cloth, 2.9, 3.85, top, 0.95, 0.42, 3, seed=2, flare=0.3)  # bunched at the far end
pleats(cloth, 1.2, 2.3, top, 6.2, 0.25, 3, seed=3, ragged=0.35, sway=-0.15)  # torn short
gliders = kit.Mesh("Gliders", "worn_plastic", (210, 210, 204))
for x in [-3.8 + k * 0.5 for k in range(10)] + [1.25, 1.75, 2.25, 2.95, 3.3, 3.65]:
    gliders.box((0.08, 0.16, 0.08), cf(x, TRACK_Y - 0.12, 0), bevel=0.0)
kit.finish([track, cloth, gliders], "curtain_rail")
