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
3. Press **Play**. The Output window should show:
   - `Hello from the server! Rojo sync is working.`
   - `Hello from <you>'s client! Rojo sync is working.`

Code changes pulled from GitHub show up in Studio automatically while `rojo serve` is running.
Save the place in Studio (File > Save to Roblox) to keep non-code stuff like maps and parts; Rojo only manages the folders above.
