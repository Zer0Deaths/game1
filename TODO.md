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

## Uploads: everything in one go (about 5 minutes of your time)
SHIFT now has 19 PBR texture sets, the crew suit's clothing and 25 sounds in `assets/`. Roblox only plays uploaded files, so until this is done the game uses built-in materials and stand-in sounds. One script uploads the lot and fills in the IDs for you.
- [ ] **Make an Open Cloud API key** (the only part only you can do):
  1. Go to https://create.roblox.com/dashboard/credentials and click **Create API Key**.
  2. Name it `SHIFT uploads`. Under **Access Permissions** pick **Assets API**, then tick **Read** and **Write**.
  3. Under **Security**, add the IP address `0.0.0.0/0` (or your own IP).
  4. Click **Save & Generate Key**, then **Copy Key**. Keep it private: don't paste it in the chat or commit it.
  5. Find your user ID: open your Roblox profile; it's the number in the address bar.
- [ ] **Run the upload** (the Claude session on your PC can do this for you, you just paste the key into its prompt when asked):
  1. Optional but better: `python tools/fetch_cc0.py` swaps in real CC0 footsteps and impacts from Kenney and scanned textures from ambientCG (your PC can reach those sites; the cloud can't).
  2. `python tools/upload_assets.py`, paste the key and your user ID when it asks.
  3. It writes `src/shared/AssetIds.luau`. Commit and push that file so it's saved.
- [ ] In Studio, after the next pull: Play. Output shows `[Surfaces] ...` and the sounds play.

## Money and publishing (Claude will never do these)
- [ ] Publish the place when you're happy with it.
- [ ] Monetisation is wired but **off**. To turn it on, create these on the Creator Hub (your call on prices), then paste each ID into `Config.MONETISATION` in `src/shared/Config.luau`:
  - Game pass **Suit Colours**: the safehouse wardrobe lets the owner cycle their suit colour.
  - Game pass **Supporter**: an amber patch on the owner's suit.
  - Developer product **Crew Supply Drop**: an energy drink and soft boots for the buyer's whole crew next run.
  All are cosmetic or help the whole crew; nothing lets a payer out-earn others. Leave an ID at 0 to keep that one off.
- [ ] Decide whether you also want a Cash bundle product. Claude left it out on purpose (it's pay-to-win in a co-op quota game).
