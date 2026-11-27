"""SHIFT door: 0.9 m x 2.1 m painted metal slab in a steel frame.

Two meshes (Door_Frame, Door_Slab) so the slab can swing later. Both have
their origin at the bottom centre of the doorway. Front faces -Y in Blender.
All sizes are in metres.
"""

import math
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent / "lib"))

import bmesh
import bpy
import numpy as np
import roblox_export
from mathutils import Matrix, Vector

SLAB_W, SLAB_H, SLAB_T = 0.9, 2.1, 0.044
FRONT = -SLAB_T / 2  # y of the slab's front face

GAP = 0.003  # clearance between slab and frame
JAMB_W, FRAME_D = 0.07, 0.18

PANEL_HALF_W, PANEL_Z0, PANEL_Z1 = 0.31, 0.36, 1.94
PANEL_DEPTH = PANEL_SLOPE = 0.012

PLATE_HALF_W, PLATE_Z0, PLATE_Z1, PLATE_T = 0.41, 0.025, 0.225, 0.003

HANDLE_X, HANDLE_Z = 0.38, 1.02  # on the right-hand stile, seen from the front

# Texture atlas: paint on the left three quarters, bare steel on the right.
PAINT, STEEL = (0.01, 0.73), (0.77, 0.99)
ATLAS_METRES_W, ATLAS_METRES_H = 1.2, 2.3


def bevel(bm, edges, width, segments):
    bmesh.ops.bevel(bm, geom=list(edges), offset=width, segments=segments,
                    profile=0.5, affect="EDGES", clamp_overlap=True)


def frame_mesh():
    """A U-shaped profile (two jambs and a head) pushed through the wall depth."""
    inner = SLAB_W / 2 + GAP
    outer = inner + JAMB_W
    inner_h = SLAB_H + GAP
    outer_h = inner_h + JAMB_W
    profile = [(-outer, 0), (-inner, 0), (-inner, inner_h), (inner, inner_h),
               (inner, 0), (outer, 0), (outer, outer_h), (-outer, outer_h)]

    bm = bmesh.new()
    face = bm.faces.new([bm.verts.new((x, -FRAME_D / 2, z)) for x, z in profile])
    extruded = bmesh.ops.extrude_face_region(bm, geom=[face])
    back = [v for v in extruded["geom"] if isinstance(v, bmesh.types.BMVert)]
    bmesh.ops.translate(bm, verts=back, vec=(0, FRAME_D, 0))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bevel(bm, bm.edges, 0.008, 2)
    return bm


def slab_body():
    """Box whose front face is a border around a sloped, recessed panel."""
    bm = bmesh.new()

    def ring(half_w, z0, z1, y):
        points = [(-half_w, z0), (half_w, z0), (half_w, z1), (-half_w, z1)]
        return [bm.verts.new((x, y, z)) for x, z in points]

    front = ring(SLAB_W / 2, 0, SLAB_H, FRONT)
    back = ring(SLAB_W / 2, 0, SLAB_H, -FRONT)
    opening = ring(PANEL_HALF_W, PANEL_Z0, PANEL_Z1, FRONT)
    floor = ring(PANEL_HALF_W - PANEL_SLOPE, PANEL_Z0 + PANEL_SLOPE,
                 PANEL_Z1 - PANEL_SLOPE, FRONT + PANEL_DEPTH)

    for i in range(4):
        j = (i + 1) % 4
        bm.faces.new((front[i], front[j], opening[j], opening[i]))
        bm.faces.new((opening[i], opening[j], floor[j], floor[i]))
        bm.faces.new((front[j], front[i], back[i], back[j]))
    bm.faces.new(floor)
    bm.faces.new(back[::-1])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.edges.ensure_lookup_table()

    def loop_edges(verts):
        return [bm.edges.get((verts[i], verts[(i + 1) % 4])) for i in range(4)]

    outer = loop_edges(front) + loop_edges(back)
    outer += [bm.edges.get((front[i], back[i])) for i in range(4)]
    # One bevel call per width; the panel edges are found again by position.
    panel_keys = [tuple(v.co.copy() for v in e.verts)
                  for e in loop_edges(opening) + loop_edges(floor)]
    bevel(bm, outer, 0.005, 2)

    def find(co):
        return min(bm.verts, key=lambda v: (v.co - co).length_squared)

    panel = [bm.edges.get((find(a), find(b))) for a, b in panel_keys]
    bevel(bm, panel, 0.003, 2)
    return bm


def box(x0, x1, y0, y1, z0, z1, width, segments):
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    bmesh.ops.scale(bm, verts=bm.verts, vec=(x1 - x0, y1 - y0, z1 - z0))
    bmesh.ops.translate(bm, verts=bm.verts,
                        vec=((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2))
    bevel(bm, bm.edges, width, segments)
    return bm


def disc(radius, y0, y1, segments, width):
    """Cylinder pointing out of the door at the handle position."""
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, segments=segments, radius1=radius,
                          radius2=radius, depth=y1 - y0)
    bmesh.ops.rotate(bm, verts=bm.verts, matrix=Matrix.Rotation(math.pi / 2, 3, "X"))
    bmesh.ops.translate(bm, verts=bm.verts, vec=(HANDLE_X, (y0 + y1) / 2, HANDLE_Z))
    if width:
        rims = [e for e in bm.edges if e.calc_face_angle(0) > math.radians(60)]
        bevel(bm, rims, width, 1)
    return bm


