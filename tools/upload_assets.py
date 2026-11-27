"""Uploads every SHIFT texture, sound and clothing template to Roblox in one
go and writes the IDs into src/shared/AssetIds.luau (Rojo syncs it).

Run:  python tools/upload_assets.py
It asks for (or reads from the environment):
  ROBLOX_API_KEY   an Open Cloud API key from https://create.roblox.com/dashboard/credentials
                   with the "Assets" API, Read + Write, for your account
  ROBLOX_USER_ID   your Roblox user ID (the number in your profile URL)

The key is never saved. Already-uploaded files are skipped (their IDs are
kept in assets/uploaded.json), so it is safe to run again after adding or
changing files: a changed file is uploaded again.

Roblox stores images as Decals. Textures need the Decal's image ID; this
script looks it up when it can, and the game also resolves Decal IDs
itself on start (Surfaces.luau), so either kind works.
Audio uploads count against Roblox's monthly audio limit (higher once your
account is ID-verified).
"""
import getpass
import hashlib
import json
import os
import re
import sys
import time
import urllib.error
import urllib.request
import uuid

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, ".."))
ASSETS = os.path.join(ROOT, "assets")
LEDGER = os.path.join(ASSETS, "uploaded.json")
OUT = os.path.join(ROOT, "src", "shared", "AssetIds.luau")
API = "https://apis.roblox.com/assets/v1"

TEXTURE_MAPS = ("colour", "normal", "roughness", "metalness")


def sha(path):
    with open(path, "rb") as f:
        return hashlib.sha256(f.read()).hexdigest()[:16]


def request(method, url, key, body=None, headers=None):
    h = {"x-api-key": key}
    h.update(headers or {})
    req = urllib.request.Request(url, data=body, method=method, headers=h)
    try:
        with urllib.request.urlopen(req, timeout=120) as r:
            return json.loads(r.read() or b"{}")
    except urllib.error.HTTPError as e:
        raise RuntimeError(f"{e.code} {e.read()[:300]!r}") from None


def upload(path, kind, key, user_id):
    name = os.path.splitext(os.path.basename(path))[0]
    meta = {
        "assetType": kind,
        "displayName": f"SHIFT {name}"[:50],
        "description": "SHIFT game asset",
        "creationContext": {"creator": {"userId": str(user_id)}},
    }
    mime = {".png": "image/png", ".ogg": "audio/ogg", ".mp3": "audio/mpeg", ".wav": "audio/wav"}[os.path.splitext(path)[1].lower()]
    boundary = uuid.uuid4().hex
    with open(path, "rb") as f:
        data = f.read()
    body = (
        f"--{boundary}\r\nContent-Disposition: form-data; name=\"request\"\r\nContent-Type: application/json\r\n\r\n".encode()
        + json.dumps(meta).encode()
        + f"\r\n--{boundary}\r\nContent-Disposition: form-data; name=\"fileContent\"; filename=\"{os.path.basename(path)}\"\r\nContent-Type: {mime}\r\n\r\n".encode()
        + data
        + f"\r\n--{boundary}--\r\n".encode()
    )
    op = request("POST", f"{API}/assets", key, body, {"Content-Type": f"multipart/form-data; boundary={boundary}"})
    path_ = op.get("path") or f"operations/{op.get('operationId')}"
    for _ in range(60):
        if op.get("done"):
            break
        time.sleep(2)
        op = request("GET", f"{API}/{path_}", key)
    asset_id = (op.get("response") or {}).get("assetId")
    if not asset_id:
        raise RuntimeError(f"upload didn't finish: {op}")
    return str(asset_id)


def image_id_for(decal_id, key):
    """Best effort: the image behind a decal. The game can do this too."""
    try:
        info = request("GET", f"https://apis.roblox.com/asset-delivery-api/v1/assetId/{decal_id}", key)
        loc = info.get("location")
        if not loc:
            return None
        with urllib.request.urlopen(loc, timeout=60) as r:
            xml = r.read().decode("utf-8", "ignore")
        m = re.search(r"\?id=(\d+)", xml) or re.search(r"rbxassetid://(\d+)", xml)
        return m.group(1) if m else None
    except Exception:
        return None


