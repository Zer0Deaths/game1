"""The descent lift in the safehouse (Safehouse.luau), 12-stud ceiling:
deck in a worn concrete kerb, ochre corner posts on concrete footings,
header and hoist ropes. Its DESCENT sign and the amber ready button stay
the game's own parts."""
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent))

import lift_cage  # noqa: E402

lift_cage.build("descent_lift", 12.0, (128, 116, 74), footings=True, kerb=True)
