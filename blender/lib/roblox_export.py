"""Shared export step for every SHIFT prop. See ../EXPORT_SETTINGS.md.

Model in metres, then call export(objects, name). Do not change the settings
per prop: if the scale ever needs changing, change it here and rebuild all.
"""

from pathlib import Path

import bpy
from mathutils import Matrix

# Roblox defines 1 stud as 28 cm.
STUDS_PER_METRE = 1 / 0.28
MAX_TRIANGLES = 20_000

EXPORT_DIR = Path(__file__).resolve().parent.parent / "exports"

FBX_SETTINGS = dict(
    use_selection=True,
    object_types={"MESH"},
    global_scale=1.0,
    apply_unit_scale=True,
    apply_scale_options="FBX_SCALE_UNITS",
    axis_forward="Z",  # Blender front (-Y) becomes Roblox front (-Z)
    axis_up="Y",
    use_space_transform=True,
    bake_space_transform=True,  # axis change goes into the vertices, not the node
    use_mesh_modifiers=True,
    mesh_smooth_type="FACE",
    add_leaf_bones=False,
    bake_anim=False,
    path_mode="COPY",
    embed_textures=True,
)


def reset_scene():
    """Start from an empty file with metric units."""
    bpy.ops.wm.read_factory_settings(use_empty=True)
    units = bpy.context.scene.unit_settings
    units.system = "METRIC"
    units.scale_length = 1.0


def export(objects, name):
    """Apply transforms, convert metres to studs and write exports/<name>.fbx.

    Each object's origin stays at the world origin, so build props with their
    bottom centre at (0, 0, 0).
    """
    EXPORT_DIR.mkdir(exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")

    for obj in objects:
        bpy.context.view_layer.update()
        # Bake location/rotation/scale into the mesh, then convert to studs.
        obj.data.transform(Matrix.Scale(STUDS_PER_METRE, 4) @ obj.matrix_world)
        obj.matrix_world = Matrix.Identity(4)
        obj.data.update()
        obj.select_set(True)

        obj.data.calc_loop_triangles()
        tris = len(obj.data.loop_triangles)
        if tris > MAX_TRIANGLES:
            raise ValueError(f"{obj.name}: {tris} triangles, limit is {MAX_TRIANGLES}")
        size = " x ".join(f"{d:.3f}" for d in _size(obj))
        print(f"[export] {obj.name}: {tris} tris, {size} studs (X, Y, Z in Blender axes)")

    path = EXPORT_DIR / f"{name}.fbx"
    bpy.ops.export_scene.fbx(filepath=str(path), **FBX_SETTINGS)
    print(f"[export] wrote {path}")
    return path


def _size(obj):
    cos = [v.co for v in obj.data.vertices]
    return [max(c[i] for c in cos) - min(c[i] for c in cos) for i in range(3)]
