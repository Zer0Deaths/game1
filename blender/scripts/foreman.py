"""The Foreman: SHIFT's last-minute entity, as R15 body-part meshes (under 20k tris).

Original design (no other game's entity): a broad, square, stiff figure
in a work jacket and an old hard hat, with a heavy ring of keys on its
belt. It is wrong in a quieter way than the Tenant:
  * there is no head. Under the brim, inside the turned-up collar, there's
    a head-shaped hole of pure black (a Neon black mesh, so no light ever
    lands on it). The hat sits on nothing.
  * the shoulders are far too broad for a body with no head, and the arms
    are too long: the gloved hands hang at the knees,
  * everything else is ordinary and tidy: buttoned jacket, belt, boots,
    reflective bands that catch your torch before you see the rest of it.
It stands bolt upright and walks stiff-legged, and it never turns to look.

Rigid segments, one mesh per R15 part, each modelled in place in the rest
pose below, plus a few welded extras (hat void, belt, keys, reflective
bands) that carry their own look and say which part they ride on
(kit.Mesh attach). The joints go into the manifest ("joints") like the
Tenant's, so EntityRig builds the rig from them.

Frame: feet on y = 0, facing -Z, its left at -X (Roblox R15), at
Config.FOREMAN.height = 8.6 (the game scales it for other heights).
"""
import math
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent / "lib"))

import json  # noqa: E402

import bmesh  # noqa: E402
import kit  # noqa: E402
from kit import cf  # noqa: E402
from mathutils import Matrix, Vector  # noqa: E402

JACKET = (56, 51, 44)  # a donkey jacket gone the colour of the corridors
TROUSERS = (44, 42, 39)
GLOVE = (82, 70, 52)
BOOT = (30, 28, 26)
BELT = (36, 31, 27)
HAT = (178, 162, 112)  # an old white hard hat, yellowed
BAND = (176, 176, 166)  # reflective tape (Foil: it flares in a torch beam)
KEYS = (150, 140, 112)
VOID = (0, 0, 0)

JOINTS = {
    "Root": (0.0, 4.0, 0.0),
    "Waist": (0.0, 4.6, 0.0),
    "Neck": (0.0, 7.4, 0.0),
}
for side, s in (("Left", -1), ("Right", 1)):
    JOINTS[f"{side}Shoulder"] = (s * 1.86, 6.85, -0.06)
    JOINTS[f"{side}Elbow"] = (s * 2.06, 4.75, 0.02)
    JOINTS[f"{side}Wrist"] = (s * 2.1, 2.85, -0.1)
    JOINTS[f"{side}Hip"] = (s * 0.56, 3.85, 0.0)
    JOINTS[f"{side}Knee"] = (s * 0.6, 2.25, -0.05)
    JOINTS[f"{side}Ankle"] = (s * 0.6, 0.72, 0.05)


def V(t):
    return Vector(t)


def part(name, look, colour, attach=None):
    return kit.Mesh(name, look, colour, attach=attach)


def band(name, attach, a, b, r, flat=(1.0, 1.0)):
    """A strip of reflective tape round a limb or the body, between a and b."""
    m = part(name, "foil", BAND, attach)
    m.lathe(a, b, [(0, r), (0.5, r), (1, r)], segments=20, flat=flat)
    return m


meshes = []

# -- LowerTorso: hips, a belt, and the keys ----------------------------------
lower = part("LowerTorso", "fabric", TROUSERS)
lower.lathe((0, 3.5, 0), (0, 4.7, 0), [(0, 0.75), (0.25, 0.95), (0.7, 0.98), (1, 0.74)], segments=20, flat=(1.12, 0.62))
meshes.append(lower)
belt = part("Belt", "rubber", BELT, "LowerTorso")
belt.lathe((0, 4.3, 0), (0, 4.54, 0), [(0, 1.04), (0.5, 1.05), (1, 1.04)], segments=24, flat=(1.12, 0.68))
belt.box((0.34, 0.3, 0.06), cf(0, 4.42, -0.72))  # buckle plate
meshes.append(belt)

