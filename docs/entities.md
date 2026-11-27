# SHIFT entity roster (brainstorm)

**Status:** design only, except the Tenant, Lampjaw, the Quiet and the Foreman (built 27 Nov: `src/server/Quiet.luau` and `src/server/Foreman.luau`, tuning in `Config.QUIET` and `Config.FOREMAN`).

All of these are original to SHIFT. None of them is taken from the Backrooms wiki canon (Smilers, Hounds, Facelings and so on) or from another game's roster.

## The rules every entity follows

1. **One rule.** A player can say what the entity does in one sentence after a single encounter.
2. **One tell.** It always gives a sound (and usually a light change) before it can hurt you. Nothing kills you without warning.
3. **One counter.** Every entity has a way to beat it that doesn't need a weapon. You beat it by being quiet, keeping still, picking your route or managing your loot.
4. **The game's own systems are the threat.** Each entity uses something SHIFT already has: noise, the lights, the Shift, loot, the quota timer, the map or the level dressing.
5. **A spread of threats.** Some entities cost you loot, some cost you your way out, and some cost you your life. A run should mix all three.

**Danger scale:**
- 0: harmless (an omen)
- 1: costs loot
- 2: costs time or position
- 3: can separate or strand you
- 4: kills if you break its rule
- 5: kills unless you leave

**Level types:** Carpet (offices), Ward (hospital) and Plant Room (boilers and pipes).

## Already in the game

| Entity | Rule | Danger |
|---|---|---|
| **The Tenant** | Hunts by sound, and arrives after the first Shift. | 4 |
| **Lampjaw** | Drops out of a light fitting; you only see it in its red strobe. | 4 |
| **The Quiet** | The hum dies in a ring around you; make a sound before it comes back and you're taken. From sublevel 3. | 4 |
| **The Foreman** | In the last 90 seconds it switches the level off from the far end toward the lift; be anywhere it has switched off and you're taken. From sublevel 4. | 5 |

## New entities

### 1. The Quiet (built)
- **As built:** the ring is the 3x3 cells around one player. The hum drains for 2 seconds (moving is still safe), then 4 to 6 seconds of silence. Walking, sprinting, jumping or dropping loot in the ring is fatal; a twitch under 0.3 seconds is forgiven. It holds off while a Tenant is hunting, never rings a player a Tenant is near or a light Lampjaw is in (and Lampjaw stays out of the ring), and the lift is always safe. The first time each player meets it they're told "The hum has stopped. Don't move." Its breath (`QUIET_INHALE`) waits on audio uploads; slowed whispers stand in.
- **What it is:** an absence that lives in the fluorescent hum. The safehouse note already warns about it: "if the hum stops, STOP".
- **Behaviour rule:** the hum cuts out in a ring of cells around a player. Anyone who makes noise inside the silence before the hum comes back (4 to 6 seconds) is taken.
- **Sound cue:** the level's hum ducks to dead silence, then there's one slow inhale close by. The tubes in the ring dim but stay on.
- **Counterplay:** freeze. Don't walk, sprint or drop loot until the hum returns. A crew mate outside the ring can still move.
- **Levels:** all three. It's strongest in Carpet, where the hum is loudest.
- **The Shift:** it can't strike during the blackout, but it is twice as likely in the minute after one.
- **Danger:** 4. It's lethal if you ignore it and completely safe if you obey it.
- **Scare type:** terrifying, because the silence itself becomes the jump scare.

### 2. The Clerk
- **What it is:** a stooped, grey office worker who never looks up.
- **Behaviour rule:** it drifts toward the nearest loot nobody is holding (on the floor, on shelves or dropped) and carries it off to its pile in a dead-end room.
- **Sound cue:** a rubber stamp. There's a slow "ka-chunk" every few seconds, which turns to a fast double stamp when it is carrying something.
- **Counterplay:**
  - Keep loot in hands rather than stashing it.
  - Follow the stamping to its pile, which turns into a jackpot room late in a run.
  - It never attacks. Taking loot from its hands makes it shriek, and that is noise the Tenant hears.
- **Levels:** Carpet.
- **The Shift:** during each blackout its pile moves to a new room. The map stops showing the old one.
- **Danger:** 1.
- **Scare type:** annoying, and creepy on a second look.

