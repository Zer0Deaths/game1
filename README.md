# game1

Roblox game. Code lives in `src/` and is synced into Roblox Studio with [Rojo](https://rojo.space).

| Folder        | Ends up in Studio at                          | Runs on          |
|---------------|-----------------------------------------------|------------------|
| `src/server`  | `ServerScriptService.Server`                  | Server           |
| `src/client`  | `StarterPlayer.StarterPlayerScripts.Client`   | Each player      |
| `src/shared`  | `ReplicatedStorage.Shared`                    | Both (modules)   |

File naming: `name.server.luau` = Script, `name.client.luau` = LocalScript, `name.luau` = ModuleScript.

## First-time setup (Windows)

1. Install Git: https://git-scm.com/download/win (defaults are fine).
2. Install Rokit (tool manager): open PowerShell and run
   ```powershell
   Invoke-RestMethod https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.ps1 | Invoke-Expression
   ```
   Close and reopen PowerShell afterwards.
3. Get the code:
   ```powershell
   cd $HOME\Documents
   git clone https://github.com/Zer0Deaths/game1.git
   cd game1
   rokit install
   ```
   Say yes if Rokit asks to trust `rojo-rbx/rojo`.

## Every session

1. In PowerShell, inside the `game1` folder: `git pull`, then `rojo serve`. Leave that window open.
2. In Roblox Studio, open a place (a blank Baseplate is fine), open the **Rojo** plugin, click **Connect**.
3. Press **Play**. You spawn inside a freshly generated level. The Output window shows a line like
   `[Level] seed 123456: 420 parts in 35 ms`.
4. Want a different or repeatable layout? While playing, switch to the **Server** view (Test tab > Current: Client/Server), select **Workspace**, and in Properties change the `LevelSeed` attribute to any number. The level rebuilds and everyone is moved back to the start.

Code changes pulled from GitHub show up in Studio automatically while `rojo serve` is running.
Save the place in Studio (File > Save to Roblox) to keep non-code stuff like maps and parts; Rojo only manages the folders above.

## How to play (current build)

**The loop.** You spawn in the **safehouse**. Pick a crew at the crew board (4 crews of up to 4), buy supplies at the counter, then press **Ready** at the descent lift. When everyone is ready (or after 60 s) every crew drops into the same fresh level.

**In the level**
- Find artefacts and pick them up (**E**). You can carry 4 (more with the bigger pack). Heavy ones slow you down.
- Drop the one in your hand with **G**. Dropping loot is loud.
- Sprint with **Left Shift**. Sprinting is loud too.
- The compass points to the **exit lift**. **M** opens the crew map: everything anyone has seen, faded where a Shift may have changed it.
- Walk into the lift to deposit. The money goes to *your crew's* quota. When the timer ends, crews that met quota split the bank as personal **Cash** and face a bigger quota; crews that missed are wiped.
- Die and your loot drops where you fell. You wait out the run in the safehouse.
- **F** toggles your flashlight once you own one.

**The Shift:** every 80-120 s the hum rises and the lights stutter, then 3 s of black while the maze rewires around you and the lift may move. Testing: tick a Boolean Workspace attribute `ForceShift`.

**Entities**
- **The Tenant** (tall, faceless, long coat) hunts by sound. It turns up after the first Shift, near whoever has been loudest. It only hears what is near it: walking a few studs, sprinting a couple of cells, dropped loot further. When it sees you it stops and shrieks, then chases, faster than you walk but a little slower than you sprint. Out of sight it only knows where it last saw you, so break line of sight and go quiet. You hear its drone and heavy steps first. The exit lift is safe.
- **Lampjaw** hides in flickering lights. When one strobes **red and buzzes**, don't stop under it: linger about a second and it takes you. More active when a Shift is coming.

**Levels:** The Carpet (run 1), The Ward (from run 2), The Plant Room (from run 3). Each is about 30x30 cells (600 studs across), with long walled halls, a pillared atrium, offices, storage rooms and open rooms between the maze corridors. The Shift rewires everything out of sight but keeps the level stocked with these set pieces.

**Studio testing:** set the Workspace attribute `LevelSeed` to a number while in the safehouse to descend straight into that layout.

Tuning numbers live in `src/shared/Config.luau`. Things only you can do (Studio settings, uploads, publishing, products) are in **TODO.md**.

## Optional: make it sound right

Sound files live in `assets/`: `fluorescent-hum.ogg`, `footstep-carpet.ogg`, `footstep-hard.ogg`, `footstep-metal.ogg`. Roblox only plays uploaded sounds, so:

1. In Studio: **Window > Asset Manager > Bulk Import**, select all four files.
2. Right-click each one > **Copy Asset ID**.
3. Send the IDs to Claude, or set them yourself: select **Workspace**, add string attributes `HUM`, `STEP_CARPET`, `STEP_HARD`, `STEP_METAL`, paste each ID, and save the place.

Until then the hum is silent and footsteps use Roblox's default sound.

## What's in the code

Shared (`src/shared`, pure logic, mostly tested offline):
- `LevelGen` maze generator, the Shift rewiring, and path finding. `LevelTypes` the three level kinds.
- `Config` every tuning number. `Artefacts`, `ShopItems` item lists. `Crews` crew rules. `MapKnowledge` the crew map. `PlayerData` what gets saved.

Server (`src/server`):
- `main.server` the game loop: safehouse, descent, run, results.
- `LevelBuilder`, `Atmosphere`, `ExitLift`, `Safehouse` build the world. `Materials` the SHIFT textures (`assets/textures`, regenerate with `python tools/make_textures.py`).
- `RunManager` quotas and timer per crew. `CrewService` crews and Cash. `ArtefactService` loot.
- `ShiftService` the Shift. `Tenant`, `Lampjaw` the entities. `NoiseService` what they can hear.
- `MapService` crew map. `ShopService` shop and flashlight. `DataService` saving. `MonetisationService` paid extras (off until IDs are set). `Uniform` the crew suit.

Client (`src/client`): `main.client` lights, `Hud`, `Compass`, `Map`, `Shop`, `Movement` (sprint), `Footsteps`, `Ambience`, `TenantSounds`, `Controls`, `StartupLight`, `Dust`, `Arms` (off for now).

Offline tests (need the [Luau CLI](https://github.com/luau-lang/luau/releases)): `luau tests/levelgen.test.luau`, `tests/map.test.luau`, `tests/crews.test.luau`, `tests/playerdata.test.luau`.
