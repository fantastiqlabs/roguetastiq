# Product scope

Product title: **Roguetastiq - The giga rogue toolkit!**

## First release

1. Two small movable indicators, one each for Main Hand and Off Hand. Each shows poison and sharpening-stone time and charge state.
2. Per-coating time and charge thresholds. Hide each hand indicator while every enabled coating is above its warning thresholds; show it if a coating is absent or running low.
3. Settings for the preferred poison and sharpening stone, with a highest-available-rank option and fixed-rank overrides. The poison selector must only show poisons currently taught by a rogue poison trainer in Forever.
4. Modifier click mapping for normal, Shift, Ctrl, and Alt. Each mapping selects a coating type and configured priority for that weapon hand.
5. A poison recipe catalog and reagent calculator. Choose a trainer-taught poison and target craft count (for example, 20); show total materials, bag counts, and remaining shopping quantities.
6. Vendor-aware shopping view that marks which missing reagents are sold by the currently open poison vendor.
7. An in-addon Rogue macro library/builder with copyable, Forever-checked macros such as focus Kick, mouseover Sap, stealth, and Pick Pocket/openers.
8. An optional **Add /laugh** setting for generated Cheap Shot and Blind macros. It changes only the copied macro text; Roguetastiq never runs emotes itself.
9. Fadeleaf reminders while browsing vendors or the Auction House, last-paid price hints when reliable transaction data is available, and a configurable low Flash Powder warning.

## Interaction boundary

All item use and purchases must result from an explicit user hardware click. Opening a merchant, low coating time, or an addon timer must not use an item or spend gold. If Forever does not permit the requested click action through its secure UI, keep the feature informational and show exact manual steps.

## Releases

Use SemVer, beginning at `0.0.1`. Publish a tagged ZIP for every version from the first development preview onward. Keep releases marked pre-release until the current live client smoke-test checklist is complete.

## Follow-up

- Add automatic catalog refresh/build from verified game data and patch snapshots.
- Add localized item names and supported locale coverage.
- Verify interactions in the live Forever client, including combat lockdown and item-targeting behavior.