### 3. The Fitter
- **What it is:** something long and thin that crawls in the ceiling void.
- **Behaviour rule:** it moves cell by cell above the tiles, twisting tubes out, so the lights die along its path and stay dead.
- **Sound cue:** ceiling tiles creaking, then the squeal of a tube twisting in its socket.
- **Counterplay:**
  - Shine the torch on it (a tile lifts and you see fingers). It drops the tube and flees.
  - The tube shatters loudly, so you can use that to pull the Tenant somewhere else. You can also let it darken the far side of the map.
- **Levels:** Carpet and Ward.
- **The Shift:** it rehangs nothing. Dead cells stay dead through Shifts, so a long run gets darker.
- **Danger:** 2.
- **Scare type:** creepy.

### 4. The Patient
- **What it is:** a gurney with a sheet over something that's breathing.
- **Behaviour rule:** it only rolls while it can hear footsteps, and it rolls toward them. It stops dead in silence. If it reaches you, you are "admitted": you're dragged under the sheet and dropped in a random cell with your loot spilled where you were taken.
- **Sound cue:** a squeaking castor that speeds up with its speed, and a wet wheeze under the sheet.
- **Counterplay:**
  - Stop and let it settle.
  - Walk rather than sprint.
  - Use doorways (it can't turn tight corners at speed).
- **Levels:** Ward.
- **The Shift:** in the blackout it rolls freely and silently. When the lights come back, it's somewhere new and closer.
- **Danger:** 3. It strands you and costs your loot.
- **Scare type:** terrifying, because the sound comes before the sight.

### 5. The Foreman (built)
- **As built:** with 90 seconds left the lift dings and it starts switching cells off, furthest from the lift first (by walking route), so only the lift's own cell is still lit 12 seconds before the end. Being in a switched-off cell for half a second is fatal. The dark edge moves exactly fast enough that anyone who'd make the lift by then never sees it, and there's a 5-second head start before the first light goes, so the furthest player can still drop their loot and sprint. Its body walks the edge on the route of whoever it's about to catch. Breakers clunk (the uploaded relay thunk), heavy boots, keys and a two-note whistle (keys and whistle wait on audio uploads). The crew map blacks out every switched-off cell. A Shift in the last 90 seconds pauses it, then it works the routes out again and never leaves anyone in the dark because a wall moved. The Quiet never strikes while it's working. Model: `blender/scripts/foreman.py`, with a built body as the fallback until it's uploaded.
- **Design note (changed from the brainstorm):** the brainstorm had it walking *out* from the lift, which would cut everyone off from the exit. As built, the dark closes *in* on the lift from the far end, which is the same pressure without the contradiction.
- **What it is:** a broad silhouette in a hard hat with a ring of keys, and no face under the brim.
- **Behaviour rule:** when the sublevel timer hits 90 seconds, it walks out from the lift one cell at a time and switches each cell's lights off for good. Anyone in a cell when it goes dark is taken.
- **Sound cue:** a jangling keyring and a flat two-note whistle that carries a long way. Each cell clunks off behind it like a breaker.
- **Counterplay:**
  - Be heading back early.
  - Read the darkness on the map, which spreads from the lift.
  - Only the corridor to the lift stays lit until last.
- **Levels:** all three.
- **The Shift:** a Shift in the last 90 seconds doesn't stop it, but the rewire can open a shortcut past it.
- **Danger:** 5. The timer becomes something you can see.
- **Scare type:** dread.

### 6. The Breather
- **What it is:** a pair of long arms that live in the ductwork.
- **Behaviour rule:**
  - If you stand within 4 studs of a vent grate for 3 seconds, an arm reaches out, grabs the loot in your hands and pulls it into the duct (it's gone).
  - It also empties shelf slots next to vents.
- **Sound cue:** slow breathing from the grate that quickens as you get closer. The grate rattles just before it grabs.
- **Counterplay:**
  - Listen at corners.
  - Don't loot shelves under a vent.
  - Hold nothing when you have to pass one.
- **Levels:** Carpet and Plant Room.
- **The Shift:** after a blackout the vents have moved with the walls, so the safe routes change.
- **Danger:** 1 to 2.
- **Scare type:** annoying, with a good jump scare.

### 7. The Echo
- **What it is:** you hear yourself, about 20 seconds behind.
- **Behaviour rule:** it walks a player's exact route 20 seconds behind them. If you double back into it, it takes you.
- **Sound cue:** your own footsteps, a little too wet and a little too heavy, coming from where you just were.
- **Counterplay:**
  - Keep moving forward and avoid loops.
  - Plan routes that don't retrace your steps.
  - Splitting from the crew means two Echoes.
- **Levels:** Carpet and Plant Room. Long corridors make it worse.
- **The Shift:** the rewire breaks its trail. It loses you until you've walked 20 seconds again, so a Shift is a relief.
- **Danger:** 4.
- **Scare type:** terrifying and paranoid.

### 8. The Mason
- **What it is:** a heavy, slow thing that only exists in the dark.
- **Behaviour rule:** during the Shift blackout, any player who moves more than a few studs can be walled in. The new walls close into a one-cell pocket around them for 30 seconds, or until a crew mate hits the wall from outside three times.
- **Sound cue:** grinding concrete and a slow dragging step during the blackout. The grinding gets closer each time you move.
- **Counterplay:**
  - Stand still in the blackout.
  - Or be in a room when it hits, because rooms keep their walls.
  - Your crew can dig you out.
- **Levels:** all three.
- **The Shift:** it is the Shift. You can only meet it in the blackout.
- **Danger:** 3. It strands you, and the Tenant knows where you are.
- **Scare type:** claustrophobic.

### 9. The Lodger
- **What it is:** a tall figure standing at the far end of a corridor, always facing away from you.
- **Behaviour rule:**
  - It's never there when you arrive and it never moves while you look.
  - Wherever you last saw it is where the Tenant comes in after the next Shift.
- **Sound cue:** none, which is the point. The tubes over it burn slightly brighter.
- **Counterplay:** read it as information. Move your crew away from where it stood before the blackout.
- **Levels:** all three.
- **The Shift:** it's an omen for the Shift and only appears in the minute before one.
- **Danger:** 0. It's useful, but it has the most creep per second of anything here.
- **Scare type:** creepy and uncanny.

### 10. The Knocker
- **What it is:** something in the pipes.
- **Behaviour rule:**
  - It knocks along the pipe network toward the loudest player, one joint per knock.
  - When it reaches the pipe beside you, that joint bursts with scalding steam, which knocks you down and costs health.
- **Sound cue:** metal knocking that you can place by direction, getting closer, then a pressure whine right before the burst.
- **Counterplay:** get away from pipe runs (go into rooms), or make noise somewhere else to turn it.
- **Levels:** Plant Room.
- **The Shift:** the pipes reroute with the walls, so it loses its place and starts its count again.
- **Danger:** 3.
- **Scare type:** tense.

### 11. Bedside
- **What it is:** something standing behind the ward curtains, and you can see its feet.
- **Behaviour rule:**
  - It waits behind one curtain rail at a time and moves between them unseen.
  - Walk through a curtain it's behind and you're dead.
- **Sound cue:** a curtain ring sliding on its rail when it changes bays, and bare feet shifting.
- **Counterplay:**
  - Look under the curtain first (crouch or torch) and check for feet.
  - Take the long way round.
- **Levels:** Ward.
- **The Shift:** after a blackout every curtain is drawn, which tells you it has moved.
- **Danger:** 4.
- **Scare type:** terrifying, a slow burn.

## When each appears (proposal)

| Sublevel | New this deep |
|---|---|
| 1 | Tenant (after the first Shift), Clerk, Lodger |
| 2 | Lampjaw, Fitter, Breather |
| 3 | Quiet, Patient (Ward), Knocker (Plant Room) |
| 4+ | Echo, Mason, Bedside (Ward), and the Foreman on every sublevel from 4 |

There should never be more than two lethal entities at once. Depth adds variety before it adds more killers.

## The three to build next

1. **The Quiet.**
   - **Why first:** it's the best scare for the least build. It needs no model, because it's the hum, the light system and NoiseService, all of which already exist.
   - **Why it works:** it pays off a note that's already on the safehouse wall, and it teaches a rule in one encounter. It also makes silence frightening in a game built around noise.
2. **The Foreman.**
   - **Why:** it fixes the pacing of the last minute. The timer becomes a physical thing coming out of the lift, which pushes crews to extract instead of being greedy, and that is the core tension of an extraction game.
   - **What it needs:** one Blender model and a keyring sound.
3. **The Clerk.**
   - **Why:** the roster has no low-danger, annoying tier, and sublevels 1 and 2 need one. It changes how crews handle loot (hold it, don't stash it), creates a jackpot-room risk/reward, and gives the Tenant a reason to hear players who fight it.
   - **What it needs:** one Blender model and a stamp sound.

**Audio:** every new entity needs its own sound. Those are synthesised in `tools/make_sounds.py` like the rest. Uploading audio is paused until Jason says so (after the DRONE takedown), so these can be built and tested with the stand-in sounds first.
