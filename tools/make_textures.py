"""Generates SHIFT's PBR surface textures (original, procedural, CC0).

Run:  python tools/make_textures.py      (needs numpy and Pillow)

Writes assets/textures/<set>_colour.png, _normal.png, _roughness.png and,
for metal surfaces, _metalness.png. 1024x1024, all tile seamlessly (every
noise is periodic). Normal maps are OpenGL style (+Y up), which is what
Roblox expects. Also writes the crew suit's classic clothing templates
(assets/clothing/suit_shirt.png and suit_pants.png, 585x559).

Every image here was made by this script for SHIFT, so it is free to use
with no attribution (CC0). The set names match Surfaces.luau and
AssetIds.luau. To swap in scanned CC0 sets instead, keep the same file
names (tools/fetch_cc0.py does this).

Pass set names to regenerate only those:  python tools/make_textures.py wood rust
"""
import os
import sys
import numpy as np
from PIL import Image

N = 1024
ROOT = os.path.join(os.path.dirname(__file__), "..", "assets")
OUT = os.path.join(ROOT, "textures")

yy, xx = np.mgrid[0:N, 0:N] / N


def rng_for(name):
    return np.random.default_rng(abs(hash(name)) % (2**32) if False else sum(map(ord, name)) * 7919 + 20261127)


class Gen:
    def __init__(self, name):
        self.rng = rng_for(name)

    def noise(self, beta, lo=1.0, hi=None, n=N, stretch=(1.0, 1.0)):
        """Periodic fractal noise: white noise shaped as 1/f^beta, values 0..1.
        stretch scales frequency per axis (x, y) for streaky noise."""
        white = self.rng.standard_normal((n, n))
        f = np.fft.fftfreq(n) * n
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

    def cells(self, count):
        """Periodic Worley distance (F1, F2) with `count` random points."""
        pts = self.rng.random((count, 2))
        f1 = np.full((N, N), 9.0)
        f2 = np.full((N, N), 9.0)
        for px, py in pts:
            dx = np.abs(xx - px)
            dx = np.minimum(dx, 1 - dx)
            dy = np.abs(yy - py)
            dy = np.minimum(dy, 1 - dy)
            d = np.sqrt(dx * dx + dy * dy)
            f2 = np.where(d < f1, f1, np.minimum(f2, d))
            f1 = np.minimum(f1, d)
        return f1, f2


def normal_from(height, strength):
    dx = (np.roll(height, -1, 1) - np.roll(height, 1, 1)) * strength
    dy = (np.roll(height, -1, 0) - np.roll(height, 1, 0)) * strength
    nx, ny, nz = -dx, dy, np.ones_like(height)  # +Y up (OpenGL)
    length = np.sqrt(nx * nx + ny * ny + nz * nz)
    rgb = np.stack([nx / length, ny / length, nz / length], -1) * 0.5 + 0.5
    return (rgb * 255).clip(0, 255).astype(np.uint8)


def save(name, colour, height, strength, rough, metal=None):
    os.makedirs(OUT, exist_ok=True)
    Image.fromarray((np.clip(colour, 0, 1) * 255).astype(np.uint8)).save(os.path.join(OUT, f"{name}_colour.png"), optimize=True)
    Image.fromarray(normal_from(height, strength)).save(os.path.join(OUT, f"{name}_normal.png"), optimize=True)
    Image.fromarray((np.clip(rough, 0, 1) * 255).astype(np.uint8), "L").save(os.path.join(OUT, f"{name}_roughness.png"), optimize=True)
    if metal is not None:
        Image.fromarray((np.clip(metal, 0, 1) * 255).astype(np.uint8), "L").save(os.path.join(OUT, f"{name}_metalness.png"), optimize=True)
    print("wrote", name)


def tint(base, shade):
    return np.asarray(base, float)[None, None, :] * shade[..., None]


def mix(a, b, t):
    t = t[..., None] if np.ndim(t) == 2 else t
    return a * (1 - t) + b * t


def grid_coords(nx, ny):
    """Position inside a grid tile (0..1) and the tile index."""
    u, v = xx * nx, yy * ny
    return u % 1.0, v % 1.0, np.floor(u).astype(int), np.floor(v).astype(int)


