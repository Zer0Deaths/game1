"""Generates SHIFT's grime decals (original, procedural, CC0).

Run:  python tools/make_decals.py      (needs numpy and Pillow)

Writes assets/decals/<name>.png, 512x512 RGBA (transparent where clean).
They are laid over the PBR surfaces as Decals to make rooms look lived in:
  water_stain   brown tide-mark ring for ceiling tiles
  drip_stain    dark runs down a wall from a leak above
  floor_stain   a dark blotchy spill on carpet or tile
  wear_path     soft darkening where feet have worn a path (stretch it)
  corner_grime  dirt banked up at the bottom of a wall or in a corner
  scuff         shoe and trolley scuffs along the base of a wall
  peel          wallpaper peeling off along its top edge
  wall_grime    faint smudges and hand marks at body height
  rust_streak   orange-brown runs under pipes, valves and bolts
  oil_stain     a dark, slightly glossy pool for plant-room floors
Palette: yellowed beige, dirty brown and grey, nothing saturated.
"""
import os
import numpy as np
from PIL import Image

N = 512
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "decals")
yy, xx = np.mgrid[0:N, 0:N] / N


class Gen:
    def __init__(self, name):
        self.rng = np.random.default_rng(sum(map(ord, name)) * 104729 + 20261127)

    def noise(self, beta, lo=1.0, hi=None, stretch=(1.0, 1.0)):
        white = self.rng.standard_normal((N, N))
        f = np.fft.fftfreq(N) * N
        fx, fy = np.meshgrid(f, f)
        r = np.sqrt((fx * stretch[0]) ** 2 + (fy * stretch[1]) ** 2)
        r[0, 0] = 1
        amp = 1.0 / r**beta
        amp[r < lo] = 0
        if hi:
            amp[r > hi] = 0
        out = np.real(np.fft.ifft2(np.fft.fft2(white) * amp))
        out -= out.min()
        return out / max(out.max(), 1e-9)


def smooth(t, a, b):
    t = np.clip((t - a) / (b - a), 0, 1)
    return t * t * (3 - 2 * t)


def save(name, rgb, alpha):
    os.makedirs(OUT, exist_ok=True)
    rgb = np.broadcast_to(np.asarray(rgb, float), (N, N, 3)) if np.ndim(rgb) == 1 else rgb
    img = np.dstack([np.clip(rgb, 0, 1), np.clip(alpha, 0, 1)])
    # Fade every edge to nothing so a decal never shows a hard border.
    border = smooth(np.minimum(np.minimum(xx, 1 - xx), np.minimum(yy, 1 - yy)), 0.0, 0.06)
    img[..., 3] *= border
    Image.fromarray((img * 255).astype(np.uint8), "RGBA").save(os.path.join(OUT, f"{name}.png"), optimize=True)
    print("wrote", name)


def colour(base, shade):
    return np.asarray(base, float)[None, None, :] * shade[..., None]


def radial(cx=0.5, cy=0.5, sx=1.0, sy=1.0):
    return np.sqrt(((xx - cx) / sx) ** 2 + ((yy - cy) / sy) ** 2)


def water_stain():
    g = Gen("water_stain")
    wobble = g.noise(1.6, 2, 20)
    r = radial() + 0.16 * (wobble - 0.5)
    inside = 1 - smooth(r, 0.30, 0.42)
    tide = np.exp(-((r - 0.40) / 0.018) ** 2)  # the dark ring where the water dried
    tide2 = np.exp(-((r - 0.27) / 0.012) ** 2) * 0.5  # an older, smaller ring
    mottle = g.noise(1.2, 3, 60)
    a = 0.22 * inside * (0.6 + 0.6 * mottle) + 0.75 * tide + 0.35 * tide2
    rgb = colour((0.47, 0.36, 0.2), 0.9 + 0.2 * (mottle - 0.5) - 0.25 * tide)
    save("water_stain", rgb, a)


