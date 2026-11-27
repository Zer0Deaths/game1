"""Build every SHIFT model in one Blender run, then write the game's manifest.

Run from the game1 folder:

    & "C:\\Program Files\\Blender Foundation\\Blender 5.3\\blender.exe" --background --factory-startup --python-exit-code 1 --python blender\\build_all.py

Optional: names after "--" build only those scripts, e.g. "-- door fixture".

Each script in blender/scripts writes blender/exports/<name>.fbx (and, for
kit models, <name>.json with each mesh's size, centre and look). This then
writes src/shared/MeshManifest.luau from those .json files, which the game
uses to size, place and paint every MeshPart. Next step on the PC:
python tools/upload_assets.py (uploads the FBX files as Model assets).
"""

import json
import runpy
import sys
import traceback
from pathlib import Path

HERE = Path(__file__).resolve().parent
SCRIPTS = HERE / "scripts"
EXPORTS = HERE / "exports"
MANIFEST = HERE.parent / "src" / "shared" / "MeshManifest.luau"
SKIP = {"calibration_cube"}  # a measuring aid, not a game model


def num(v):
    return f"{v:.4f}".rstrip("0").rstrip(".") if v != int(v) else str(int(v))


def vec(v):
    return f"Vector3.new({num(v[0])}, {num(v[1])}, {num(v[2])})"


def write_manifest():
    models = []
    for path in sorted(EXPORTS.glob("*.json")):
        if (EXPORTS / f"{path.stem}.fbx").exists():
            models.append(json.loads(path.read_text()))
    lines = [
        "--!strict",
        "-- WRITTEN BY blender/build_all.py from the Blender exports: don't edit by hand.",
        "-- Every SHIFT model: its size and origin (studs) and, for each MeshPart,",
        "-- its size, centre (relative to the model's bottom-centre origin) and look.",
        "-- Meshes.luau uses this to place uploaded meshes exactly where the",
        "-- primitive parts they replace stand.",
        "return {",
    ]
    for m in models:
        lines.append(f"\t{m['name']} = {{")
        lines.append(f"\t\ttris = {m['tris']},")
        lines.append(f"\t\tsize = {vec(m['size'])},")
        lines.append(f"\t\torigin = {vec(m['origin'])}, -- where the origin sits in the frame the script modelled it in")
        lines.append("\t\tparts = {")
        for p in m["parts"]:
            c = p["colour"]
            lines.append(
                f"\t\t\t{{ name = \"{p['name']}\", size = {vec(p['size'])}, centre = {vec(p['centre'])}, "
                f"look = \"{p['look']}\", material = \"{p['material']}\", surface = \"{p['surface']}\", "
                f"colour = Color3.fromRGB({c[0]}, {c[1]}, {c[2]}), transparency = {num(p['transparency'])}, "
                f"shadow = {'true' if p['shadow'] else 'false'}, attach = \"{p['attach']}\" }},"
            )
        lines.append("\t\t},")
        if m.get("joints"):
            # Rigs (the Tenant): where each Motor6D sits, in the modelled frame.
            lines.append("\t\tjoints = {")
            for k in sorted(m["joints"]):
                lines.append(f"\t\t\t{k} = {vec(m['joints'][k])},")
            lines.append("\t\t},")
        lines.append("\t},")
    lines += ["}", ""]
    with open(MANIFEST, "w", newline="\n") as f:
        f.write("\n".join(lines))
    print(f"[build_all] wrote {MANIFEST.relative_to(HERE.parent)} ({len(models)} models)")
    return models


def main():
    only = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    scripts = [p for p in sorted(SCRIPTS.glob("*.py")) if p.stem not in SKIP and (not only or p.stem in only)]
    failed = []
    for script in scripts:
        print(f"[build_all] building {script.stem}")
        try:
            runpy.run_path(str(script), run_name="__main__")
        except Exception:
            traceback.print_exc()
            failed.append(script.stem)
    models = write_manifest()
    print("[build_all] triangles per model:")
    for m in models:
        print(f"  {m['name']:<24} {m['tris']:>6}")
    if failed:
        print(f"[build_all] FAILED: {', '.join(failed)}")
        sys.exit(1)
    print(f"[build_all] all {len(scripts)} built")


main()