def edge_dist(u, v):
    """Distance from a tile's edge, in tile units (0 at the edge, 0.5 centre)."""
    return np.minimum(np.minimum(u, 1 - u), np.minimum(v, 1 - v))


def per_tile(gen, iu, iv, n):
    """A random value per tile, consistent across the tile."""
    table = gen.rng.random((n, n))
    return table[iv % n, iu % n]


# ---------------------------------------------------------------------------
# LEVEL SURFACES


def wallpaper():
    # Tired cream-yellow paper: faint vertical bands, a worn printed lattice
    # of stretched diamonds with a dot in each, grubby patches.
    g = Gen("wallpaper")
    grime = g.noise(1.6, 1, 24)
    fibre = g.noise(0.6, 64)
    bands = 0.5 + 0.5 * np.cos(xx * 2 * np.pi * 8)
    u, v = (xx * 8) % 1.0, (yy * 6) % 1.0
    diamond = np.abs(u - 0.5) * 1.0 + np.abs(v - 0.5) * 0.6
    lattice = ((diamond > 0.33) & (diamond < 0.36)).astype(float)
    dot = (((u - 0.5) ** 2 + ((v - 0.5) * 0.6) ** 2) < 0.0016).astype(float)
    wear = g.noise(1.2, 2, 40) > 0.42
    printed = np.maximum(lattice, dot) * wear
    shade = 0.86 + 0.025 * bands - 0.09 * printed + 0.12 * (grime - 0.5) + 0.05 * (fibre - 0.5)
    colour = tint((0.86, 0.77, 0.47), shade)
    colour[..., 2] -= 0.05 * grime
    height = 0.6 * fibre + 0.4 * printed
    save("wallpaper", colour, height, 2.0, 0.82 + 0.1 * grime)


def carpet():
    # Short-pile mustard carpet, mottled, with damp darker patches.
    g = Gen("carpet")
    pile = g.noise(0.25, 150)
    tufts = g.noise(0.9, 40, 200)
    mottle = g.noise(1.4, 2, 30)
    damp = np.clip((g.noise(1.8, 1, 10) - 0.62) * 4, 0, 1)
    shade = 0.8 + 0.18 * (pile - 0.5) + 0.12 * (tufts - 0.5) + 0.1 * (mottle - 0.5) - 0.07 * damp
    colour = tint((0.62, 0.53, 0.3), shade)
    height = 0.55 * pile + 0.45 * tufts
    save("carpet", colour, height, 6.0, 0.95 - 0.12 * damp)


def ceiling():
    # Off-white mineral fibre ceiling tile with fissures and pinholes.
    g = Gen("ceiling")
    base = g.noise(1.3, 2, 40)
    speck = g.noise(0.2, 200)
    holes = (g.noise(0.15, 220) > 0.78).astype(float)
    fiss = g.noise(1.0, 20, 120)
    fissures = np.clip((np.abs(fiss - 0.5) < 0.012).astype(float) * (g.noise(1.5, 4, 40) > 0.5), 0, 1)
    stain = np.clip((g.noise(1.9, 1, 8) - 0.68) * 3, 0, 1)
    shade = 0.9 + 0.05 * (base - 0.5) + 0.04 * (speck - 0.5) - 0.25 * holes - 0.2 * fissures
    colour = tint((0.9, 0.88, 0.8), shade)
    colour = colour * (1 - 0.1 * stain[..., None]) + np.array([0.55, 0.45, 0.25]) * 0.1 * stain[..., None]
    height = 0.5 * speck + 0.3 * base - 0.6 * holes - 0.5 * fissures
    save("ceiling", colour, height, 3.0, 0.93 + 0.0 * base)


def concrete():
    # Poured concrete, blotchy, with pores and hairline cracks.
    g = Gen("concrete")
    blotch = g.noise(1.5, 1, 30)
    grain = g.noise(0.5, 80)
    pores = (g.noise(0.2, 200) > 0.8).astype(float)
    crack = g.noise(1.1, 3, 60)
    cracks = (np.abs(crack - 0.5) < 0.003).astype(float) * (g.noise(1.6, 2, 30) > 0.72)
    shade = 0.62 + 0.14 * (blotch - 0.5) + 0.08 * (grain - 0.5) - 0.2 * pores - 0.18 * cracks
    colour = tint((0.78, 0.76, 0.72), shade)
    height = 0.4 * blotch + 0.5 * grain - 0.5 * pores - 0.6 * cracks
    save("concrete", colour, height, 3.0, 0.78 + 0.12 * blotch)