def drip_stain():
    g = Gen("drip_stain")
    streaks = g.noise(1.0, 2, 120, stretch=(1.0, 14.0))  # tall thin runs
    length = 0.35 + 0.6 * g.noise(1.4, 1, 10, stretch=(1.0, 30.0))
    run = smooth(streaks, 0.45, 0.8) * (1 - smooth(yy, length * 0.6, length))
    top = (1 - smooth(yy, 0.0, 0.18)) * smooth(np.abs(xx - 0.5), 0.5, 0.2)
    mottle = g.noise(1.2, 3, 60)
    a = np.clip(0.55 * run + 0.45 * top, 0, 1) * (0.7 + 0.4 * mottle) * smooth(np.abs(xx - 0.5), 0.5, 0.3)
    rgb = colour((0.36, 0.28, 0.17), 0.85 + 0.3 * (mottle - 0.5))
    save("drip_stain", rgb, a)


def floor_stain():
    g = Gen("floor_stain")
    shape = g.noise(1.8, 1, 16)
    r = radial(sx=1.0, sy=0.8)
    blob = smooth(shape - 0.9 * r, 0.12, 0.3)
    splash = (g.noise(0.6, 30, 200) > 0.86) * (1 - smooth(r, 0.3, 0.48))
    edge = np.exp(-(((shape - 0.9 * r) - 0.14) / 0.02) ** 2)
    mottle = g.noise(1.0, 4, 80)
    a = 0.32 * blob * (0.35 + 0.9 * mottle) + 0.5 * edge * blob.clip(0.3, 1) + 0.35 * splash
    rgb = colour((0.24, 0.19, 0.12), 0.9 + 0.3 * (mottle - 0.5) - 0.3 * edge)
    save("floor_stain", rgb, a)


def wear_path():
    g = Gen("wear_path")
    along = g.noise(1.3, 1, 40, stretch=(1.0, 6.0))  # stretched: placed lengthwise along the path
    across = 1 - smooth(np.abs(xx - 0.5), 0.12, 0.45)
    ends = smooth(yy, 0.0, 0.15) * (1 - smooth(yy, 0.85, 1.0))
    fibre = g.noise(0.4, 100)
    a = 0.42 * across * ends * (0.6 + 0.6 * along) * (0.85 + 0.3 * fibre)
    rgb = colour((0.2, 0.17, 0.12), 0.9 + 0.2 * (along - 0.5))
    save("wear_path", rgb, a)


def corner_grime():
    g = Gen("corner_grime")
    rise = 0.35 + 0.25 * g.noise(1.4, 1, 20)
    h = 1 - yy  # 0 at the bottom of the image
    bank = 1 - smooth(h, 0.0, rise)
    specks = g.noise(0.5, 40, 220)
    streak = g.noise(1.0, 2, 100, stretch=(1.0, 8.0))
    a = 0.6 * bank ** 1.6 * (0.6 + 0.5 * specks) + 0.15 * bank * smooth(streak, 0.55, 0.8)
    rgb = colour((0.28, 0.23, 0.16), 0.85 + 0.3 * (specks - 0.5))
    save("corner_grime", rgb, a)


def scuff():
    g = Gen("scuff")
    marks = np.zeros((N, N))
    for _ in range(26):
        cx, cy = g.rng.random(), 0.55 + 0.4 * g.rng.random()
        length, tilt = 0.05 + 0.22 * g.rng.random(), (g.rng.random() - 0.5) * 0.25
        thick = 0.004 + 0.012 * g.rng.random()
        u = (xx - cx) * np.cos(tilt) + (yy - cy) * np.sin(tilt)
        v = -(xx - cx) * np.sin(tilt) + (yy - cy) * np.cos(tilt)
        stroke = np.exp(-(v / thick) ** 2) * (1 - smooth(np.abs(u), length * 0.6, length))
        marks = np.maximum(marks, stroke * (0.4 + 0.6 * g.rng.random()))
    dirt = (1 - smooth(1 - yy, 0.0, 0.3)) * 0.25
    grain = g.noise(0.6, 30, 200)
    a = np.clip(0.75 * marks + dirt, 0, 1) * (0.75 + 0.4 * grain)
    rgb = colour((0.17, 0.15, 0.13), np.ones((N, N)))
    save("scuff", rgb, a)


