"""Extra shapes for SHIFT's big modular pieces (walls, floors, ceilings),
on top of kit.Mesh. Same units and axes as kit: studs, Roblox axes, front -Z.

slab() is a box that can bevel only some of its faces' edges and leave out
faces nobody can ever see (the underside of a floor tile, the hidden sides
of tiles that butt up against each other), so a cell's worth of floor or
ceiling stays cheap when there are a thousand of them in a level.
"""

import bmesh

from kit import cf

_DIRS = {"top": (1, 1), "bottom": (1, -1), "left": (0, -1), "right": (0, 1), "front": (2, -1), "back": (2, 1)}


def _facing(face, which):
    i, s = _DIRS[which]
    return face.normal[i] * s > 0.99


def slab(mesh, size, at=None, bevel=0.04, bevel_faces=None, drop=()):
    """A box of `size` (studs) on `mesh`.

    bevel_faces: bevel only the edges of these faces ("top", "bottom",
                 "left", "right", "front" (-Z), "back" (+Z)); None = all edges.
    drop:        faces to leave out entirely (never seen).
    """
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    bmesh.ops.scale(bm, vec=size, verts=bm.verts)
    bm.normal_update()
    if bevel > 0:
        if bevel_faces:
            edges = {e for f in bm.faces if any(_facing(f, d) for d in bevel_faces) for e in f.edges}
        else:
            edges = set(bm.edges)
        bmesh.ops.bevel(bm, geom=list(edges), offset=min(bevel, min(size) * 0.45), segments=1,
                        profile=0.5, affect="EDGES", clamp_overlap=True)
        bm.normal_update()
    if drop:
        kill = [f for f in bm.faces if any(_facing(f, d) for d in drop)]
        bmesh.ops.delete(bm, geom=kill, context="FACES")
    return mesh._add(bm, at or cf())


def frame_box(mesh, outer, inner, depth, at=None, bevel=0.03):
    """A rectangular frame in the XY plane (a picture frame, a door surround):
    outer (w, h), inner opening (w, h), depth along Z. Four bevelled bars."""
    ow, oh = outer
    iw, ih = inner
    side = (ow - iw) / 2
    top = (oh - ih) / 2
    m = at or cf()
    for sx in (-1, 1):
        mesh.box((side, oh, depth), m @ cf(sx * (iw + side) / 2, 0, 0), bevel=bevel)
    for sy in (-1, 1):
        mesh.box((iw, top, depth), m @ cf(0, sy * (ih + top) / 2, 0), bevel=bevel)
    return mesh


def tube(mesh, points, radius, segments=6, caps=True):
    """Thin tubing through points (studs): straight unbevelled runs, no
    balls at the bends (at this thickness nobody sees the joins). Cheaper
    than kit.Mesh.pipe for the chrome frames of trolleys and chairs."""
    from mathutils import Matrix, Vector
    for p, q in zip(points, points[1:]):
        p, q = Vector(p), Vector(q)
        d = q - p
        if d.length < 1e-4:
            continue
        rot = Vector((1, 0, 0)).rotation_difference(d.normalized()).to_matrix().to_4x4()
        mesh.cyl(d.length + radius * 0.6, radius, Matrix.Translation((p + q) / 2) @ rot, segments, bevel=0.0)
    return mesh
