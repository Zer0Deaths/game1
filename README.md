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

- Find artefacts in the maze and pick them up (**E**, or tap the prompt). You can carry 4. Heavy ones slow you down.
- Drop the one in your hand with **G** (or the Drop button on phones).
- Sprint with **Left Shift** (L3 on gamepad, Sprint button on phones). Stamina drains faster and comes back slower the more you carry. Carried loot shows on your back.
- The compass at the top points to the **exit lift**. The further away you are, the more it wanders.
- Walk into the lift to deposit everything you carry. The money goes to the shared quota at the top.
- Beat the quota before the timer ends and the next run asks for more. Miss it and the quota resets.
- Die and your loot drops where you fell.

Tuning numbers (timer, quota, carry limit, speeds) are in `src/shared/Config.luau`.

## Optional: make it sound right

Sound files live in `assets/`: `fluorescent-hum.ogg`, `footstep-carpet.ogg`, `footstep-hard.ogg`, `footstep-metal.ogg`. Roblox only plays uploaded sounds, so:

1. In Studio: **Window > Asset Manager > Bulk Import**, select all four files.
2. Right-click each one > **Copy Asset ID**.
3. Send the IDs to Claude, or set them yourself: select **Workspace**, add string attributes `HUM`, `STEP_CARPET`, `STEP_HARD`, `STEP_METAL`, paste each ID, and save the place.

Until then the hum is silent and footsteps use Roblox's default sound.

## What's in the code

- `src/shared/LevelGen.luau` builds a level layout as plain data: a grid maze with loops, open rooms and light states (on, flickering, dead). Same seed, same level.
- `src/server/LevelBuilder.luau` turns that layout into grey-box parts (walls merged into long runs to keep part count low).
- `src/server/main.server.luau` sets dark lighting, builds the level and moves players to the spawn.
- `src/server/Atmosphere.luau` sets the look: haze, colour grading, bloom, hallway reverb. Tweak the numbers in `LOOK`.
- `src/client/main.client.luau` makes flickering lights stutter in bursts on each player's device.
- `src/shared/Artefacts.luau` lists the 8 artefact types: value, weight, look.
- `src/server/ArtefactService.luau` spawns artefacts and handles pickup, drop, carry weight and death drops.
- `src/server/ExitLift.luau` builds the deposit lift. `src/server/RunManager.luau` runs the quota, timer and deposits.
- `src/client/Hud.client.luau` (quota, timer, carry, messages), `Compass.client.luau` (lift compass), `Controls.client.luau` (drop key).
- `src/client/Ambience.client.luau` loops the fluorescent hum once a sound ID is set (`src/shared/SoundIds.luau`).
- `tests/levelgen.test.luau` checks 300 seeds can always reach every cell. Optional, needs the [Luau CLI](https://github.com/luau-lang/luau/releases): `luau tests/levelgen.test.luau`.
