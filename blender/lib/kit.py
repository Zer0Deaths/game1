"""Modelling kit for SHIFT props, authored in ROBLOX STUDS and Roblox axes.

Every prop script in ../scripts builds its meshes here with the same numbers
the Luau primitives use (LevelBuilder.luau, Safehouse.luau, EntityRig.luau),
so a mesh lands exactly where the primitive it replaces stood:

    X right, Y up, Z back (the front of a prop faces -Z), 1 unit = 1 stud,
    origin where the Luau code puts the prop's CFrame (usually the floor
    under its centre).

finish() converts to Blender metres for roblox_export (1 stud = 0.28 m,
Roblox (X, Y, Z) = Blender (-x, z, y) / 0.28, checked with check_fbx.py)
and records each mesh's size, centre and look in exports/<name>.json.
build_all.py gathers those into src/shared/MeshManifest.luau, which the game
uses to size and place each MeshPart, so nothing depends on how Roblox
positions an imported model.
"""

import json
import math
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent))

import bpy  # noqa: E402  (bpy first: bmesh needs it when run as a module)
import bmesh  # noqa: E402
from mathutils import Matrix, Vector  # noqa: E402

import roblox_export  # noqa: E402

STUD = 0.28
UV_STUDS = 4.0  # one texture tile per 4 studs, like the parts' StudsPerTile
SHARP = math.radians(40)


def cf(x=0.0, y=0.0, z=0.0, rx=0.0, ry=0.0, rz=0.0):
    """Like Roblox CFrame.new(x, y, z) * CFrame.Angles(rx, ry, rz) (radians)."""
    rot = (Matrix.Rotation(rx, 4, "X") @ Matrix.Rotation(ry, 4, "Y")
           @ Matrix.Rotation(rz, 4, "Z"))
    return Matrix.Translation((x, y, z)) @ rot


def deg(d):
    return math.radians(d)


# PBR looks: Roblox material + SHIFT MaterialVariant (Surfaces.luau) the game
# paints the MeshPart with, and the matching Blender Principled values so
# the FBX also previews right (roughness, metallic).
LOOKS = {
    "painted_metal": ("Metal", "SHIFT_PaintedMetal", 0.55, 0.5),
    "brushed_metal": ("Metal", "SHIFT_BrushedMetal", 0.35, 1.0),
    "rust": ("CorrodedMetal", "SHIFT_Rust", 0.8, 0.6),
    "steel_plate": ("DiamondPlate", "SHIFT_SteelPlate", 0.5, 1.0),
    "worn_plastic": ("Plastic", "SHIFT_AgedPlastic", 0.6, 0.0),
    "wallpaper": ("Plaster", "SHIFT_Wallpaper", 0.85, 0.0),
    "ceiling": ("Plaster", "SHIFT_CeilingTile", 0.9, 0.0),
    "plaster": ("Plaster", "", 0.95, 0.0),
    "carpet": ("Carpet", "SHIFT_Carpet", 1.0, 0.0),
    "concrete": ("Concrete", "SHIFT_Concrete", 0.9, 0.0),
    "wood": ("Wood", "SHIFT_Wood", 0.7, 0.0),
    "fabric": ("Fabric", "SHIFT_Fabric", 0.95, 0.0),
    "rubber": ("Rubber", "SHIFT_Rubber", 0.9, 0.0),
    "paper": ("Fabric", "SHIFT_Paper", 0.95, 0.0),
    "cardboard": ("Cardboard", "SHIFT_Cardboard", 0.9, 0.0),
    "skin": ("Rubber", "SHIFT_TenantSkin", 0.7, 0.0),
    "suit": ("Fabric", "SHIFT_SuitFabric", 0.9, 0.0),
    "glass": ("Glass", "", 0.1, 0.0),
    "neon": ("Neon", "", 0.5, 0.0),
}

BEVEL = 0.04  # studs (about 1 cm): every edge is rounded, nothing is a hard 90


