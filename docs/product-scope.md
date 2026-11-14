# Product scope

## First release

1. Two small movable indicators, one each for Main Hand and Off Hand. Each shows poison and sharpening-stone time and charge state.
2. Per-coating time and charge thresholds. Hide each hand indicator while every enabled coating is above its warning thresholds; show it if a coating is absent or running low.
3. Settings for the preferred poison and sharpening stone, with a highest-available-rank option and fixed-rank overrides.
4. Modifier click mapping for normal, Shift, Ctrl, and Alt. Each mapping selects a coating type and configured priority for that weapon hand.
5. A poison recipe catalog and reagent calculator. Enter a target craft count (for example, 20); show total materials, bag counts, and remaining shopping quantities.
6. Vendor-aware shopping view that marks which missing reagents are sold by the currently open poison vendor.

## Interaction boundary

All item use and purchases must result from an explicit user hardware click. Opening a merchant, low coating time, or an addon timer must not use an item or spend gold. If Forever does not permit the requested click action through its secure UI, keep the feature informational and show exact manual steps.

## Follow-up

- Add automatic catalog refresh/build from verified game data and patch snapshots.
- Add localized item names and supported locale coverage.
- Verify interactions in the live Forever client, including combat lockdown and item-targeting behavior.
