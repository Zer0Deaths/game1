"""Cork notice board (5 x 3.5 studs) in a wood frame, with pinned sheets.
Front -Z; the back sits on the wall. Any writing is drawn by the game."""
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent / "lib"))

import kit  # noqa: E402
from kit import cf, deg  # noqa: E402

cork = kit.Mesh("Cork", "cardboard", (150, 112, 70))
cork.box((4.7, 3.2, 0.1), cf(0, 1.75, 0.0), bevel=0.02)
frame = kit.Mesh("Frame", "wood", (96, 78, 50))
frame.box((5.0, 0.18, 0.2), cf(0, 0.09, -0.02), bevel=0.05)
frame.box((5.0, 0.18, 0.2), cf(0, 3.41, -0.02), bevel=0.05)
frame.box((0.18, 3.5, 0.2), cf(-2.41, 1.75, -0.02), bevel=0.05)
frame.box((0.18, 3.5, 0.2), cf(2.41, 1.75, -0.02), bevel=0.05)
paper = kit.Mesh("Sheets", "paper", (222, 216, 196))
pins = kit.Mesh("Pins", "worn_plastic", (120, 52, 40))
for i, (x, y, w, h, tilt) in enumerate(((-1.4, 2.3, 1.2, 1.5, 3), (0.2, 2.1, 1.0, 1.3, -2), (1.5, 2.5, 1.1, 1.0, 5), (-0.6, 0.9, 1.3, 0.9, -4))):
    paper.sheet(w, h, cf(x, y, -0.07, rz=deg(tilt)), curl=0.06, wave=0.01, seed=i)
    pins.ball(0.06, cf(x, y + h / 2 - 0.12, -0.1), segments=8)
kit.finish([cork, frame, paper, pins], "notice_board")
