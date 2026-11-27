"""Swaps SHIFT's generated assets for real CC0 recordings and scans.

Run on a PC with normal internet (the cloud build box can't reach these
sites):   python tools/fetch_cc0.py          (needs Pillow and numpy)
Only one half:  python tools/fetch_cc0.py sounds   (or: textures)
If the sound download fails, download Impact Sounds by hand from
kenney.nl into your Downloads folder and run the sounds line again; the
script finds the zip there (or pass its path after "sounds").

1. Sounds: downloads Kenney's "Impact Sounds" pack (CC0, kenney.nl) and
   copies the real recorded footsteps and impacts into assets/sounds/
   under SHIFT's sound keys (STEP_CARPET, STEP_TILE, STEP_METAL, DROP...).
2. Textures: downloads 1K PNG material sets from ambientCG (CC0) for the
   surfaces listed in TEXTURES below, resizes them to 1024x1024 and saves
   them over assets/textures/<set>_<map>.png. Each scanned colour map is
   re-graded to the mean colour of SHIFT's own version, so the palette
   (mustard carpet, cold ward tile...) stays the same with real detail.
   Sets not listed keep the generated version (wallpaper, the Tenant).

Everything fetched is CC0: free to use, no credit needed. Sources are
written to assets/CREDITS.txt anyway.
After this, run tools/upload_assets.py to upload the lot in one go.
"""
import http.cookiejar
import io
import json
import os
import re
import sys
import urllib.parse
import urllib.request
import zipfile

import numpy as np
from PIL import Image

ROOT = os.path.join(os.path.dirname(__file__), "..", "assets")
TEX = os.path.join(ROOT, "textures")
SND = os.path.join(ROOT, "sounds")
UA = {"User-Agent": "Mozilla/5.0 (asset fetch script)"}

# set -> ambientCG search words (first popular match wins) or an exact asset id.
TEXTURES = {
    "carpet": "carpet",
    "concrete": "concrete",
    "ceiling": "office ceiling",
    "ward_tile": "tiles",
    "ward_floor": "terrazzo",
    "steel_plate": "diamond plate",
    "painted_metal": "painted metal",
    "brushed_metal": "metal brushed",
    "rust": "rust",
    "wood": "wood",
    "fabric": "fabric",
    "cardboard": "cardboard",
    "aged_plastic": "plastic",
    "rubber": "rubber",
    "suit_fabric": "fabric",
}

# SHIFT sound key -> Kenney Impact Sounds file name (without .ogg).
SOUNDS = {
    "STEP_CARPET": "footstep_carpet_000",
    "STEP_CARPET_2": "footstep_carpet_001",
    "STEP_CARPET_3": "footstep_carpet_002",
    "STEP_TILE": "footstep_concrete_000",
    "STEP_TILE_2": "footstep_concrete_001",
    "STEP_TILE_3": "footstep_concrete_002",
    "STEP_METAL": "impactPlate_light_000",
    "STEP_METAL_2": "impactPlate_light_001",
    "STEP_METAL_3": "impactPlate_light_002",
    "DROP": "impactSoft_heavy_000",
    "PICKUP": "impactSoft_medium_001",
    "TENANT_STEP": "impactWood_heavy_002",
}

credits = []


# One opener with a cookie jar: Kenney only hands out its download link to
# a browser session that has loaded the asset page first.
OPENER = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(http.cookiejar.CookieJar()))


def get(url, referer=None):
    headers = dict(UA)
    if referer:
        headers["Referer"] = referer
    with OPENER.open(urllib.request.Request(url, headers=headers), timeout=60) as r:
        return r.read()


def kenney_link(page, page_url):
    """Kenney's current flow: the page has data-download-id="..."; with the
    page's session cookie, /download-link/<id> returns JSON {"url": signed zip}."""
    m = re.search(r"""data-download-id=["']([^"']+)["']""", page)
    if not m:
        return None
    data = json.loads(get(f"https://kenney.nl/download-link/{m.group(1)}", referer=page_url))
    return data.get("url")


# Pages that link the Impact Sounds zip.
SOUND_PAGES = (
    "https://kenney.nl/assets/impact-sounds",
)


def zip_links(page, base):
    """Every .zip URL on a page, wherever it sits (href, data-*, JSON, JS)."""
    page = page.replace("\\/", "/").replace("&amp;", "&")
    found = []
    for m in re.finditer(r"""(https?://[^\s"'<>()]+?\.zip|/[^\s"'<>()]+?\.zip)""", page, re.I):
        url = urllib.parse.urljoin(base, m.group(1))
        if url not in found:
            found.append(url)
    # Prefer links that name the pack.
    found.sort(key=lambda u: 0 if "impact" in u.lower() else 1)
    return found


def local_zip():
    """A copy you downloaded by hand: a path given after 'sounds', or the usual places."""
    for a in sys.argv[2:]:
        if a.lower().endswith(".zip") and os.path.exists(a):
            return a
    home = os.path.expanduser("~")
    for folder in (os.path.join(home, "Downloads"), ROOT, os.path.dirname(__file__)):
        if os.path.isdir(folder):
            for n in sorted(os.listdir(folder)):
                low = n.lower()
                if low.endswith(".zip") and "impact" in low:
                    return os.path.join(folder, n)
    return None


