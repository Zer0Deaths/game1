"""Clipboard lying flat (1.3 x 1.8 studs), a sheet under its steel clip."""
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent / "lib"))

import kit  # noqa: E402
from kit import cf, deg  # noqa: E402

board = kit.Mesh("Board", "wood", (120, 90, 56))
board.box((1.3, 0.06, 1.8), cf(0, 0.03, 0), bevel=0.02)
clip = kit.Mesh("Clip", "brushed_metal", (170, 168, 160))
clip.box((0.7, 0.07, 0.3), cf(0, 0.1, -0.72), bevel=0.025)
clip.cyl(0.6, 0.05, cf(0, 0.14, -0.62), segments=8, bevel=0.01)
paper = kit.Mesh("Sheet", "paper", (226, 222, 206))
paper.sheet(1.1, 1.45, cf(0, 0.075, 0.08, rx=deg(-90)), curl=0.04, wave=0.004, seed=3)
kit.finish([board, clip, paper], "clipboard")
