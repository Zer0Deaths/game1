# Things only Jason can do

Claude is building the game; these steps need your Roblox account, Studio, or money.
Tick them off as you go. Nothing here is urgent unless marked.

## Studio settings
- [ ] **Max players per server: 16.** Game Settings > Places > (your place) > Server Size... or Home > Game Settings > Places, set *Max Players* to 16. (Scripts can't change this.)
- [ ] **Avatar type R15.** Home > Game Settings > Avatar > Avatar Type: R15. The crew suit and arms are built for R15.
- [ ] **Allow Studio access to API services** (needed for saving progress): Home > Game Settings > Security > *Enable Studio Access to API Services* ON. Only matters once the place is published.

## Uploads (Creator Hub or Studio Asset Manager)
- [ ] Real recorded footstep sounds (CC0) to replace the generated ones. Upload, then paste the IDs into `src/shared/SoundIds.luau`.
- [ ] Optional: a modelled first-person arms rig and crew suit (Creator Store asset or a modeller). The current suit is basic shapes; first-person arms are hidden (`Config.SHOW_FIRST_PERSON_ARMS`).
- [ ] Optional: modelled entities. The Tenant is built from basic shapes.

## Money and publishing (Claude will never do these)
- [ ] Publish the place when you're happy with it.
- [ ] Create any game passes / developer products and paste their IDs into `Config` (see the monetisation section once it lands). Until then the shop only uses in-game money.
