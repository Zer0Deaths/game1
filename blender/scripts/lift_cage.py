"""Shared builder for SHIFT's two lift cages (exit_lift.py in the levels,
descent_lift.py in the safehouse): a square chequer-plate deck (10 x 10
studs in the safehouse, 16 x 16 in the levels so the armoury fits), four
steel H-section posts at the corners, a channel-beam header round the top
with a cross beam, and the lift's hoist ropes running up into the ceiling.
Origin on the floor at the middle of the deck. Not a model on its own."""
import math
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent / "lib"))

import kit  # noqa: E402
from kit import cf, deg  # noqa: E402

def build(name, H, post_colour, footings=False, kerb=False, panel=None, lamp=False, half=5.0):
    S = half * 2
    CORNERS = [(half, half), (-half, half), (half, -half), (-half, -half)]
    deck = kit.Mesh("Deck", "steel_plate", (70, 70, 74))
    deck.box((S, 0.2, S), cf(0, 0.1, 0), bevel=0.03)
    trim = kit.Mesh("Trim", "painted_metal", (56, 56, 58))
    for s in (-1, 1):  # angle-iron round the deck edge
        trim.box((S + 0.2, 0.22, 0.12), cf(0, 0.11, s * (half + 0.04)), bevel=0.02)
        trim.box((0.12, 0.22, S + 0.2), cf(s * (half + 0.04), 0.11, 0), bevel=0.02)
    posts = kit.Mesh("Posts", "painted_metal", post_colour)
    for x, z in CORNERS:
        # H-section: two flanges and a web, flanges facing along X.
        for f in (-1, 1):
            posts.box((0.6, H, 0.08), cf(x, H / 2, z + f * 0.26), bevel=0.02)
        posts.box((0.08, H, 0.48), cf(x, H / 2, z), bevel=0.01)
        posts.box((0.8, 0.06, 0.8), cf(x, 0.23, z), bevel=0.02)  # base plate on the deck
    hy = H - 0.35
    for s in (-1, 1):  # header channels between the posts
        posts.box((S + 0.6, 0.5, 0.3), cf(0, hy, s * half), bevel=0.03)
        posts.box((0.3, 0.5, S), cf(s * half, hy, 0), bevel=0.03)
    posts.box((S, 0.36, 0.36), cf(0, hy - 0.05, 0), bevel=0.03)  # cross beam over the middle
    bolts = kit.Mesh("Bolts", "brushed_metal", (130, 128, 120))
    for x, z in CORNERS:
        for dx, dz in ((0.28, 0.28), (-0.28, 0.28), (0.28, -0.28), (-0.28, -0.28)):
            bolts.cyl(0.08, 0.06, cf(x + dx * 0.9, 0.3, z + dz * 0.9, rz=deg(90)), segments=6, bevel=0.0)
    ropes = kit.Mesh("Ropes", "rubber", (40, 40, 38))
    for x in (-1.2, 1.2):
        ropes.cyl(0.5, 0.06, cf(x, H - 0.25, 0, rz=deg(90)), segments=6, bevel=0.0)  # into the ceiling
        ropes.box((0.4, 0.3, 0.5), cf(x, hy - 0.32, 0), bevel=0.04)  # rope clamp under the beam
    meshes = [deck, trim, posts, bolts, ropes]
    if footings:
        conc = kit.Mesh("Footings", "concrete", (150, 146, 136))
        for x, z in CORNERS:
            conc.box((1.4, 1.1, 1.4), cf(x, 0.55, z), bevel=0.08)
        meshes.append(conc)
    if kerb:
        k = kit.Mesh("Kerb", "concrete", (140, 136, 126))
        for s in (-1, 1):
            k.box((S + 1.4, 0.18, 0.9), cf(0, 0.09, s * (half + 0.45)), bevel=0.04)
            k.box((0.9, 0.18, S), cf(s * (half + 0.45), 0.09, 0), bevel=0.04)
        meshes.append(k)
    if panel:
        # The control box on the corner post: two lit buttons and a key.
        px, py, pz, yaw = panel
        box = kit.Mesh("ControlBox", "painted_metal", (46, 44, 40))
        box.box((1.2, 1.8, 0.4), cf(px, py, pz, ry=deg(yaw)), bevel=0.06)
        box.box((0.2, 1.2, 0.2), cf(px, py - 1.4, pz, ry=deg(yaw)) @ cf(0, 0, 0.15), bevel=0.04)  # conduit down
        buttons = kit.Mesh("Buttons", "worn_plastic", (190, 170, 60))
        for k_, y in enumerate((py + 0.45, py - 0.05)):
            buttons.cyl(0.08, 0.16, cf(px, y, pz, ry=deg(yaw)) @ cf(0, 0, -0.22, ry=deg(90)), segments=10, bevel=0.02)
        buttons.box((0.5, 0.18, 0.02), cf(px, py + 0.72, pz, ry=deg(yaw)) @ cf(0, 0, -0.21), bevel=0.0)  # label
        meshes += [box, buttons]
    if lamp:
        # A wire guard round the lamp under the cross beam.
        guard = kit.Mesh("LampGuard", "painted_metal", (60, 58, 54))
        ly = H - 0.6
        for s in (-1, 1):
            guard.box((2.5, 0.05, 0.05), cf(0, ly - 0.3, s * 1.2), bevel=0.0)
            guard.box((0.05, 0.05, 2.5), cf(s * 1.2, ly - 0.3, 0), bevel=0.0)
            for t in (-1, 1):
                guard.box((0.05, 0.5, 0.05), cf(s * 1.2, ly - 0.05, t * 1.2), bevel=0.0)
        guard.box((2.4, 0.05, 0.05), cf(0, ly - 0.32, 0), bevel=0.0)
        guard.box((0.05, 0.05, 2.4), cf(0, ly - 0.32, 0), bevel=0.0)
        meshes.append(guard)
    return kit.finish(meshes, name, budget=2400)