keys = part("Keys", "brushed_metal", KEYS, "LowerTorso")
RING = V((1.2, 3.9, -0.12))
keys.box((0.08, 0.42, 0.1), cf(1.17, 4.22, -0.12))  # the clip off the belt
keys.torus(0.26, 0.028, cf(*RING), segments=20, sides=6)
for i, b in enumerate((-0.95, -0.62, -0.3, 0.0, 0.28, 0.6, 0.9)):
    p = RING + V((0.0, -0.26 * math.cos(b), 0.26 * math.sin(b)))
    rx = b * 0.55 + (0.12 if i % 2 else -0.08)
    down = V((0.0, -math.cos(rx), -math.sin(rx)))
    length = 0.36 + 0.08 * ((i * 5) % 3)
    keys.box((0.07, 0.15, 0.2), cf(*(p + down * 0.08), rx=rx))  # the bow
    keys.box((0.045, length, 0.09), cf(*(p + down * (0.16 + length / 2)), rx=rx))  # the blade
    keys.box((0.05, 0.08, 0.06), cf(*(p + down * (0.16 + length * 0.8) + V((0, 0, 0.06))), rx=rx))  # a tooth
meshes.append(keys)

# -- UpperTorso: a buttoned jacket over a chest that widens into shoulders far
# too broad, hunched up round an empty collar --------------------------------
upper = part("UpperTorso", "fabric", JACKET)
upper.lathe((0, 4.55, 0), (0, 7.42, -0.04), [(0, 0.84), (0.15, 0.86), (0.35, 0.95), (0.55, 1.1), (0.75, 1.24), (0.88, 1.3), (0.95, 1.22), (1, 1.0)], segments=24, flat=(1.4, 0.66))
for s in (-1, 1):
    upper.ball(0.62, cf(s * 1.64, 6.98, -0.1), segments=18, scale=(1.12, 0.82, 1.02))  # shoulders, hunched up
    upper.lathe((s * 0.35, 7.42, 0.04), (s * 1.5, 7.08, -0.06), [(0, 0.42), (0.6, 0.46), (1, 0.4)], segments=14, flat=(1.0, 1.25))  # the slope up to the collar
upper.lathe((0, 7.2, 0.02), (0, 7.62, 0.04), [(0, 0.64), (0.5, 0.68), (1, 0.72)], segments=20, flat=(1.0, 0.92))  # turned-up collar
for i in range(4):  # buttons, done up to the top
    upper.ball(0.075, cf(0.04, 4.95 + i * 0.6, -0.6 - i * 0.07), segments=8, scale=(1, 1, 0.5))
for s in (-1, 1):
    upper.box((0.7, 0.06, 0.06), cf(s * 0.66, 5.4, -0.66))  # pocket flaps
meshes.append(upper)
meshes.append(band("ChestBand", "UpperTorso", (0, 5.62, 0), (0, 5.9, 0), 1.09, flat=(1.4, 0.66)))

# -- Head: a hard hat over nothing ---------------------------------------------
head = part("Head", "worn_plastic", HAT)
head.ball(0.68, cf(0, 8.2, 0.02), segments=22, scale=(1.0, 0.72, 1.12))  # the shell
head.lathe((0, 8.06, -0.12), (0, 8.15, -0.12), [(0, 0.88), (0.5, 0.9), (1, 0.88)], segments=26, flat=(0.92, 1.18))  # brim, peaked at the front
# Tip the hat forward a little, so the brim hides more of the hole under it.
tilt = Matrix.Rotation(-0.14, 3, "X")
bmesh.ops.rotate(head.bm, verts=head.bm.verts, cent=V((0, 7.8, 0)), matrix=tilt)
meshes.append(head)
void = part("FaceVoid", "neon", VOID, "Head")
void.ball(0.52, cf(0, 7.8, -0.04), segments=20, scale=(0.95, 0.92, 1.0))  # where the head should be: nothing
meshes.append(void)