def ward_tile():
    # The Ward's walls: small glazed tiles, off-white with a green cast,
    # grubby grout, the odd chipped corner. Glaze is shiny, grout is not.
    g = Gen("ward_tile")
    u, v, iu, iv = grid_coords(8, 8)
    d = edge_dist(u, v)
    grout = d < 0.035
    bevel = np.clip((d - 0.035) / 0.06, 0, 1)
    tile_shade = per_tile(g, iu, iv, 8)
    grime = g.noise(1.5, 1, 20)
    glaze = g.noise(0.8, 30)
    chips = (g.noise(0.4, 90) > 0.82) & (d < 0.12) & ~grout
    tile = tint((0.82, 0.88, 0.85), 0.94 + 0.05 * (tile_shade - 0.5) + 0.03 * (glaze - 0.5) - 0.08 * np.clip(grime - 0.6, 0, 1))
    gr = tint((0.42, 0.44, 0.4), 0.9 + 0.3 * (grime - 0.5))
    chipcol = tint((0.66, 0.64, 0.58), np.ones_like(d))
    colour = np.where(grout[..., None], gr, np.where(chips[..., None], chipcol, tile))
    height = np.where(grout, 0.0, bevel ** 0.5) - 0.4 * chips + 0.02 * glaze
    rough = np.where(grout, 0.92, np.where(chips, 0.85, 0.18 + 0.12 * grime))
    save("ward_tile", colour, height, 5.0, rough)


def ward_floor():
    # The Ward's floor: big speckled vinyl tiles with seams and scuffs.
    g = Gen("ward_floor")
    u, v, iu, iv = grid_coords(4, 4)
    d = edge_dist(u, v)
    seam = d < 0.006
    tile_shade = per_tile(g, iu, iv, 4)
    fleck = g.noise(0.1, 260)
    flecks_dark = fleck > 0.74
    flecks_light = fleck < 0.24
    scuff = np.clip((g.noise(1.2, 3, 60, stretch=(1.0, 4.0)) - 0.66) * 2, 0, 1)
    grime = g.noise(1.7, 1, 12)
    shade = 0.74 + 0.04 * (tile_shade - 0.5) - 0.18 * flecks_dark + 0.1 * flecks_light - 0.12 * scuff - 0.06 * (grime - 0.5)
    colour = tint((0.7, 0.74, 0.7), shade)
    colour = np.where(seam[..., None], colour * 0.55, colour)
    height = 0.1 * fleck - 0.8 * seam - 0.1 * scuff
    rough = 0.5 + 0.25 * scuff + 0.1 * grime
    save("ward_floor", colour, height, 4.0, rough)


def steel_plate():
    # The Plant Room's floor: diamond tread plate, worn shiny on top of
    # the lozenges, rust creeping in from the edges of patches.
    g = Gen("steel_plate")
    u, v, iu, iv = grid_coords(12, 12)
    flip = ((iu + iv) % 2 == 0)
    a = np.where(flip, (u - 0.5) + (v - 0.5), (u - 0.5) - (v - 0.5))
    b = np.where(flip, (u - 0.5) - (v - 0.5), (u - 0.5) + (v - 0.5))
    lozenge = np.clip(1 - (np.abs(a) / 0.5) ** 2 - (np.abs(b) / 0.14) ** 2, 0, 1)
    raised = lozenge ** 0.4
    rust = np.clip((g.noise(1.4, 2, 40) - 0.7) * 3.0, 0, 1) * 0.8
    pits = (g.noise(0.3, 140) > 0.8) & (rust > 0.3)
    grime = g.noise(1.4, 2, 30)
    steel = tint((0.5, 0.5, 0.52), 0.7 + 0.5 * raised - 0.15 * (grime - 0.5))
    rustc = tint((0.42, 0.22, 0.1), 0.85 + 0.3 * (g.noise(0.6, 40) - 0.5))
    colour = mix(steel, rustc, rust)
    height = raised - 0.3 * pits + 0.05 * grime
    metal = np.clip(1 - rust * 1.2, 0, 1)
    rough = np.clip(0.42 - 0.18 * raised + 0.15 * grime + 0.5 * rust, 0, 1)
    save("steel_plate", colour, height, 6.0, rough, metal)


