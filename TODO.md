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
- [ ] **Blender models:** Output says `[Meshes] 32 models loaded` a few seconds after Play. Check that loot shows its model (and the white outline when you look at it), the tube fittings switch off in a Shift blackout, the lockers have crates on top, and desks, chairs, pillars, door frames, vents and pipes look right. Anything floating, sunk or turned the wrong way: tell Claude which piece. If a line says `came in turned`, mention that too.
- [ ] **The new Tenant** (after the PC uploads `tenant`): when it arrives, Output says `[EntityRig] Tenant: the Blender model`. Head hung low in front of its chest, shoulders hunched over it, arms past its knees, elbows bending the wrong way, up on its toes. When it spots you the head comes up and tips over. If it looks broken (limbs detached or spinning), say so: the old body comes back by deleting `tenant` from `AssetIds.models`.
- [ ] **The Quiet** (sublevel 3 and down, or anywhere with the `ForceQuiet` Workspace attribute: tick it while you're in a level). Output: `[Quiet] crew 1: the hum stops around <you>`. The hum sags and drains away over 2 seconds, the tubes around you dim, then dead silence and one slow breath just behind you. Stand still (looking around is fine) and after 4-6 seconds the hum comes back and the tubes stutter up. Walk, jump or drop loot in the silence and you're taken. The first time it also says "The hum has stopped. Don't move." Tell Claude if the warning feels too short or the breath sounds wrong.
- [ ] **The Foreman** (sublevel 4 and down, or anywhere with the `ForceForeman` Workspace attribute: tick it while you're in a level; it jumps the timer to 90 s). The lift dings, the banner says it's switching off the level, and after 5 seconds the far end starts going dark, breaker by breaker, closing in on the lift. Open the map (M): the dark cells are blacked out. Walk back and it never reaches you; stand still out in the level and when your cell goes dark you're taken. Output: `[Foreman] crew 1: switching off from N cells out`. Until the PC uploads `foreman` its body is built from blocks (hat over a black hole, keys on the belt); after the upload, Output says `[EntityRig] Foreman: the Blender model`.
- [ ] **Audio, when you're ready to un-pause it:** three new sounds, all our own synthesis: the Quiet's breath (`QUIET_INHALE`), and the Foreman's keys (`FOREMAN_KEYS`) and whistle (`FOREMAN_WHISTLE`) in `assets/sounds/`. Until they're uploaded, slowed whispers stand in for the breath, and the Foreman is heard by its boots and the breakers only. They go up with `python tools/upload_assets.py --audio`, so only when you say audio is OK again.

## Uploads (done 27 Nov: 99 assets uploaded, IDs in `src/shared/AssetIds.luau`)
- [ ] **After the realism pass:** the PC session runs `python tools/upload_assets.py` once more (it only uploads the 10 new grime decals in `assets/decals`) and commits `src/shared/AssetIds.luau` and `assets/uploaded.json`. Until then the stains use the old flat patches.
- [ ] **Install the textures once (about 1 minute).** This same line also turns on the best lighting your Studio allows (Future, or Realistic + Prioritize Lighting Quality in newer Studios), which a running game can't do. A running game isn't allowed to create textured materials, so this one step happens in Studio itself:
  1. Make sure the game is **stopped** (not playing).
  2. Open **View > Command Bar**, paste this and press Enter:
     `require(game.ReplicatedStorage.Shared.Surfaces).install()`
  3. **File > Save** (so the materials are kept in the place).
  4. Play. Output should say `[Surfaces] 19 of 19 PBR sets active`. The command bar also prints `[Surfaces] lighting: ...` with what it could set.
  Do it again only after new textures are uploaded.
- To re-upload after changing files: `python tools/upload_assets.py` (skips anything unchanged), then commit `src/shared/AssetIds.luau` and `assets/uploaded.json`.
- Audio is moderated: a new sound can show "not approved" for a while after upload. It starts working by itself once Roblox approves it.

## Entities (optional, when you want them to look modelled)
- [ ] Real Tenant and Lampjaw meshes (Cube or Tripo, under 20k triangles) and Animation Editor animations. Step by step: `docs/ENTITY_GUIDE.md`. The built-in rigs and procedural animations work until then.

## Money and publishing (Claude will never do these)
- [ ] Publish the place when you're happy with it.
- [ ] Monetisation is wired but **off**. To turn it on, create these on the Creator Hub (your call on prices), then paste each ID into `Config.MONETISATION` in `src/shared/Config.luau`:
  - Game pass **Suit Colours**: the safehouse wardrobe lets the owner cycle their suit colour.
  - Game pass **Supporter**: an amber patch on the owner's suit.
  - Developer product **Crew Supply Drop**: an energy drink and soft boots for the buyer's whole crew next run.
  All are cosmetic or help the whole crew; nothing lets a payer out-earn others. Leave an ID at 0 to keep that one off.
- [ ] Decide whether you also want a Cash bundle product. Claude left it out on purpose (it's pay-to-win in a co-op quota game).
