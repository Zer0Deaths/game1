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

## Optional: make it look and sound right

- **Better lights:** in Studio, select **Lighting** in Explorer and set **Technology** to **Future**, then save the place. Scripts can't change this setting. Phones fall back to a cheaper mode on their own.
- **Fluorescent hum:** upload `assets/fluorescent-hum.ogg` (Window > Asset Manager > Bulk Import), copy its asset ID, then select **Workspace**, add a string attribute `HumSoundId`, paste the ID and save the place.

## What's in the code

- `src/shared/LevelGen.luau` builds a level layout as plain data: a grid maze with loops, open rooms and light states (on, flickering, dead). Same seed, same level.
- `src/server/LevelBuilder.luau` turns that layout into grey-box parts (walls merged into long runs to keep part count low).
- `src/server/main.server.luau` sets dark lighting, builds the level and moves players to the spawn.
- `src/server/Atmosphere.luau` sets the look: haze, colour grading, bloom, hallway reverb. Tweak the numbers in `LOOK`.
- `src/client/main.client.luau` makes flickering lights stutter in bursts on each player's device.
- `src/client/CameraBob.client.luau` adds a gentle head bob while walking.
- `src/client/Ambience.client.luau` loops the fluorescent hum once a sound ID is set (`src/shared/SoundIds.luau`).
- `tests/levelgen.test.luau` checks 300 seeds can always reach every cell. Optional, needs the [Luau CLI](https://github.com/luau-lang/luau/releases): `luau tests/levelgen.test.luau`.
