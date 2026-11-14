# Product scope

Product title: **Roguetastiq - The giga rogue toolkit!**

## First release

1. One compact application bar with Main Hand and Off Hand buttons joined side by side and separated by a clear center divider. Keep the full bar narrow.
2. Each hand button displays two coating icons (poison and stone), with a diagonal visual split and compact duration/charge labels. Use the selected item icon when no coating is applied.
3. Independently select whether low/missing poison, low/missing stone, or both trigger the bar. A disabled category must not pop the bar open. Let the minimap button expose it manually when the user wants to reapply early.
4. Add a minimap button. Left-click opens Roguetastiq settings; right-click toggles the application bar.
5. Register the same options panel under **Interface → AddOns** and let the minimap button open that page. The panel configures warning thresholds and every unmodified/Shift/Ctrl/Alt click on both hand buttons.
6. Each hand/modifier mapping selects poison family or stone type. Choose the highest rank carried in bags within the selected trainer-taught poison family.
7. A poison recipe catalog and reagent calculator. Choose a trainer-taught poison and target craft count (for example, 20); show total materials, bag counts, and remaining shopping quantities.
8. Vendor-aware shopping view that marks which missing reagents are sold by the currently open poison vendor.
9. An in-addon Rogue macro library/builder with copyable, Forever-checked macros such as focus Kick, mouseover Sap, stealth, and Pick Pocket/openers.
10. An optional **Add /laugh** setting for generated Cheap Shot and Blind macros. It changes only the copied macro text; Roguetastiq never runs emotes itself.
11. Fadeleaf reminders while browsing vendors or the Auction House, last-paid price hints when reliable transaction data is available, and a configurable low Flash Powder warning.

## Interaction boundary

All item use and purchases must result from an explicit user hardware click. Opening a merchant, low coating time, or an addon timer must not use an item or spend gold. If Forever does not permit the requested click action through its secure UI, keep the feature informational and show exact manual steps.

## Releases

Use SemVer, beginning at `0.0.1`. Publish a tagged ZIP for every version from the first development preview onward. Keep releases marked pre-release until the current live client smoke-test checklist is complete.

## Follow-up

- Add automatic catalog refresh/build from verified game data and patch snapshots.
- Add localized item names and supported locale coverage.
- Verify interactions in the live Forever client, including combat lockdown and item-targeting behavior.