def main():
    key = os.environ.get("ROBLOX_API_KEY") or getpass.getpass("Open Cloud API key (hidden): ").strip()
    user_id = os.environ.get("ROBLOX_USER_ID") or input("Your Roblox user ID: ").strip()
    ledger = json.load(open(LEDGER)) if os.path.exists(LEDGER) else {}

    jobs = []  # (relative path, Decal|Audio)
    for folder, kind in (("textures", "Decal"), ("clothing", "Decal"), ("sounds", "Audio")):
        d = os.path.join(ASSETS, folder)
        if os.path.isdir(d):
            for f in sorted(os.listdir(d)):
                if f.lower().endswith((".png", ".ogg", ".mp3", ".wav")):
                    jobs.append((f"{folder}/{f}", kind))

    failed = 0
    for rel, kind in jobs:
        full = os.path.join(ASSETS, rel)
        digest = sha(full)
        entry = ledger.get(rel)
        if entry and entry.get("sha") == digest:
            continue
        try:
            asset_id = upload(full, kind, key, user_id)
            image = image_id_for(asset_id, key) if kind == "Decal" else None
            # A decal ID the script couldn't turn into an image ID is marked
            # "decal:"; the game looks those up itself (Surfaces.image).
            ident = image or (f"decal:{asset_id}" if kind == "Decal" else asset_id)
            ledger[rel] = {"sha": digest, "id": ident, "decal": asset_id if kind == "Decal" else None}
            print(f"uploaded {rel} -> {ledger[rel]['id']}")
        except Exception as e:
            failed += 1
            print(f"! {rel}: {e}")
        with open(LEDGER, "w") as f:
            json.dump(ledger, f, indent=1, sort_keys=True)

    write_luau(ledger)
    print(f"done, {failed} failed. Wrote {os.path.relpath(OUT, ROOT)}." + (" Run again to retry the failures." if failed else ""))


def write_luau(ledger):
    textures, sounds, clothing = {}, {}, {}
    for rel, entry in ledger.items():
        folder, file = rel.split("/", 1)
        stem = os.path.splitext(file)[0]
        if folder == "textures":
            set_name, _, m = stem.rpartition("_")
            if m in TEXTURE_MAPS:
                textures.setdefault(set_name, {})[m] = entry["id"]
        elif folder == "sounds":
            sounds[stem] = entry["id"]
        elif folder == "clothing":
            clothing[stem.replace("suit_", "")] = entry["id"]
    lines = [
        "--!strict",
        "-- Uploaded asset IDs. WRITTEN BY tools/upload_assets.py: run that",
        "-- instead of editing by hand (hand edits are fine, but get overwritten).",
        "-- Empty means not uploaded yet; the game falls back gracefully.",
        "return {",
        "\ttextures = {",
    ]
    for s in sorted(textures):
        maps = ", ".join(f'{m} = "{textures[s].get(m, "")}"' for m in TEXTURE_MAPS)
        lines.append(f"\t\t{s} = {{ {maps} }},")
    lines += ["\t},", "\tsounds = {"]
    for k in sorted(sounds):
        lines.append(f'\t\t{k} = "{sounds[k]}",')
    lines += ["\t},", "\tclothing = {"]
    for k in sorted(clothing):
        lines.append(f'\t\t{k} = "{clothing[k]}",')
    lines += ["\t},", "}", ""]
    with open(OUT, "w", newline="\n") as f:
        f.write("\n".join(lines))


if __name__ == "__main__":
    if "--write-only" in sys.argv:
        write_luau(json.load(open(LEDGER)) if os.path.exists(LEDGER) else {})
    else:
        main()
