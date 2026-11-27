# Things only Jason can do

Claude is building the game; these steps need your Roblox account, Studio, or money.
Tick them off as you go. Nothing here is urgent unless marked.

## Studio settings
- [ ] **Max players per server: 16.** Game Settings > Places > (your place) > Server Size... or Home > Game Settings > Places, set *Max Players* to 16. (Scripts can't change this.)
- [ ] **Avatar type R15.** Home > Game Settings > Avatar > Avatar Type: R15. The crew suit and arms are built for R15.
- [ ] **Allow Studio access to API services** (needed for saving progress): Home > Game Settings > Security > *Enable Studio Access to API Services* ON. Only matters once the place is published.

## Play-test checklist (Studio: Play for solo, or Test > Clients and Servers with 2-4)
- [ ] Safehouse: press Ready at the descent lift. "GOING DOWN 5" on the HUD, then you land on sublevel 1 (Output: `[Level] crew 1, sublevel 1 ...`).
- [ ] HUD shows your crew, sublevel and `$banked / $quota`. Deposit at the lift until the quota is met: the lift turns green and the HUD says TO THE LIFT.
- [ ] Stand in the lift: the panel offers Go deeper (E) and Return to safehouse (R). Deeper builds sublevel 2 (Lampjaw shows up from here); Return takes you to the safehouse with your Cash.
- [ ] Let the timer run out (or set `SUBLEVEL_SECONDS` to 60 in Config to test): the crew is wiped, back in the safehouse, shop kit gone.
- [ ] Two players in different crews: each crew gets its own level and never sees the other's.
- [ ] The Tenant shows up after the first Shift (tick `ForceShift`), follows your noise, and the lift is safe.
- [ ] Map (M) fills in and fades after a Shift.

## Uploads (Creator Hub or Studio Asset Manager)
- [ ] **Surface textures (biggest visual upgrade, ~10 minutes).** SHIFT has its own wallpaper, carpet, ceiling tile and concrete textures in `assets/textures/` (12 images, made for SHIFT, free to use). Roblox can only show uploaded images:
  1. In Studio: **Window > Asset Manager**, then **Bulk Import**, and pick all 12 files in `Documents\game1\assets\textures`.
  2. Right-click each one > **Copy Asset ID**, and paste them to Claude (say which file each ID is), or fill them in yourself in `src/shared/Config.luau` under `TEXTURES` (colour, normal and roughness for each of wallpaper, carpet, ceiling, concrete).
  3. Play. The Output shows `[Materials] 4 of 4 SHIFT textures active`.
- [ ] Optional, later: proper 3D models make the biggest difference after textures: the Tenant, office furniture, shelving and light fittings are all built from code shapes. A modeller (or Creator Store models you have the rights to) would replace them.
- [ ] Real recorded footstep sounds (CC0) to replace the generated ones. Upload, then paste the IDs into `src/shared/SoundIds.luau`.
- [ ] Optional: a modelled first-person arms rig and crew suit (Creator Store asset or a modeller). The current suit is basic shapes; first-person arms are hidden (`Config.SHOW_FIRST_PERSON_ARMS`).
- [ ] Optional: modelled entities. The Tenant and Lampjaw are built from code shapes.

## Money and publishing (Claude will never do these)
- [ ] Publish the place when you're happy with it.
- [ ] Monetisation is wired but **off**. To turn it on, create these on the Creator Hub (your call on prices), then paste each ID into `Config.MONETISATION` in `src/shared/Config.luau`:
  - Game pass **Suit Colours**: the safehouse wardrobe lets the owner cycle their suit colour.
  - Game pass **Supporter**: an amber patch on the owner's suit.
  - Developer product **Crew Supply Drop**: an energy drink and soft boots for the buyer's whole crew next run.
  All are cosmetic or help the whole crew; nothing lets a payer out-earn others. Leave an ID at 0 to keep that one off.
- [ ] Decide whether you also want a Cash bundle product. Claude left it out on purpose (it's pay-to-win in a co-op quota game).
