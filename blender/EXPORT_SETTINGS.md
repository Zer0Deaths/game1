# Blender to Roblox export settings (SHIFT)

Use these for every prop. They live in code in `lib/roblox_export.py`, so a
prop script only calls `roblox_export.export(objects, name)`.

## Status

| Check | Result |
|---|---|
| Blender | 5.3.0 |
| Headless script to FBX | Works |
| FBX contents (units, size, pivot, axes) | Checked with `tools/check_fbx.py` |
| Measured in Roblox Studio | **Not yet.** Import `calibration_cube.fbx` and confirm 3.571 studs, then update this row |

## Scale

- Roblox: 1 stud = 0.28 m ([units](https://create.roblox.com/docs/physics/units)).
- So 1 m = **3.5714286 studs**.
- Model in real metres. The export multiplies the vertices by 1 / 0.28.
- In Studio's importer, **Scale Unit = Studs** (the default). Never pick
  Meter: the scale is already converted, and Roblox has used a 20 studs per
  metre ratio for that option.

| Blender | Studio |
|---|---|
| 0.28 m | 1 stud |
| 1 m | 3.571 studs |
| 2.1 m | 7.5 studs |

## FBX export settings

| Setting (Blender UI name) | Python argument | Value |
|---|---|---|
| Limit to Selected Objects | `use_selection` | on |
| Object Types | `object_types` | Mesh only |
| Scale | `global_scale` | 1.0 |
| Apply Unit | `apply_unit_scale` | on |
| Apply Scalings | `apply_scale_options` | FBX Units Scale (`FBX_SCALE_UNITS`) |
| Forward | `axis_forward` | Z Forward |
| Up | `axis_up` | Y Up |
| Use Space Transform | `use_space_transform` | on |
| Apply Transform | `bake_space_transform` | on |
| Apply Modifiers | `use_mesh_modifiers` | on |
| Smoothing | `mesh_smooth_type` | Face |
| Add Leaf Bones | `add_leaf_bones` | off |
| Bake Animation | `bake_anim` | off |
| Path Mode | `path_mode` | Copy |
| Embed Textures | `embed_textures` | on |

Scene units: Metric, Unit Scale 1.0.

These suit static props. Rigged or animated models need their own settings.

## Build a prop

Run from the `game1` folder. `blender` is not on PATH, so use the full path.

```powershell
& "C:\Program Files\Blender Foundation\Blender 5.3\blender.exe" --background --factory-startup --python-exit-code 1 --python blender\scripts\shift_door.py
```

`--python-exit-code 1` matters: without it Blender reports success even when
the script crashes.

Check what went into the file:

```powershell
& "C:\Program Files\Blender Foundation\Blender 5.3\blender.exe" --background --factory-startup --python-exit-code 1 --python blender\tools\check_fbx.py -- blender\exports\shift_door.fbx
```

A correct file shows `UnitScaleFactor = 100.0`, `UpAxis = 1`, every node at
`identity transform`, and sizes in studs.

## Rules for every prop

- Under 20,000 triangles per mesh; aim under 2,000 for props.
- Real-world scale in metres.
- Origin at the bottom centre: build the prop around (0, 0, 0), front facing -Y.
- Transforms applied on export (the export step does this).
- One script per prop in `scripts/`, same name as its FBX in `exports/`.

## Import into Studio

1. **File > Import** (also "Import 3D" on the toolbar) and pick the FBX from
   `blender\exports\`.
2. In the preview window set:
   - File General: Import Only As Model **on**, Anchored **on**,
     Set Pivot to Scene Origin **on**, Add to Workspace **on**,
     Insert Using Scene Position **off**
   - File Geometry: Scale Unit **Studs**, Merge Meshes **off**
   - File Transform: World Forward **Front**, World Up **Top**
3. Compare **File Dimensions** with the table below. If they differ, cancel.
4. Click **Import**. This uploads the meshes and textures to your Roblox account.

| FBX | Size in studs (X, Y, Z) | Meshes |
|---|---|---|
| `calibration_cube.fbx` | 3.571, 3.571, 3.571 | 1 |
| `shift_door.fbx` | 3.736, 7.761, 0.643 | `Door_Frame`, `Door_Slab` |

If a door part arrives untextured, add a **SurfaceAppearance** to that
MeshPart and set ColorMap, MetalnessMap and RoughnessMap to the three PNGs in
`exports\textures\`.
