"""The Tenant: SHIFT's hunter, as 15 R15 body-part meshes (under 20k tris).

Original design (no other game's entity): tall, thin, near-black and
featureless, and wrong in its proportions rather than in any detail you
could name:
  * the head sits too low, slung out in front of the chest below the
    shoulders, which are hunched up higher than it, a little lopsided,
  * the arms are too long, the forearm longer than the upper arm, and the
    fingertips hang past the shins,
  * the elbows bend the wrong way: at rest they're pushed forward, the
    hands trailing back, and the walk bends them further that way,
  * it walks on the balls of its feet, heels never touching the floor,
  * a shallow dish where a face should be, and in it a bone-white face
    (Face, welded to the Head): smooth, two deep sockets too far apart,
    not level and not the same size, and a small round mouth hanging open
    off-centre (FaceHoles). Against the near-black body
    it's the part you see first in the dark, and it's turned down to the
    floor until it notices you; then it lifts,
  * a knotted spine, a ribcage you can count.

Rigid segments, one mesh per R15 part (Head, UpperTorso, LowerTorso,
Left/Right UpperArm, LowerArm, Hand, UpperLeg, LowerLeg, Foot), each
modelled in place in the rest pose below, plus Face and FaceHoles riding
on the Head (kit.Mesh attach). "FaceLight" in the joints is not a joint:
it's the point just in front of the face where the game hangs the faint
light the face catches. The joint positions are written
into the manifest ("joints"), and EntityRig builds the rig from them, so
the skeleton the game animates is exactly the one modelled here.

Frame: feet on y = 0, facing -Z, the Tenant's left at -X (Roblox R15),
at Config.TENANT.height = 9.5 (the game scales it for other heights).
Skin: SHIFT_TenantSkin (the 1024 PBR set in assets/textures), near-black.
"""
import math
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent / "lib"))

import json  # noqa: E402

import kit  # noqa: E402
from kit import cf  # noqa: E402
import bmesh  # noqa: E402
from mathutils import Matrix, Vector  # noqa: E402

SKIN = (20, 18, 18)
BONE = (226, 221, 208)

# Rest pose joints (studs). Shared with EntityRig through the manifest.
# A little lopsided on purpose: the left shoulder sits lower than the right.
JOINTS = {
    "Root": (0.0, 4.7, 0.05),
    "Waist": (0.0, 5.2, 0.06),
    "Neck": (0.0, 7.64, -0.7),
}
for side, s in (("Left", -1), ("Right", 1)):
    JOINTS[f"{side}Shoulder"] = (s * 0.8, 7.5 if s < 0 else 7.64, -0.5)
    JOINTS[f"{side}Elbow"] = (s * 1.0, 5.18, -0.96)  # forward of the shoulder-wrist line: bent the wrong way
    JOINTS[f"{side}Wrist"] = (s * 1.02, 2.42, -0.28)
    JOINTS[f"{side}Hip"] = (s * 0.36, 4.6, 0.06)
    JOINTS[f"{side}Knee"] = (s * 0.42, 2.42, -0.2)
    JOINTS[f"{side}Ankle"] = (s * 0.4, 0.62, 0.14)  # heel held high


def V(t):
    return Vector(t)


def part(name):
    return kit.Mesh(name, "skin", SKIN)


def ribbed(r0, r1, n, rib=0.028):
    """A profile that swells and dips n times: ribs under thin skin."""
    out = []
    for i in range(n + 1):
        t = i / n
        r = r0 + (r1 - r0) * t
        out.append((t, r + (rib if i % 2 == 1 else 0.0)))
    return out


# -- LowerTorso: a narrow, bony pelvis --------------------------------------
lower = part("LowerTorso")
lower.lathe((0, 4.42, 0.1), (0, 5.36, 0.07), [(0, 0.22), (0.2, 0.36), (0.5, 0.41), (0.8, 0.32), (1, 0.26)], segments=18, flat=(1.0, 0.6))
for s in (-1, 1):
    lower.ball(0.15, cf(s * 0.36, 4.6, 0.06), segments=12)

