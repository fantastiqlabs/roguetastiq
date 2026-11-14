# Roguetastiq agent guidance

## Feature settings

Expose every user-requested feature through **Interface → AddOns → Roguetastiq**. Add the relevant enable/disable control, scope, threshold, selection, or presentation choice with a sensible default, and persist the setting. A feature is ready for review only when its option is visible and its setting changes the feature's behavior.

## Player-facing behavior

- Keep combat actions behind deliberate hardware clicks and WoW's secure UI.
- Opening a vendor must not buy anything by default. The reagent-shopping auto-buy may run only when the player enables its explicit option; it must use the current recipe and quantity, match an identified poison reagent vendor, and buy only the currently previewed missing reagent quantities. Never buy or craft on a warning threshold.
- Keep all vendor purchases within the documented merchant API and its confirmation/stock/funds/bag-space limits. Never simulate clicks or bypass protected actions; report client-blocked or partial purchases accurately.
- Keep macro text as a preview the player copies into WoW; never execute or create a macro on the player's behalf.
- Document limits that depend on nameplates, client APIs, or unverified live-game behavior in the relevant product or API note.