def hardware_meshes():
    sink = 0.0005  # parts overlap slightly so no gap shows between them
    plate = box(-PLATE_HALF_W, PLATE_HALF_W, FRONT - PLATE_T, FRONT + sink,
                PLATE_Z0, PLATE_Z1, 0.0012, 1)
    rose = disc(0.027, FRONT - 0.009, FRONT + sink, 20, 0.002)
    neck = disc(0.010, FRONT - 0.046, FRONT - 0.008, 12, 0)
    lever = box(HANDLE_X - 0.115, HANDLE_X + 0.013, FRONT - 0.060, FRONT - 0.042,
                HANDLE_Z - 0.011, HANDLE_Z + 0.011, 0.007, 2)
    return [plate, rose, neck, lever]


def map_uvs(bm, zone):
    """Flat-project each face into its zone of the atlas."""
    uv = bm.loops.layers.uv.verify()
    u0, u1 = zone
    bm.normal_update()
    for face in bm.faces:
        axis = max(range(3), key=lambda i: abs(face.normal[i]))
        for loop in face.loops:
            co = loop.vert.co
            across, up = {0: (co.y, co.z), 1: (co.x, co.z), 2: (co.x, co.y)}[axis]
            u = u0 + (across / ATLAS_METRES_W + 0.5) * (u1 - u0)
            v = (up + 0.1) / ATLAS_METRES_H
            loop[uv].uv = (u, v)


def make_object(name, parts, material):
    """Merge [(bmesh, atlas zone)] into one smooth-shaded, triangulated object."""
    merged = bmesh.new()
    for bm, zone in parts:
        map_uvs(bm, zone)
        temp = bpy.data.meshes.new("temp")
        bm.to_mesh(temp)
        merged.from_mesh(temp)
        bpy.data.meshes.remove(temp)
        bm.free()
    bmesh.ops.triangulate(merged, faces=merged.faces)

    open_edges = sum(1 for e in merged.edges if not e.is_manifold)
    if open_edges:
        raise ValueError(f"{name}: {open_edges} open edges, mesh is not watertight")

    mesh = bpy.data.meshes.new(name)
    merged.to_mesh(mesh)
    merged.free()
    mesh.materials.append(material)
    mesh.shade_smooth()
    mesh.set_sharp_from_angle(angle=math.radians(50))

    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    # Keeps the large flat faces looking flat next to the rounded bevels.
    normals = obj.modifiers.new("WeightedNormal", "WEIGHTED_NORMAL")
    normals.keep_sharp = True
    return obj


def save_texture(name, rgb, non_color):
    height, width = rgb.shape[:2]
    image = bpy.data.images.new(name, width, height, alpha=False)
    if non_color:
        image.colorspace_settings.name = "Non-Color"
    rgba = np.ones((height, width, 4), dtype=np.float32)
    rgba[..., :3] = np.clip(rgb, 0, 1)
    image.pixels.foreach_set(rgba.ravel())
    folder = roblox_export.EXPORT_DIR / "textures"
    folder.mkdir(parents=True, exist_ok=True)
    image.filepath_raw = str(folder / f"{name}.png")
    image.file_format = "PNG"
    image.save()
    return image


def painted_metal_material(size=512):
    rng = np.random.default_rng(7)  # fixed seed: every build looks the same
    split = int(size * 0.75)  # first steel column

    def noise(cells):
        """Smooth value noise in -1..1."""
        grid = rng.uniform(-1, 1, (cells + 1, cells + 1))
        t = np.linspace(0, cells, size, endpoint=False)
        i, f = t.astype(int), t % 1
        rows = grid[i] * (1 - f)[:, None] + grid[i + 1] * f[:, None]
        return rows[:, i] * (1 - f) + rows[:, i + 1] * f

    mottle = noise(8) * 0.025 + noise(64) * 0.012
    # Row 0 is the bottom of the door: darken it a little, like scuffed paint.
    grime = np.clip(1 - np.arange(size) / (size * 0.25), 0, 1)[:, None] * 0.08

    color = np.array([0.33, 0.39, 0.35]) * (1 + mottle * 2 - grime)[..., None]
    brushed = rng.uniform(-0.04, 0.04, (size, 1))  # horizontal brush lines
    color[:, split:] = (np.array([0.56, 0.57, 0.58]) + brushed[..., None]
                        + noise(32)[:, split:, None] * 0.02)

    metalness = np.full((size, size), 0.1)
    metalness[:, split:] = 1.0
    roughness = 0.5 + noise(16) * 0.08 + grime
    roughness[:, split:] = 0.36 + brushed

    def grey(channel):
        return np.repeat(channel[..., None], 3, axis=2)

    maps = {
        "Base Color": save_texture("shift_door_color", color, False),
        "Metallic": save_texture("shift_door_metalness", grey(metalness), True),
        "Roughness": save_texture("shift_door_roughness", grey(roughness), True),
    }

    material = bpy.data.materials.new("Door_PaintedMetal")
    if material.node_tree is None:
        material.use_nodes = True
    tree = material.node_tree
    shader = next(n for n in tree.nodes if n.type == "BSDF_PRINCIPLED")
    for socket, image in maps.items():
        node = tree.nodes.new("ShaderNodeTexImage")
        node.image = image
        tree.links.new(node.outputs["Color"], shader.inputs[socket])
    return material


roblox_export.reset_scene()
material = painted_metal_material()
frame = make_object("Door_Frame", [(frame_mesh(), PAINT)], material)
slab = make_object(
    "Door_Slab",
    [(slab_body(), PAINT)] + [(bm, STEEL) for bm in hardware_meshes()],
    material,
)

total = len(frame.data.polygons) + len(slab.data.polygons)
if total >= 2000:
    raise ValueError(f"door is {total} triangles, budget is under 2000")
print(f"[door] total triangles: {total}")

roblox_export.export([frame, slab], "shift_door")