# -- UpperTorso: a sunken belly, a countable ribcage hunched well forward,
# a knotted spine, and shoulders hunched up higher than the head ------------
upper = part("UpperTorso")
BELLY0, BELLY1 = V((0, 5.12, 0.1)), V((0, 6.4, 0.02))
RIB0, RIB1 = V((0, 6.15, 0.04)), V((0, 7.86, -0.58))
upper.lathe(tuple(BELLY0), tuple(BELLY1), [(0, 0.3), (0.45, 0.23), (1, 0.36)], segments=20, flat=(1.0, 0.58))
upper.lathe(tuple(RIB0), tuple(RIB1), [(t * 0.82, r) for t, r in ribbed(0.4, 0.56, 10, rib=0.03)] + [(0.9, 0.52), (0.96, 0.4), (1.0, 0.2)], segments=22, flat=(1.12, 0.52))
for i in range(9):  # vertebrae down the back, under the skin
    y = 5.5 + i * 0.27
    if y < 6.3:
        z = BELLY0.z + (BELLY1.z - BELLY0.z) * (y - BELLY0.y) / (BELLY1.y - BELLY0.y) + 0.3 * 0.58 * 0.8
    else:
        z = RIB0.z + (RIB1.z - RIB0.z) * (y - RIB0.y) / (RIB1.y - RIB0.y) + 0.5 * 0.52 * 0.95
    upper.ball(0.06, cf(0, y, z), segments=10, scale=(1.4, 0.65, 0.7))
for s in (-1, 1):
    top = JOINTS["LeftShoulder" if s < 0 else "RightShoulder"]
    upper.lathe((s * 0.3, 6.9, 0.14), (s * 0.48, top[1] + 0.42, -0.12), [(0, 0.1), (0.35, 0.25), (0.75, 0.24), (1, 0.18)], segments=14, flat=(1.15, 0.62))  # shoulder blade, hunched up
    upper.lathe((0, 7.92, -0.4), top, [(0, 0.22), (0.6, 0.18), (1, 0.15)], segments=12)  # the slope down to the shoulder
    upper.ball(0.19, cf(*top), segments=14)  # shoulder knob

# -- Head: hung low and forward off a thin neck out of the front of the
# chest, crown first, the blank face turned down to the floor (it lifts
# when it listens); a long egg with a shallow dish where a face should be --
head = part("Head")
CHIN, CROWN = V((0.04, 6.5, -0.98)), V((0.1, 7.12, -1.82))
head.lathe(tuple(CHIN), tuple(CROWN), [(0, 0.08), (0.08, 0.19), (0.25, 0.28), (0.5, 0.32), (0.75, 0.31), (0.9, 0.24), (1, 0.1)], segments=22, flat=(0.88, 1.12))  # = HEAD_PROFILE, HEAD_FLAT below
axis = (CROWN - CHIN).normalized()
face = V((0, -1, 0)) - axis * V((0, -1, 0)).dot(axis)
face.normalize()
for v in head.bm.verts:
    rel = v.co - CHIN
    t = rel.dot(axis) / (CROWN - CHIN).length
    radial = rel - axis * rel.dot(axis)
    if radial.length < 1e-4:
        continue
    toward = radial.normalized().dot(face)  # 1 = straight out of the face side
    if toward > 0.35 and 0.18 < t < 0.8:
        w = (toward - 0.35) / 0.65 * math.sin((t - 0.18) / 0.62 * math.pi)
        v.co += radial.normalized() * -0.075 * w  # press the face in

# -- The face: bone-white, set into the dish. Built on the same surface as
# the head (same profile, same dish), lifted a hair off it, over an oval
# from a third to four fifths of the way up; then two pits and a mouth.
HEAD_PROFILE = [(0, 0.08), (0.08, 0.19), (0.25, 0.28), (0.5, 0.32), (0.75, 0.31), (0.9, 0.24), (1, 0.1)]
HEAD_FLAT = (0.88, 1.12)
H_LEN = (CROWN - CHIN).length
_side = axis.cross(V((0, 0, 1)))
if _side.length < 1e-4:
    _side = axis.cross(V((1, 0, 0)))
_side.normalize()
_fwd = _side.cross(axis)  # the lathe's own cross-section frame (kit.lathe)
A0 = math.atan2(face.dot(_fwd) / HEAD_FLAT[1], face.dot(_side) / HEAD_FLAT[0])  # the angle round the head that faces out of the dish


SEGS = 22


def _ring_vert(i, j):
    """Vertex j of ring i of the head, exactly as kit.lathe made it and the
    dish above pressed it in."""
    t, r = HEAD_PROFILE[i]
    a = 2 * math.pi * (j % SEGS) / SEGS
    v = CHIN + (CROWN - CHIN) * t + _side * (math.cos(a) * r * HEAD_FLAT[0]) + _fwd * (math.sin(a) * r * HEAD_FLAT[1])
    rel = v - CHIN
    tt = rel.dot(axis) / H_LEN
    radial = rel - axis * rel.dot(axis)
    toward = radial.normalized().dot(face)
    if toward > 0.35 and 0.18 < tt < 0.8:
        v = v + radial.normalized() * (-0.075 * (toward - 0.35) / 0.65 * math.sin((tt - 0.18) / 0.62 * math.pi))
    return v


