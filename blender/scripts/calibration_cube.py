"""1 m reference cube. In Studio it must measure 3.571 studs on every side."""

import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent / "lib"))

import bpy
import roblox_export

roblox_export.reset_scene()

# Origin at the bottom centre: build the cube 0.5 m up, then bake that offset.
bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0.5))
cube = bpy.context.active_object
cube.name = cube.data.name = "calibration_cube"

roblox_export.export([cube], "calibration_cube")