def sound_zip():
    path = local_zip()
    if path:
        print("using", path)
        with open(path, "rb") as f:
            return zipfile.ZipFile(io.BytesIO(f.read()))
    for page_url in SOUND_PAGES:
        try:
            page = get(page_url).decode("utf-8", "ignore")
        except Exception as e:
            print(f"! {page_url}: {e}")
            continue
        links = []
        if "kenney.nl" in page_url:
            try:
                signed = kenney_link(page, page_url)
                if signed:
                    links.append(signed)
            except Exception as e:
                print(f"! Kenney download-link step failed: {e}")
        links += [u for u in zip_links(page, page_url) if u not in links]
        if not links:
            dump = os.path.join(os.path.dirname(__file__), "last_sound_page.html")
            with open(dump, "w", encoding="utf-8") as f:
                f.write(page)
            hints = sorted(set(re.findall(r"""[^\s"'<>]*download[^\s"'<>]*""", page, re.I)))[:8]
            print(f"! no .zip link on {page_url} (page saved to {dump}); download-ish bits: {hints}")
            continue
        for url in links:
            try:
                print("downloading", url)
                return zipfile.ZipFile(io.BytesIO(get(url, referer=page_url)))
            except Exception as e:
                print(f"! {url}: {e}")
    return None


def fetch_sounds():
    z = sound_zip()
    if not z:
        print("! couldn't get Impact Sounds. Download it by hand from https://kenney.nl/assets/impact-sounds")
        print("  into your Downloads folder, then run: python tools/fetch_cc0.py sounds")
        return
    names = {os.path.splitext(os.path.basename(n))[0].lower(): n for n in z.namelist() if n.lower().endswith(".ogg")}
    if not names:
        print("! that zip has no .ogg files in it")
        return
    os.makedirs(SND, exist_ok=True)
    got = 0
    for key, want in SOUNDS.items():
        src = names.get(want.lower())
        if not src:
            print(f"! {want}.ogg not in the pack, {key} keeps its old file")
            continue
        with open(os.path.join(SND, f"{key}.ogg"), "wb") as f:
            f.write(z.read(src))
        got += 1
        print(f"  {key} <- {want}.ogg")
    print(f"{got} of {len(SOUNDS)} sounds swapped in")
    if got:
        credits.append("Sounds: Kenney 'Impact Sounds' (https://kenney.nl/assets/impact-sounds), CC0 1.0")


def regrade(scan, reference_path):
    """Shift the scan's per-channel mean/spread towards SHIFT's own colour map."""
    if not os.path.exists(reference_path):
        return scan
    ref = np.asarray(Image.open(reference_path).convert("RGB"), float)
    s = np.asarray(scan, float)
    out = (s - s.mean((0, 1))) / (s.std((0, 1)) + 1e-6) * ref.std((0, 1)) * 0.9 + ref.mean((0, 1))
    return Image.fromarray(np.clip(out, 0, 255).astype(np.uint8))


def find_asset(query):
    if re.fullmatch(r"[A-Za-z]+\d{3}[A-Z]?", query):
        q = f"id={query}"
    else:
        q = "q=" + urllib.parse.quote(query) + "&type=Material&sort=Popular&limit=5"
    data = json.loads(get(f"https://ambientcg.com/api/v2/full_json?{q}&include=downloadData"))
    for asset in data.get("foundAssets", []):
        for cat in asset.get("downloadFolders", {}).values():
            for group in cat.get("downloadFiletypeCategories", {}).values():
                for d in group.get("downloads", []):
                    if d.get("attribute") == "1K-PNG":
                        return asset["assetId"], d["downloadLink"]
    return None, None


def fetch_textures():
    for set_name, query in TEXTURES.items():
        try:
            asset_id, link = find_asset(query)
        except Exception as e:  # keep going: one bad set shouldn't stop the rest
            print(f"! {set_name}: search failed ({e})")
            continue
        if not link:
            print(f"! {set_name}: nothing found for '{query}', keeping the generated set")
            continue
        print(f"{set_name} <- ambientCG {asset_id}")
        z = zipfile.ZipFile(io.BytesIO(get(link)))
        maps = {}
        for n in z.namelist():
            low = n.lower()
            for key, tag in (("colour", "_color."), ("normal", "_normalgl."), ("roughness", "_roughness."), ("metalness", "_metalness.")):
                if tag in low:
                    maps[key] = n
        if "colour" not in maps or "normal" not in maps:
            print(f"! {set_name}: zip had no colour/normal map, skipped")
            continue
        for key, n in maps.items():
            img = Image.open(io.BytesIO(z.read(n)))
            img = img.convert("L" if key in ("roughness", "metalness") else "RGB").resize((1024, 1024), Image.LANCZOS)
            path = os.path.join(TEX, f"{set_name}_{key}.png")
            if key == "colour":
                img = regrade(img, path)
            img.save(path, optimize=True)
        credits.append(f"Texture {set_name}: ambientCG {asset_id} (https://ambientcg.com/a/{asset_id}), CC0 1.0")


if __name__ == "__main__":
    which = sys.argv[1:] or ["sounds", "textures"]
    if "sounds" in which:
        fetch_sounds()
    if "textures" in which:
        fetch_textures()
    with open(os.path.join(ROOT, "CREDITS.txt"), "a", encoding="utf-8") as f:
        for line in credits:
            f.write(line + "\n")
    print("done. Next: python tools/upload_assets.py")
