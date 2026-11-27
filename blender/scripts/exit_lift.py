"""The exit lift in every level (ExitLift.luau), for the 11-stud ceilings:
a 16 x 16 stud deck (Config.LIFT_SIZE, room for the armoury on the -X
side), corner posts, header and hoist ropes, a guard round the lamp, and
the control box on the +X +Z post. The amber edge strips, the lamp and its
sign stay the game's own parts (they change colour when the quota's met)."""
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent))

import lift_cage  # noqa: E402

HALF = 8.0
lift_cage.build("exit_lift", 11.0, (90, 88, 80), panel=(HALF - 0.4, 3.6, HALF - 0.4, 45), lamp=True, half=HALF)