def on_head(t, ang, lift=0.0):
    """A point on the head's faceted, dished surface (so the face sits on it
    exactly): t along it, chin to crown, ang (radians) round it from the
    middle of the face; `lift` off it. Returns the point and its outward."""
    i = max(k for k in range(len(HEAD_PROFILE) - 1) if HEAD_PROFILE[k][0] <= t)
    t0, t1 = HEAD_PROFILE[i][0], HEAD_PROFILE[i + 1][0]
    u = (t - t0) / (t1 - t0)
    a = (A0 + ang) % (2 * math.pi)
    jf = a / (2 * math.pi) * SEGS
    j = int(math.floor(jf))
    w = jf - j
    p00, p01 = _ring_vert(i, j), _ring_vert(i, j + 1)
    p10, p11 = _ring_vert(i + 1, j), _ring_vert(i + 1, j + 1)
    p = (p00 * (1 - w) + p01 * w) * (1 - u) + (p10 * (1 - w) + p11 * w) * u
    across = (p01 - p00) * (1 - u) + (p11 - p10) * u
    along = (p10 - p00) * (1 - w) + (p11 - p01) * w
    out = along.cross(across).normalized()
    radial = p - CHIN - axis * (p - CHIN).dot(axis)
    if out.dot(radial) < 0:
        out = -out
    return p + out * lift, out


FACE_T, FACE_HALF_T, FACE_HALF_ANG = 0.52, 0.27, 0.95
facemesh = kit.Mesh("Face", "plaster", BONE, attach="Head")
fbm = facemesh.bm
RINGS, AROUND = 7, 28
centre_v = fbm.verts.new(on_head(FACE_T, 0.0, 0.016)[0])
rings = []
for i in range(1, RINGS + 1):
    rho = i / RINGS
    ring = []
    for j in range(AROUND):
        th = 2 * math.pi * j / AROUND
        x, y = rho * math.cos(th), rho * math.sin(th)
        ring.append(fbm.verts.new(on_head(FACE_T + y * FACE_HALF_T, x * FACE_HALF_ANG, 0.016)[0]))
    rings.append(ring)
for j in range(AROUND):
    k = (j + 1) % AROUND
    fbm.faces.new((centre_v, rings[0][j], rings[0][k]))
for i in range(RINGS - 1):
    for j in range(AROUND):
        k = (j + 1) % AROUND
        fbm.faces.new((rings[i][j], rings[i + 1][j], rings[i + 1][k], rings[i][k]))
fbm.normal_update()
_, out_mid = on_head(FACE_T, 0.0)
if sum(f.normal.dot(out_mid) for f in fbm.faces) < 0:  # face it outwards, away from the head
    bmesh.ops.reverse_faces(fbm, faces=list(fbm.faces))

holes = kit.Mesh("FaceHoles", "skin", (8, 7, 7), attach="Head")


def pit(t, ang, size, depth):
    """A dark oval set into the face: size (across, along), depth out of it."""
    at, out = on_head(t, ang, 0.006)
    up = axis - out * axis.dot(out)
    up.normalize()
    across = up.cross(out)
    m = Matrix(((across.x, up.x, out.x, at.x), (across.y, up.y, out.y, at.y),
                    (across.z, up.z, out.z, at.z), (0, 0, 0, 1)))
    holes.ball(1.0, m, segments=12, scale=(size[0], size[1], depth))


# Everything on it is slightly wrong: two deep sockets, too far apart, not
# level and not the same size (lopsided like its shoulders), and a small
# round mouth hanging open, off-centre.
pit(0.61, -0.44, (0.078, 0.066), 0.034)
pit(0.55, 0.42, (0.064, 0.056), 0.034)
pit(0.35, 0.1, (0.045, 0.07), 0.03)

# Where the game hangs the faint light the face catches: just in front of it.
_glow_at, _ = on_head(FACE_T, 0.0)
JOINTS["FaceLight"] = tuple(round(c, 4) for c in (_glow_at + face * 0.9))