def peel():
    g = Gen("peel")
    edge = 0.18 + 0.22 * g.noise(1.5, 1, 30)  # the torn line, from the top
    torn = g.noise(0.8, 20, 160)
    edge = edge + 0.04 * (torn - 0.5)
    bare = 1 - smooth(yy, edge - 0.01, edge + 0.005)  # plaster showing above the tear
    curl = np.exp(-((yy - edge - 0.012) / 0.012) ** 2)  # the lifted lip catches light
    shadow = np.exp(-((yy - edge - 0.035) / 0.02) ** 2)  # and throws a shadow below it
    plaster = colour((0.72, 0.68, 0.6), 0.9 + 0.2 * (g.noise(1.0, 4, 60) - 0.5))
    lip = np.asarray((0.88, 0.8, 0.58))[None, None, :] * np.ones((N, N, 1))
    dark = np.asarray((0.16, 0.13, 0.09))[None, None, :] * np.ones((N, N, 1))
    rgb = plaster * bare[..., None] + lip * (curl * (1 - bare))[..., None] + dark * (shadow * (1 - bare) * (1 - curl))[..., None]
    total = bare + curl * (1 - bare) + shadow * (1 - bare) * (1 - curl)
    rgb = rgb / np.maximum(total, 1e-3)[..., None]
    a = np.clip(bare * 0.95 + curl * 0.8 + shadow * 0.45, 0, 1)
    save("peel", rgb, a)


def wall_grime():
    g = Gen("wall_grime")
    smudge = smooth(g.noise(1.7, 1, 12), 0.55, 0.85)
    prints = np.zeros((N, N))
    for _ in range(5):  # a few greasy hand marks
        cx, cy = 0.2 + 0.6 * g.rng.random(), 0.3 + 0.4 * g.rng.random()
        prints = np.maximum(prints, np.exp(-(radial(cx, cy, 0.05, 0.07) ** 2) * 3) * (0.5 + 0.5 * g.rng.random()))
    fine = g.noise(0.7, 20, 200)
    a = (0.28 * smudge + 0.3 * prints) * (0.7 + 0.5 * fine) * (1 - smooth(radial(), 0.35, 0.5))
    rgb = colour((0.3, 0.26, 0.19), 0.9 + 0.2 * (fine - 0.5))
    save("wall_grime", rgb, a)


def rust_streak():
    g = Gen("rust_streak")
    streaks = g.noise(1.0, 2, 120, stretch=(1.0, 16.0))
    fade = 1 - smooth(yy, 0.15, 0.95)
    source = (1 - smooth(yy, 0.0, 0.12)) * (1 - smooth(np.abs(xx - 0.5), 0.12, 0.3))
    width = 1 - smooth(np.abs(xx - 0.5), 0.1, 0.42)
    mottle = g.noise(1.0, 4, 80)
    a = np.clip(0.6 * smooth(streaks, 0.4, 0.8) * fade * width + 0.7 * source, 0, 1) * (0.7 + 0.4 * mottle)
    rgb = colour((0.45, 0.25, 0.11), 0.85 + 0.35 * (mottle - 0.5))
    save("rust_streak", rgb, a)


def oil_stain():
    g = Gen("oil_stain")
    shape = g.noise(1.9, 1, 12)
    r = radial()
    pool = smooth(shape - r, 0.05, 0.2)
    rim = np.exp(-(((shape - r) - 0.06) / 0.025) ** 2)
    sheen = g.noise(1.2, 3, 40)
    a = 0.5 * pool * (0.75 + 0.4 * sheen) + 0.2 * rim
    rgb = colour((0.1, 0.09, 0.08), 0.8 + 0.5 * (sheen - 0.5))
    save("oil_stain", rgb, a)


if __name__ == "__main__":
    for fn in (water_stain, drip_stain, floor_stain, wear_path, corner_grime, scuff, peel, wall_grime, rust_streak, oil_stain):
        fn()