def painted_metal():
    # Cabinets, shelves, skirting and housings: thick grey paint (neutral,
    # tinted by each part's colour) chipped back to dark steel at random.
    g = Gen("painted_metal")
    chipn = g.noise(1.0, 6, 90)
    chips = chipn > 0.86
    scratch = (np.abs(g.noise(1.2, 8, 120, stretch=(1.0, 8.0)) - 0.5) < 0.0025) & (g.noise(1.4, 2, 20) > 0.55)
    orange = g.noise(0.9, 40, 200)  # orange-peel paint texture
    grime = g.noise(1.6, 1, 20)
    paint = tint((0.82, 0.82, 0.8), 0.95 + 0.04 * (orange - 0.5) - 0.12 * np.clip(grime - 0.55, 0, 1))
    bare = tint((0.36, 0.36, 0.37), np.ones_like(orange))
    colour = np.where((chips | scratch)[..., None], bare, paint)
    height = 0.08 * orange - 0.5 * chips - 0.3 * scratch
    metal = (chips | scratch).astype(float)
    rough = np.where(chips | scratch, 0.35, 0.48 + 0.2 * grime)
    save("painted_metal", colour, height, 3.0, rough, metal)


def brushed_metal():
    # Lift walls, light housings, handles: brushed steel with smudges.
    g = Gen("brushed_metal")
    brush = g.noise(0.6, 4, 400, stretch=(0.04, 1.0))
    smudge = g.noise(1.7, 1, 14)
    dents = g.noise(1.3, 3, 40)
    colour = tint((0.66, 0.66, 0.68), 0.88 + 0.12 * (brush - 0.5) - 0.06 * (smudge - 0.5))
    height = 0.35 * brush + 0.2 * dents
    metal = np.full((N, N), 1.0)
    rough = 0.28 + 0.12 * (brush - 0.5) + 0.2 * np.clip(smudge - 0.5, 0, 1)
    save("brushed_metal", colour, height, 1.5, rough, metal)


def rust():
    # Plant Room pipes and trim: corroded steel, pitted and flaking.
    g = Gen("rust")
    corr = g.noise(1.3, 1, 40)
    flake = g.noise(0.7, 20, 160)
    pits = g.noise(0.3, 150) > 0.78
    heavy = np.clip((corr - 0.45) * 3, 0, 1)
    steel = tint((0.4, 0.38, 0.36), 0.9 + 0.2 * (flake - 0.5))
    rustc = mix(tint((0.48, 0.24, 0.1), np.ones_like(corr)), tint((0.3, 0.14, 0.06), np.ones_like(corr)), flake)
    colour = mix(steel, rustc, heavy)
    height = 0.4 * flake + 0.3 * corr - 0.4 * pits
    metal = np.clip(1 - heavy * 1.3, 0, 1) * 0.9
    rough = np.clip(0.5 + 0.45 * heavy + 0.1 * pits, 0, 1)
    save("rust", colour, height, 4.0, rough, metal)


def wood():
    # Doors and desks: warm varnished grain, slightly worn.
    g = Gen("wood")
    warp = g.noise(1.6, 1, 10)
    fine = g.noise(0.8, 20, 300, stretch=(0.08, 1.0))
    rings = 0.5 + 0.5 * np.sin((xx * 48 + warp * 6.0 + 0.4 * g.noise(1.0, 3, 30)) * 2 * np.pi)
    late = np.clip((rings - 0.55) * 2.0, 0, 1) * (0.6 + 0.4 * g.noise(1.2, 2, 20))
    knots_f1, _ = g.cells(3)
    knot = np.clip(1 - knots_f1 / 0.035, 0, 1) * (g.noise(1.0, 2, 20) > 0.5)
    wear = g.noise(1.5, 1, 16)
    shade = 0.84 - 0.12 * late - 0.14 * (fine - 0.5) - 0.3 * knot + 0.05 * (wear - 0.5)
    colour = tint((0.62, 0.43, 0.26), shade)
    height = -0.3 * late + 0.2 * fine - 0.3 * knot
    rough = 0.48 + 0.2 * late + 0.15 * np.clip(wear - 0.55, 0, 1)
    save("wood", colour, height, 2.5, rough)