# -- Arms: heavy and too long, gloved hands hanging at the knees ---------------
def arm(side, s):
    sh, el, wr = V(JOINTS[f"{side}Shoulder"]), V(JOINTS[f"{side}Elbow"]), V(JOINTS[f"{side}Wrist"])
    ua = part(f"{side}UpperArm", "fabric", JACKET)
    ua.lathe(tuple(sh), tuple(el), [(0, 0.54), (0.2, 0.53), (0.8, 0.45), (1, 0.44)], segments=16)
    ua.ball(0.43, cf(*el), segments=14)
    la = part(f"{side}LowerArm", "fabric", JACKET)
    la.lathe(tuple(el), tuple(wr), [(0, 0.43), (0.6, 0.4), (0.9, 0.42), (1, 0.38)], segments=16)
    cuff = band(f"{side}CuffBand", f"{side}LowerArm", tuple(wr + (el - wr) * 0.14), tuple(wr + (el - wr) * 0.24), 0.435)
    hand = part(f"{side}Hand", "fabric", GLOVE)
    knuckle = wr + V((s * 0.02, -0.7, -0.02))
    hand.lathe(tuple(wr + V((0, 0.14, 0))), tuple(knuckle), [(0, 0.36), (0.4, 0.44), (1, 0.4)], segments=14, flat=(0.55, 1.0))
    for dz, length in ((-0.22, 0.6), (-0.075, 0.7), (0.075, 0.68), (0.22, 0.56)):
        base = knuckle + V((0, 0.03, dz))
        mid = base + V((-s * 0.04, -length * 0.55, 0.03))
        tip = mid + V((-s * 0.12, -length * 0.4, 0.07))  # curled in, heavy
        hand.lathe(tuple(base), tuple(mid), [(0, 0.125), (0.5, 0.12), (1, 0.12)], segments=8)
        hand.lathe(tuple(mid), tuple(tip), [(0, 0.12), (0.6, 0.105), (1, 0.075)], segments=8)
    thumb0 = wr + V((-s * 0.12, -0.32, -0.26))
    hand.lathe(tuple(thumb0), tuple(thumb0 + V((-s * 0.14, -0.5, -0.14))), [(0, 0.135), (0.6, 0.115), (1, 0.08)], segments=8)
    return [ua, la, cuff, hand]


# -- Legs: thick and straight, in heavy boots ----------------------------------
def leg(side, s):
    hp, kn, an = V(JOINTS[f"{side}Hip"]), V(JOINTS[f"{side}Knee"]), V(JOINTS[f"{side}Ankle"])
    ul = part(f"{side}UpperLeg", "fabric", TROUSERS)
    ul.lathe(tuple(hp + V((0, 0.2, 0))), tuple(kn), [(0, 0.58), (0.3, 0.57), (0.85, 0.48), (1, 0.47)], segments=16)
    ul.ball(0.45, cf(*kn), segments=14)
    ll = part(f"{side}LowerLeg", "fabric", TROUSERS)
    ll.lathe(tuple(kn), tuple(an + V((0, 0.4, 0))), [(0, 0.45), (0.5, 0.42), (1, 0.4)], segments=16)
    shin = band(f"{side}ShinBand", f"{side}LowerLeg", (an.x, 1.42, an.z - 0.02), (an.x, 1.62, an.z - 0.03), 0.435)
    foot = part(f"{side}Foot", "rubber", BOOT)
    foot.lathe((an.x, 1.12, an.z), (an.x, 0.42, an.z), [(0, 0.47), (0.5, 0.48), (1, 0.48)], segments=16)  # boot top, over the trouser leg
    foot.lathe((an.x, 0.34, an.z + 0.42), (an.x + s * 0.02, 0.32, an.z - 1.02), [(0, 0.32), (0.3, 0.4), (0.75, 0.4), (1, 0.3)], segments=16, flat=(1.0, 0.72))
    foot.box((0.84, 0.16, 1.62), cf(an.x + s * 0.01, 0.08, an.z - 0.3), bevel=0.05)  # sole, flat on the floor
    return [ul, ll, shin, foot]


for side, s in (("Left", -1), ("Right", 1)):
    meshes += arm(side, s)
for side, s in (("Left", -1), ("Right", 1)):
    meshes += leg(side, s)

out = kit.finish(meshes, "foreman", budget=20000)
data = json.loads(out.read_text())
data["joints"] = {k: [round(c, 4) for c in v] for k, v in JOINTS.items()}
out.write_text(json.dumps(data, indent=1))