class Mesh:
    """One MeshPart: geometry in studs plus how Roblox should paint it.

    look:    a key of LOOKS (painted_metal, worn_plastic, wallpaper, ...)
    colour:  (r, g, b) 0-255, kept to the yellowed beige / brown / grey palette
    attach:  for rigs, the part this mesh is welded to (default: its own name)
    """

    def __init__(self, name, look="painted_metal", colour=(160, 160, 160),
                 transparency=0.0, shadow=True, attach=None):
        if look not in LOOKS:
            raise ValueError(f"{name}: unknown look {look}")
        material, surface, _, _ = LOOKS[look]
        self.name = name
        self.look_name = look
        self.look = {"look": look, "material": material, "colour": list(colour), "surface": surface,
                     "transparency": transparency, "shadow": shadow, "attach": attach or ""}
        self.bm = bmesh.new()

    # -- primitives (all in studs, placed by a 4x4 matrix from cf()) --------

    def _add(self, other, at, bevel=0.0, segments=1):
        if bevel > 0:
            bmesh.ops.bevel(other, geom=list(other.edges), offset=bevel, segments=segments,
                            profile=0.5, affect="EDGES", clamp_overlap=True)
        bmesh.ops.transform(other, matrix=at, verts=other.verts)
        tmp = bpy.data.meshes.new("tmp")
        other.to_mesh(tmp)
        self.bm.from_mesh(tmp)
        bpy.data.meshes.remove(tmp)
        other.free()
        return self

    def box(self, size, at=None, bevel=BEVEL, segments=1):
        bm = bmesh.new()
        bmesh.ops.create_cube(bm, size=1.0)
        bmesh.ops.scale(bm, vec=size, verts=bm.verts)
        return self._add(bm, at or cf(), min(bevel, min(size) * 0.45), segments)

    def panel(self, size, at=None, inset=0.3, depth=0.05, faces=("front",), bevel=BEVEL):
        """Bevelled box with a sloped recessed panel pressed into its front
        (-Z) and/or back (+Z) face, like the test door's slab."""
        bm = bmesh.new()
        bmesh.ops.create_cube(bm, size=1.0)
        bmesh.ops.scale(bm, vec=size, verts=bm.verts)
        bmesh.ops.bevel(bm, geom=list(bm.edges), offset=min(bevel, min(size) * 0.45), segments=1,
                        profile=0.5, affect="EDGES", clamp_overlap=True)
        bm.normal_update()
        for which in faces:
            sign = -1 if which == "front" else 1
            face = max((f for f in bm.faces if f.normal.z * sign > 0.99), key=lambda f: f.calc_area())
            bmesh.ops.inset_region(bm, faces=[face], thickness=inset, depth=-depth, use_even_offset=True)
        return self._add(bm, at or cf())

    def cyl(self, length, radius, at=None, segments=16, bevel=BEVEL, radius2=None):
        """Cylinder along X (like a Roblox Cylinder part), centred."""
        bm = bmesh.new()
        bmesh.ops.create_cone(bm, cap_ends=True, segments=segments, radius1=radius,
                              radius2=radius if radius2 is None else radius2, depth=length)
        bmesh.ops.rotate(bm, verts=bm.verts, matrix=Matrix.Rotation(math.pi / 2, 3, "Y"))
        if bevel > 0:
            rims = [e for e in bm.edges if e.calc_face_angle(0) > math.radians(60)]
            bmesh.ops.bevel(bm, geom=rims, offset=min(bevel, radius * 0.3, length * 0.3), segments=1,
                            profile=0.5, affect="EDGES", clamp_overlap=True)
        return self._add(bm, at or cf())

    def ball(self, radius, at=None, segments=12, scale=(1, 1, 1)):
        bm = bmesh.new()
        bmesh.ops.create_uvsphere(bm, u_segments=segments, v_segments=max(6, segments // 2),
                                  radius=radius)
        bmesh.ops.scale(bm, vec=scale, verts=bm.verts)
        return self._add(bm, at or cf())

    def torus(self, major, minor, at=None, segments=20, sides=8):
        """Ring in the YZ plane (axis along X, like a wheel on a Cylinder part)."""
        bm = bmesh.new()
        rings = []
        for i in range(segments):
            a = 2 * math.pi * i / segments
            ring = []
            for j in range(sides):
                b = 2 * math.pi * j / sides
                r = major + minor * math.cos(b)
                ring.append(bm.verts.new((minor * math.sin(b), r * math.cos(a), r * math.sin(a))))
            rings.append(ring)
        for i in range(segments):
            a, b = rings[i], rings[(i + 1) % segments]
            for j in range(sides):
                k = (j + 1) % sides
                bm.faces.new((a[j], b[j], b[k], a[k]))
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        return self._add(bm, at or cf())

    def lathe(self, a, b, profile, segments=10, flat=(1.0, 1.0)):
        """Organic limb from point a to point b (studs).

        profile: [(t, radius)] with t from 0 (at a) to 1 (at b). The ends
        close to a point, so limbs come out rounded and seamless.
        flat: (x, z) squash of the cross-section (1, 1 = round).
        """
        a, b = Vector(a), Vector(b)
        axis = b - a
        length = axis.length
        up = axis.normalized()
        side = up.cross(Vector((0, 0, 1)))
        if side.length < 1e-4:
            side = up.cross(Vector((1, 0, 0)))
        side.normalize()
        fwd = side.cross(up)
        bm = bmesh.new()
        rings = []
        for t, r in profile:
            centre = a + axis * t
            ring = []
            for i in range(segments):
                ang = 2 * math.pi * i / segments
                p = centre + side * (math.cos(ang) * r * flat[0]) + fwd * (math.sin(ang) * r * flat[1])
                ring.append(bm.verts.new(p))
            rings.append(ring)
        tip0 = bm.verts.new(a - up * min(profile[0][1], length * 0.1))
        tip1 = bm.verts.new(b + up * min(profile[-1][1], length * 0.1))
        for i in range(len(rings) - 1):
            for j in range(segments):
                k = (j + 1) % segments
                bm.faces.new((rings[i][j], rings[i][k], rings[i + 1][k], rings[i + 1][j]))
        for j in range(segments):
            k = (j + 1) % segments
            bm.faces.new((tip0, rings[0][k], rings[0][j]))
            bm.faces.new((tip1, rings[-1][j], rings[-1][k]))
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        return self._add(bm, cf())

    def sheet(self, w, h, at=None, curl=0.0, wave=0.0, nx=6, ny=8, thickness=0.012, seed=0):
        """A sheet of paper w x h in the XY plane (front -Z), a hair thick.
        curl lifts the bottom-right corner off the surface (studs); wave adds
        a gentle ripple. Its edges are naturally soft, nothing to bevel."""
        import random
        rnd = random.Random(seed)
        bm = bmesh.new()
        grid = bmesh.ops.create_grid(bm, x_segments=nx, y_segments=ny, size=0.5)
        for v in grid["verts"]:
            u, t = v.co.x + 0.5, v.co.y + 0.5  # 0..1 across, 0..1 up
            lift = curl * max(0.0, u - 0.55) * max(0.0, 0.45 - t) * 8
            ripple = wave * math.sin(u * 5.1 + t * 3.3 + rnd.random()) * 0.5
            v.co = Vector(((u - 0.5) * w, (t - 0.5) * h, -(lift + ripple)))
        bmesh.ops.solidify(bm, geom=list(bm.faces), thickness=thickness)
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        return self._add(bm, at or cf())

    def pipe(self, points, radius, segments=10, joints=True):
        """Straight runs between points (studs), with a ball at each bend."""
        for p, q in zip(points, points[1:]):
            p, q = Vector(p), Vector(q)
            d = q - p
            if d.length < 1e-4:
                continue
            rot = Vector((1, 0, 0)).rotation_difference(d.normalized()).to_matrix().to_4x4()
            self.cyl(d.length, radius, Matrix.Translation((p + q) / 2) @ rot, segments)
        if joints:
            for p in points[1:-1]:
                self.ball(radius * 1.02, cf(*p), segments)
        return self

    def tris(self):
        return sum(len(f.verts) - 2 for f in self.bm.faces)


def _uv(bm):
    """Box-project UVs in studs (one tile per UV_STUDS)."""
    uv = bm.loops.layers.uv.verify()
    bm.normal_update()
    for face in bm.faces:
        n = face.normal
        axis = max(range(3), key=lambda i: abs(n[i]))
        for loop in face.loops:
            co = loop.vert.co
            u, v = {0: (co.z, co.y), 1: (co.x, co.z), 2: (co.x, co.y)}[axis]
            loop[uv].uv = (u / UV_STUDS, v / UV_STUDS)


_materials = {}


def _material(look, colour):
    """A named Principled material per look and colour (PBR-ready slots)."""
    key = (look, tuple(colour))
    if key in _materials:
        return _materials[key]
    _, _, rough, metal = LOOKS[look]
    mat = bpy.data.materials.new(f"SHIFT_{look}_{colour[0]}_{colour[1]}_{colour[2]}")
    if mat.node_tree is None:
        mat.use_nodes = True
    bsdf = next(n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    srgb = [c / 255 for c in colour]
    linear = [c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4 for c in srgb]
    bsdf.inputs["Base Color"].default_value = (*linear, 1.0)
    bsdf.inputs["Roughness"].default_value = rough
    bsdf.inputs["Metallic"].default_value = metal
    if look == "neon":
        bsdf.inputs["Emission Color"].default_value = (*linear, 1.0)
        bsdf.inputs["Emission Strength"].default_value = 3.0
    _materials[key] = mat
    return mat


def finish(meshes, name, budget=2000):
    """Convert to Blender metres, export exports/<name>.fbx and its .json.
    budget: Jason's per-prop triangle target (raise it only for big kit pieces)."""
    roblox_export.reset_scene()
    _materials.clear()
    to_blender = Matrix(((-STUD, 0, 0, 0), (0, 0, STUD, 0), (0, STUD, 0, 0), (0, 0, 0, 1)))
    # Jason's rule: origin at the bottom centre. Scripts model in the game's
    # own frame (where the Luau code puts the prop); shift everything so the
    # whole model's bounding box sits on the origin, and record the shift
    # ("origin") so the game can still place it in that frame.
    for m in meshes:
        bmesh.ops.remove_doubles(m.bm, verts=m.bm.verts, dist=1e-5)
        bmesh.ops.triangulate(m.bm, faces=m.bm.faces)
    every = [v.co for m in meshes for v in m.bm.verts]
    lo_all = Vector([min(c[i] for c in every) for i in range(3)])
    hi_all = Vector([max(c[i] for c in every) for i in range(3)])
    origin = Vector(((lo_all.x + hi_all.x) / 2, lo_all.y, (lo_all.z + hi_all.z) / 2))
    objects, parts = [], []
    total = 0
    for m in meshes:
        bm = m.bm
        bmesh.ops.translate(bm, vec=-origin, verts=bm.verts)
        _uv(bm)
        lo = Vector([min(v.co[i] for v in bm.verts) for i in range(3)])
        hi = Vector([max(v.co[i] for v in bm.verts) for i in range(3)])
        tris = len(bm.faces)
        total += tris
        parts.append({
            "name": m.name,
            "size": [round(hi[i] - lo[i], 4) for i in range(3)],
            "centre": [round((hi[i] + lo[i]) / 2, 4) for i in range(3)],
            "tris": tris,
            **m.look,
        })
        bmesh.ops.transform(bm, matrix=to_blender, verts=bm.verts)
        mesh = bpy.data.meshes.new(m.name)
        bm.to_mesh(mesh)
        bm.free()
        mesh.materials.append(_material(m.look_name, m.look["colour"]))
        mesh.shade_smooth()
        mesh.set_sharp_from_angle(angle=SHARP)
        obj = bpy.data.objects.new(m.name, mesh)
        bpy.context.collection.objects.link(obj)
        objects.append(obj)
    if total > roblox_export.MAX_TRIANGLES:
        raise ValueError(f"{name}: {total} triangles, limit is {roblox_export.MAX_TRIANGLES}")
    if total > budget:
        raise ValueError(f"{name}: {total} triangles, over its {budget} budget")
    roblox_export.export(objects, name)
    out = roblox_export.EXPORT_DIR / f"{name}.json"
    lo = [min(p["centre"][i] - p["size"][i] / 2 for p in parts) for i in range(3)]
    hi = [max(p["centre"][i] + p["size"][i] / 2 for p in parts) for i in range(3)]
    out.write_text(json.dumps({"name": name, "tris": total, "size": [round(hi[i] - lo[i], 4) for i in range(3)],
                               "origin": [round(origin[i], 4) for i in range(3)], "parts": parts}, indent=1))
    print(f"[kit] {name}: {len(parts)} meshes, {total} tris")
    return out