def fabric():
    # Office chairs and upholstery: tight woven fabric, neutral (tinted).
    g = Gen("fabric")
    tx, ty = xx * 256, yy * 256
    warp_ = 0.5 + 0.5 * np.sin(tx * 2 * np.pi)
    weft = 0.5 + 0.5 * np.sin(ty * 2 * np.pi)
    over = ((np.floor(tx) + np.floor(ty)) % 2 == 0)
    weave = np.where(over, warp_, weft)
    fuzz = g.noise(0.3, 100)
    pill = g.noise(1.5, 1, 30)
    colour = tint((0.78, 0.78, 0.78), 0.84 + 0.1 * (weave - 0.5) + 0.06 * (fuzz - 0.5) - 0.06 * (pill - 0.5))
    height = 0.6 * weave + 0.3 * fuzz
    save("fabric", colour, height, 3.0, 0.92 + 0.06 * fuzz)


def cardboard():
    # Storage boxes: brown board, faint flute ridges, scuffs and damp marks.
    g = Gen("cardboard")
    flutes = 0.5 + 0.5 * np.sin(yy * 2 * np.pi * 48)
    fibre = g.noise(0.4, 80)
    damp = np.clip((g.noise(1.8, 1, 8) - 0.62) * 3, 0, 1)
    scuff = np.clip((g.noise(1.1, 4, 60) - 0.7) * 4, 0, 1)
    shade = 0.86 + 0.03 * flutes + 0.08 * (fibre - 0.5) - 0.18 * damp + 0.1 * scuff
    colour = tint((0.66, 0.5, 0.32), shade)
    height = 0.25 * flutes + 0.5 * fibre - 0.2 * scuff
    save("cardboard", colour, height, 2.0, 0.9 - 0.08 * damp)


def aged_plastic():
    # Monitors, keyboards, sockets: old beige plastic (neutral-ish, tinted),
    # fine moulded texture, scratches and a yellowed film.
    g = Gen("aged_plastic")
    mould = g.noise(0.2, 180)
    scratch = (np.abs(g.noise(1.2, 6, 120, stretch=(1.0, 6.0)) - 0.5) < 0.0035)
    yellow = g.noise(1.6, 1, 10)
    colour = tint((0.92, 0.9, 0.86), 0.93 + 0.03 * (mould - 0.5) + 0.05 * scratch)
    colour[..., 2] -= 0.06 * yellow
    height = 0.2 * mould - 0.3 * scratch
    rough = 0.5 + 0.1 * mould + 0.15 * scratch
    save("aged_plastic", colour, height, 2.0, rough)


def paper():
    # Loose paper: printed lines of text on cheap white paper, creased.
    g = Gen("paper")
    fibre = g.noise(0.4, 100)
    crease = np.abs(g.noise(1.0, 2, 12) - 0.5) < 0.006
    line = (yy * 40) % 1.0
    words = g.noise(0.6, 30, 200, stretch=(1.0, 20.0)) > 0.45
    text = (line > 0.35) & (line < 0.6) & words & (xx % 0.5 > 0.04) & (xx % 0.5 < 0.46) & ((yy % 0.5) > 0.08)
    shade = 0.93 + 0.04 * (fibre - 0.5) - 0.55 * text - 0.1 * crease
    colour = tint((0.96, 0.95, 0.9), shade)
    height = 0.2 * fibre - 0.5 * crease
    save("paper", colour, height, 2.0, 0.85 + 0.0 * fibre)


def rubber():
    # Suit gloves and boots: black rubber with a fine grain, scuffed grey.
    g = Gen("rubber")
    grain = g.noise(0.3, 120)
    scuff = np.clip((g.noise(1.2, 3, 50) - 0.65) * 3, 0, 1)
    colour = tint((0.1, 0.1, 0.1), 0.85 + 0.25 * (grain - 0.5) + 0.35 * scuff)
    height = 0.4 * grain - 0.2 * scuff
    save("rubber", colour, height, 2.5, 0.72 + 0.15 * scuff)


