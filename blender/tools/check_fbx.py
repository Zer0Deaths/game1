"""Print what is really inside an FBX: units, node transforms, size, triangles.

    blender --background --factory-startup --python-exit-code 1 \
        --python blender/tools/check_fbx.py -- blender/exports/<name>.fbx
"""

import sys

from io_scene_fbx import parse_fbx

path = sys.argv[sys.argv.index("--") + 1]
root, version = parse_fbx.parse(path)


def children(elem, name):
    return [e for e in elem.elems if e.id == name]


def properties(elem):
    out = {}
    for block in children(elem, b"Properties70"):
        for p in block.elems:
            out[p.props[0].decode()] = list(p.props[4:])
    return out


print(f"[check] {path} (FBX {version})")
settings = properties(children(root, b"GlobalSettings")[0])
for key in ("UnitScaleFactor", "UpAxis", "UpAxisSign", "FrontAxis", "FrontAxisSign"):
    print(f"[check] {key} = {settings[key][0]}")

objects = children(root, b"Objects")[0]

for model in children(objects, b"Model"):
    props = properties(model)
    name = model.props[1].split(b"\x00")[0].decode()
    # A property that is missing is at its default (0 move/rotate, 1 scale).
    moved = {k: [round(v, 6) for v in props[k]] for k in
             ("Lcl Translation", "Lcl Rotation", "Lcl Scaling") if k in props}
    print(f"[check] node {name}: {moved or 'identity transform'}")

for geo in children(objects, b"Geometry"):
    name = geo.props[1].split(b"\x00")[0].decode()
    verts = children(geo, b"Vertices")[0].props[0]
    for axis, label in enumerate("XYZ"):
        values = verts[axis::3]
        print(f"[check] {name} {label}: {min(values):.4f} to {max(values):.4f}"
              f"  (size {max(values) - min(values):.4f})")
    # FBX marks the last index of each polygon as negative.
    indices = children(geo, b"PolygonVertexIndex")[0].props[0]
    polygons = sum(1 for i in indices if i < 0)
    print(f"[check] {name}: {len(indices) - 2 * polygons} triangles")

for video in children(objects, b"Video"):
    name = video.props[1].split(b"\x00")[0].decode()
    content = children(video, b"Content")
    size = len(content[0].props[0]) if content and content[0].props else 0
    print(f"[check] embedded texture {name}: {size} bytes")
