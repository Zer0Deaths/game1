"""Steel shelving rack (8 wide x 7.4 tall x 2.4 deep studs), the storage
rooms' racks: four slotted-angle uprights in faded blue, four steel decks
(tops at 0.475, 2.675, 4.875, 7.075, where LevelBuilder puts the boxes and
the loot gaps), cross-bracing on the back and ends, foot plates."""
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent / "lib"))

import kit  # noqa: E402
from kit import cf, deg  # noqa: E402

W, D, H = 8.0, 2.4, 7.4
LEVELS = [0.4 + k * 2.2 for k in range(4)]  # shelf centres (decks 0.15 thick)
import math

uprights = kit.Mesh("Uprights", "painted_metal", (70, 96, 140))
for sx in (-1, 1):
    for sz in (-1, 1):
        x, z = sx * (W / 2 - 0.02), sz * (D / 2 - 0.02)
        # Slotted angle: two flanges at a right angle, opening inwards.
        uprights.box((0.26, H, 0.05), cf(x - sx * 0.1, H / 2, z), bevel=0.012)
        uprights.box((0.05, H, 0.26), cf(x, H / 2, z - sz * 0.1), bevel=0.012)
        uprights.box((0.4, 0.04, 0.4), cf(x - sx * 0.08, 0.02, z - sz * 0.08), bevel=0.012)  # foot plate
decks = kit.Mesh("Shelves", "steel_plate", (120, 122, 120))
for y in LEVELS:
    decks.box((W - 0.06, 0.05, D - 0.06), cf(0, y + 0.05, 0), bevel=0.012)
    for sz in (-1, 1):  # box beams front and back, under the deck
        decks.box((W - 0.06, 0.22, 0.06), cf(0, y - 0.065, sz * (D / 2 - 0.05)), bevel=0.015)
        decks.box((W - 0.06, 0.05, 0.16), cf(0, y - 0.15, sz * (D / 2 - 0.12)), bevel=0.012)
bracing = kit.Mesh("Bracing", "painted_metal", (54, 62, 74))
# X-braces on the back between the lower and upper decks, and on each end.
for y0, y1 in ((LEVELS[0], LEVELS[2]), (LEVELS[2], LEVELS[3])):
    h = y1 - y0
    for sx in (-1, 1):
        ang = math.atan2(h, W / 2 - 0.3) * sx
        L = math.hypot(h, W / 2 - 0.3)
        bracing.box((L, 0.1, 0.02), cf(sx * (W / 4), (y0 + y1) / 2, D / 2 + 0.01, rz=ang), bevel=0.0)
for sx in (-1, 1):
    for y0, y1 in ((LEVELS[0], LEVELS[1]), (LEVELS[1], LEVELS[2]), (LEVELS[2], LEVELS[3])):
        h = y1 - y0
        ang = math.atan2(h, D - 0.2)
        L = math.hypot(h, D - 0.2)
        bracing.box((0.02, 0.1, L), cf(sx * (W / 2 + 0.01), (y0 + y1) / 2, 0, rx=-ang if (y0 // 2.2) % 2 == 0 else ang), bevel=0.0)
bolts = kit.Mesh("Bolts", "brushed_metal", (150, 150, 146))
for sx in (-1, 1):
    for sz in (-1, 1):
        for y in LEVELS:
            bolts.cyl(0.05, 0.05, cf(sx * (W / 2 + 0.03), y - 0.06, sz * (D / 2 - 0.12)), segments=6, bevel=0.0)
kit.finish([uprights, decks, bracing, bolts], "shelf_rack")