def suit_fabric():
    # The crew suit (hood): heavy twill canvas, neutral so it takes the suit colour.
    g = Gen("suit_fabric")
    twill = 0.5 + 0.5 * np.sin((xx + yy) * 2 * np.pi * 180)
    fibre = g.noise(0.4, 100)
    wear = g.noise(1.5, 1, 20)
    colour = tint((0.8, 0.8, 0.8), 0.86 + 0.07 * (twill - 0.5) + 0.06 * (fibre - 0.5) + 0.06 * (wear - 0.5))
    height = 0.5 * twill + 0.4 * fibre
    save("suit_fabric", colour, height, 2.5, 0.9 + 0.05 * fibre)


def tenant_skin():
    # The Tenant: near-black, waxy, featureless skin with faint raised
    # veins and fine wrinkles. Shiny where it is damp, so it catches light.
    g = Gen("tenant_skin")
    mottle = g.noise(1.4, 2, 30)
    vein = np.abs(g.noise(1.2, 3, 50) - 0.5) < 0.01
    wrinkle = g.noise(0.8, 30, 250, stretch=(1.0, 0.25))
    pores = g.noise(0.2, 220)
    damp = np.clip((g.noise(1.6, 1, 14) - 0.55) * 3, 0, 1)
    colour = tint((0.075, 0.07, 0.068), 0.95 + 0.25 * (mottle - 0.5) - 0.1 * (pores - 0.5))
    colour = mix(colour, tint((0.16, 0.15, 0.15), np.ones_like(mottle)), vein * 0.5)
    height = 0.5 * wrinkle + 0.15 * pores + 0.2 * vein
    rough = 0.55 - 0.3 * damp + 0.05 * pores
    save("tenant_skin", colour, height, 3.0, rough)


def tenant_coat():
    # The Tenant's long coat: old dark wool felt, worn shiny at the seams.
    g = Gen("tenant_coat")
    felt = g.noise(0.5, 60)
    hairs = g.noise(0.2, 250)
    worn = np.clip((g.noise(1.5, 1, 16) - 0.55) * 3, 0, 1)
    stain = np.clip((g.noise(1.8, 1, 8) - 0.65) * 3, 0, 1)
    colour = tint((0.1, 0.095, 0.09), 0.9 + 0.15 * (felt - 0.5) + 0.1 * (hairs - 0.5) + 0.2 * worn - 0.25 * stain)
    height = 0.5 * felt + 0.3 * hairs
    rough = 0.95 - 0.3 * worn
    save("tenant_coat", colour, height, 3.0, rough)


# ---------------------------------------------------------------------------
# CLASSIC CLOTHING: the crew suit as a Shirt + Pants (585x559 templates).
# Neutral light grey so Clothing.Color3 tints it to each suit colour. Roblox
# template regions: https://create.roblox.com/docs/art/classic-clothing

W, H = 585, 559
TORSO = {"U": (231, 8, 128, 64), "F": (231, 74, 128, 128), "D": (231, 204, 128, 64),
         "R": (165, 74, 64, 128), "L": (361, 74, 64, 128), "B": (427, 74, 128, 128)}
LIMB_R = {"U": (217, 289, 64, 64), "D": (217, 485, 64, 64),
          "F": (217, 355, 64, 128), "L": (151, 355, 64, 128), "B": (85, 355, 64, 128), "R": (19, 355, 64, 128)}
LIMB_L = {"U": (308, 289, 64, 64), "D": (308, 485, 64, 64),
          "F": (308, 355, 64, 128), "L": (374, 355, 64, 128), "B": (440, 355, 64, 128), "R": (506, 355, 64, 128)}


def cloth_canvas():
    g = Gen("suit_template")
    ty, tx = np.mgrid[0:H, 0:W]
    twill = 0.5 + 0.5 * np.sin((tx + ty) * 0.9)
    fibre = g.noise(0.4, 60, n=1024)[:H, :W]
    base = 0.82 + 0.05 * (twill - 0.5) + 0.06 * (fibre - 0.5)
    img = np.stack([base, base, base], -1)
    return img


def rect(img, box, colour, inset=(0, 0, 0, 0)):
    x, y, w, h = box
    l, t, r, b = inset
    img[y + t : y + h - b, x + l : x + w - r] = colour


def seams(img, region):
    # A darker stitched edge round every face.
    for box in region.values():
        x, y, w, h = box
        img[y : y + 2, x : x + w] *= 0.8
        img[y + h - 2 : y + h, x : x + w] *= 0.8
        img[y : y + h, x : x + 2] *= 0.8
        img[y : y + h, x + w - 2 : x + w] *= 0.8