head.lathe((0, 7.86, -0.56), (0.06, 7.0, -1.24), [(0, 0.15), (0.5, 0.1), (1, 0.12)], segments=12)  # neck

# -- Arms: too long, the elbow bent the wrong way, hands past the knees ------
def arm(side, s):
    sh, el, wr = V(JOINTS[f"{side}Shoulder"]), V(JOINTS[f"{side}Elbow"]), V(JOINTS[f"{side}Wrist"])
    ua = part(f"{side}UpperArm")
    ua.lathe(tuple(sh), tuple(el), [(0, 0.17), (0.15, 0.15), (0.6, 0.115), (0.9, 0.12), (1, 0.13)], segments=12)
    ua.ball(0.14, cf(*el), segments=12)
    ua.ball(0.085, cf(el.x, el.y + 0.04, el.z - 0.12), segments=10)  # the joint bulging out the front
    la = part(f"{side}LowerArm")
    la.lathe(tuple(el), tuple(wr), [(0, 0.12), (0.2, 0.12), (0.7, 0.085), (1, 0.07)], segments=12)
    la.ball(0.085, cf(*wr), segments=10)
    hand = part(f"{side}Hand")
    knuckle = wr + V((s * 0.01, -0.6, -0.02))
    hand.lathe(tuple(wr), tuple(knuckle), [(0, 0.1), (0.4, 0.15), (1, 0.13)], segments=10, flat=(0.42, 1.0))
    for i, (dz, length) in enumerate(((-0.12, 1.0), (-0.04, 1.2), (0.04, 1.25), (0.12, 1.08))):
        base = knuckle + V((0, 0.02, dz))
        mid = base + V((-s * 0.05, -length * 0.55, dz * 0.25 + 0.04))
        tip = mid + V((-s * 0.1, -length * 0.45, 0.1))  # curling in and back
        hand.lathe(tuple(base), tuple(mid), [(0, 0.05), (0.5, 0.042), (1, 0.047)], segments=6)
        hand.lathe(tuple(mid), tuple(tip), [(0, 0.044), (0.6, 0.035), (1, 0.02)], segments=6)
    thumb0 = wr + V((-s * 0.06, -0.3, -0.12))
    hand.lathe(tuple(thumb0), tuple(thumb0 + V((-s * 0.12, -0.55, -0.1))), [(0, 0.05), (0.6, 0.04), (1, 0.02)], segments=6)
    return [ua, la, hand]


# -- Legs: long and thin, up on the balls of long, narrow feet ---------------
def leg(side, s):
    hp, kn, an = V(JOINTS[f"{side}Hip"]), V(JOINTS[f"{side}Knee"]), V(JOINTS[f"{side}Ankle"])
    ul = part(f"{side}UpperLeg")
    ul.lathe(tuple(hp), tuple(kn), [(0, 0.2), (0.2, 0.19), (0.7, 0.135), (1, 0.14)], segments=14)
    ul.ball(0.155, cf(*kn), segments=12)
    ll = part(f"{side}LowerLeg")
    ll.lathe(tuple(kn), tuple(an), [(0, 0.13), (0.25, 0.145), (0.65, 0.1), (1, 0.075)], segments=12)
    foot = part(f"{side}Foot")
    ball = an + V((s * 0.01, -0.54, -0.5))
    foot.ball(0.09, cf(an.x, an.y, an.z + 0.04), segments=8)  # heel, up off the floor
    foot.lathe(tuple(an), tuple(ball), [(0, 0.085), (0.5, 0.1), (1, 0.085)], segments=10, flat=(1.15, 0.8))
    for dx, length in ((-0.07, 0.42), (0.0, 0.5), (0.07, 0.4)):
        t0 = ball + V((dx * 1.2, -0.02, 0.02))
        t1 = t0 + V((dx * 0.8, -0.03, -length))
        foot.lathe(tuple(t0), tuple(t1), [(0, 0.045), (0.6, 0.036), (1, 0.022)], segments=6)
    return [ul, ll, foot]


meshes = [head, facemesh, holes, upper, lower]
for side, s in (("Left", -1), ("Right", 1)):
    meshes += arm(side, s)
for side, s in (("Left", -1), ("Right", 1)):
    meshes += leg(side, s)

out = kit.finish(meshes, "tenant", budget=20000)
# The skeleton travels with the model: EntityRig reads these joints.
data = json.loads(out.read_text())
data["joints"] = {k: [round(c, 4) for c in v] for k, v in JOINTS.items()}
out.write_text(json.dumps(data, indent=1))
