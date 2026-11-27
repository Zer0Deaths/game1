"""The exit lift in every level (ExitLift.luau), for the 11-stud ceilings:
deck, corner posts, header and hoist ropes, a guard round the lamp, and
the control box on the +X +Z post. The amber edge strips, the lamp and its
sign stay the game's own parts (they change colour when the quota's met)."""
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent))

import lift_cage  # noqa: E402

lift_cage.build("exit_lift", 11.0, (90, 88, 80), panel=(4.6, 3.6, 4.6, 45), lamp=True)