def shirt():
    img = cloth_canvas()
    for reg in (TORSO, LIMB_R, LIMB_L):
        seams(img, reg)
    fx, fy, fw, fh = TORSO["F"]
    # Zip down the middle with a dark placket.
    img[fy : fy + fh, fx + 61 : fx + 67] = 0.45
    img[fy : fy + fh : 4, fx + 63 : fx + 65] = 0.7
    # Collar.
    img[fy : fy + 10, fx + 30 : fx + 98] *= 0.78
    # Chest pocket (left side as you look at it) with a flap.
    rect(img, (fx + 14, fy + 26, 36, 30), img[fy + 40, fx + 20] * 0.9)
    rect(img, (fx + 14, fy + 26, 36, 6), 0.62)
    # Hi-vis tape across the back, and round the upper arms.
    bx, by, bw, bh = TORSO["B"]
    rect(img, (bx, by + 40, bw, 12), np.array([0.95, 0.93, 0.85]))
    rect(img, (bx, by + 54, bw, 3), 0.5)
    for reg in (LIMB_R, LIMB_L):
        for face in ("F", "L", "B", "R"):
            x, y, w, h = reg[face]
            rect(img, (x, y + 22, w, 9), np.array([0.95, 0.93, 0.85]))
            img[y + h - 10 : y + h, x : x + w] *= 0.7  # cuffs
    # Belt line at the bottom of the shirt.
    for face in ("F", "L", "B", "R"):
        x, y, w, h = TORSO[face]
        img[y + h - 8 : y + h, x : x + w] = 0.4
    out = (np.clip(img, 0, 1) * 255).astype(np.uint8)
    return Image.fromarray(out)


def pants():
    img = cloth_canvas()
    for reg in (TORSO, LIMB_R, LIMB_L):
        seams(img, reg)
    # Belt at the top of the hips.
    for face in ("F", "L", "B", "R"):
        x, y, w, h = TORSO[face]
        img[y : y + 10, x : x + w] = 0.4
    fx, fy, fw, fh = TORSO["F"]
    img[fy + 10 : fy + 50, fx + 62 : fx + 66] = 0.5  # fly
    for reg in (LIMB_R, LIMB_L):
        x, y, w, h = reg["F"]
        # Knee pads and a cargo pocket.
        rect(img, (x + 10, y + 52, w - 20, 26), 0.5)
        rect(img, (x + 10, y + 52, w - 20, 3), 0.35)
        sx, sy, sw, sh = reg["R"] if reg is LIMB_R else reg["L"]
        rect(img, (sx + 12, sy + 18, sw - 24, 30), img[sy + 10, sx + 30] * 0.88)
        for face in ("F", "L", "B", "R"):
            x2, y2, w2, h2 = reg[face]
            rect(img, (x2, y2 + 88, w2, 9), np.array([0.95, 0.93, 0.85]))  # shin tape
            img[y2 + h2 - 14 : y2 + h2, x2 : x2 + w2] = 0.18  # boot tops
    out = (np.clip(img, 0, 1) * 255).astype(np.uint8)
    return Image.fromarray(out)


def clothing():
    out = os.path.join(ROOT, "clothing")
    os.makedirs(out, exist_ok=True)
    shirt().save(os.path.join(out, "suit_shirt.png"), optimize=True)
    pants().save(os.path.join(out, "suit_pants.png"), optimize=True)
    print("wrote clothing")


SETS = {
    "wallpaper": wallpaper, "carpet": carpet, "ceiling": ceiling, "concrete": concrete,
    "ward_tile": ward_tile, "ward_floor": ward_floor, "steel_plate": steel_plate,
    "painted_metal": painted_metal, "brushed_metal": brushed_metal, "rust": rust,
    "wood": wood, "fabric": fabric, "cardboard": cardboard, "aged_plastic": aged_plastic,
    "paper": paper, "rubber": rubber, "suit_fabric": suit_fabric,
    "tenant_skin": tenant_skin, "tenant_coat": tenant_coat, "clothing": clothing,
}

if __name__ == "__main__":
    wanted = sys.argv[1:] or list(SETS)
    for name in wanted:
        SETS[name]()
