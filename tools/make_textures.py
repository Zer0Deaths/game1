"""Generates SHIFT's surface textures (original, procedural, free to use).

Run:  python tools/make_textures.py      (needs numpy and Pillow)
Writes assets/textures/<name>_colour.png, _normal.png, _roughness.png.
Every texture tiles seamlessly (all noise is periodic).
Normal maps are OpenGL style (+Y up), which is what Roblox expects.
"""
import os
import numpy as np
from PIL import Image

N = 1024
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "textures")
rng = np.random.default_rng(20261127)


def noise(beta, lo=1.0, hi=None, n=N):
    """Periodic fractal noise: white noise shaped as 1/f^beta, values 0..1."""
    white = rng.standard_normal((n, n))
    f = np.fft.fftfreq(n) * n
    fx, fy = np.meshgrid(f, f)
    r = np.sqrt(fx * fx + fy * fy)
    r[0, 0] = 1
    amp = 1.0 / r ** beta
    amp[r < lo] = 0
    if hi:
        amp[r > hi] = 0
    out = np.real(np.fft.ifft2(np.fft.fft2(white) * amp))
    out -= out.min()
    return out / out.max()


def normal_from(height, strength):
    dx = (np.roll(height, -1, 1) - np.roll(height, 1, 1)) * strength
    dy = (np.roll(height, -1, 0) - np.roll(height, 1, 0)) * strength
    nx, ny, nz = -dx, dy, np.ones_like(height)  # +Y up (OpenGL)
    length = np.sqrt(nx * nx + ny * ny + nz * nz)
    rgb = np.stack([nx / length, ny / length, nz / length], -1) * 0.5 + 0.5
    return (rgb * 255).clip(0, 255).astype(np.uint8)


def save(name, colour, height, strength, rough):
    os.makedirs(OUT, exist_ok=True)
    Image.fromarray((colour.clip(0, 1) * 255).astype(np.uint8)).save(os.path.join(OUT, f"{name}_colour.png"), optimize=True)
    Image.fromarray(normal_from(height, strength)).save(os.path.join(OUT, f"{name}_normal.png"), optimize=True)
    Image.fromarray((rough.clip(0, 1) * 255).astype(np.uint8), "L").save(os.path.join(OUT, f"{name}_roughness.png"), optimize=True)
    print("wrote", name)


def tint(base, shade):
    return np.asarray(base, float)[None, None, :] * shade[..., None]


yy, xx = np.mgrid[0:N, 0:N] / N

# WALLPAPER: tired cream-yellow paper. Faint vertical bands, and a small
# printed lattice of stretched diamonds with a dot in each, worn patchy.
grime = noise(1.6, 1, 24)
fibre = noise(0.6, 64)
bands = 0.5 + 0.5 * np.cos(xx * 2 * np.pi * 8)
u, v = (xx * 8) % 1.0, (yy * 6) % 1.0
diamond = np.abs(u - 0.5) * 1.0 + np.abs(v - 0.5) * 0.6
lattice = ((diamond > 0.33) & (diamond < 0.36)).astype(float)
dot = (((u - 0.5) ** 2 + ((v - 0.5) * 0.6) ** 2) < 0.0016).astype(float)
wear = noise(1.2, 2, 40) > 0.42
printed = np.maximum(lattice, dot) * wear
shade = 0.86 + 0.025 * bands - 0.09 * printed + 0.12 * (grime - 0.5) + 0.05 * (fibre - 0.5)
colour = tint((0.86, 0.77, 0.47), shade)
colour[..., 2] -= 0.05 * grime  # yellowing where it's grubby
height = 0.6 * fibre + 0.4 * printed
save("wallpaper", colour, height, 2.0, 0.82 + 0.1 * grime)

# CARPET: short-pile mustard carpet, mottled, with damp darker patches.
pile = noise(0.25, 150)
tufts = noise(0.9, 40, 200)
mottle = noise(1.4, 2, 30)
damp = np.clip((noise(1.8, 1, 10) - 0.62) * 4, 0, 1)
shade = 0.8 + 0.18 * (pile - 0.5) + 0.12 * (tufts - 0.5) + 0.1 * (mottle - 0.5) - 0.07 * damp
colour = tint((0.62, 0.53, 0.3), shade)
height = 0.55 * pile + 0.45 * tufts
save("carpet", colour, height, 6.0, 0.95 - 0.12 * damp)

# CEILING TILE: off-white mineral fibre with fissures and pinholes.
base = noise(1.3, 2, 40)
speck = noise(0.2, 200)
holes = (noise(0.15, 220) > 0.78).astype(float)
fiss = noise(1.0, 20, 120)
fissures = np.clip((np.abs(fiss - 0.5) < 0.012).astype(float) * (noise(1.5, 4, 40) > 0.5), 0, 1)
stain = np.clip((noise(1.9, 1, 8) - 0.68) * 3, 0, 1)
shade = 0.9 + 0.05 * (base - 0.5) + 0.04 * (speck - 0.5) - 0.25 * holes - 0.2 * fissures
colour = tint((0.9, 0.88, 0.8), shade)
colour = colour * (1 - 0.1 * stain[..., None]) + np.array([0.55, 0.45, 0.25]) * 0.1 * stain[..., None]
height = 0.5 * speck + 0.3 * base - 0.6 * holes - 0.5 * fissures
save("ceiling", colour, height, 3.0, 0.93 + 0.0 * base)

# CONCRETE: poured concrete, blotchy, with pores and hairline cracks.
blotch = noise(1.5, 1, 30)
grain = noise(0.5, 80)
pores = (noise(0.2, 200) > 0.8).astype(float)
crack = noise(1.1, 3, 60)
cracks = (np.abs(crack - 0.5) < 0.003).astype(float) * (noise(1.6, 2, 30) > 0.72)
shade = 0.62 + 0.14 * (blotch - 0.5) + 0.08 * (grain - 0.5) - 0.2 * pores - 0.18 * cracks
colour = tint((0.78, 0.76, 0.72), shade)
height = 0.4 * blotch + 0.5 * grain - 0.5 * pores - 0.6 * cracks
save("concrete", colour, height, 3.0, 0.78 + 0.12 * blotch)
