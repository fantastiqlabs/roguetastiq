# Product scope

Product title: **Roguetastiq - The giga rogue toolkit!**

## Core addon

1. One compact Main Hand/Off Hand application bar with a clear center divider and poison/stone status icons.
2. Independently configure whether low or missing poison and stone trigger the bar. A disabled category must not show it. A manual toggle can expose it early.
3. Register all configuration under **Interface → AddOns → Roguetastiq**. Every requested feature must expose the relevant enable, scope, selection, threshold, or presentation control in this screen and use a sensible per-character default.
4. Let the player unlock the bar, drag a visible grip to any screen position, persist that position per character, and lock it again. Offer small, standard, and large size presets.
5. Configure every normal/Shift/Ctrl/Alt action for each hand with dropdown menus. Select trainer-taught poison families or sharpening stones; use the highest poison rank carried in bags.
6. Provide a poison shopping planner: select a recipe and target craft count, then show recipe materials, bag counts, and the remaining amounts to buy. At supported poison vendors, show an optional purchase popup with an explicit Buy button. An auto-buy setting may request the previewed quantities when a vendor opens, but it must be off by default and opt-in.
7. Provide selectable, editable Rogue macro previews for stealth, Sap, Pick Pocket, start attack, cooldown/racial combinations, weapon swaps, and dagger Ambush/Backstab. Support configurable food and racial placeholders and optional `/laugh` in Cheap Shot and Blind. The player copies text into WoW's macro UI.
8. Provide a toggleable opposing-faction alert, configurable for open world, battlegrounds/arenas, dungeons/raids, or everywhere. Let the player choose from common WoW sounds or Cheer, Laugh, and Roar emotes, preview the selection, and explain that emote choices perform the character emote. Detection is limited to visible enemy nameplates.
9. Show in-game mail feedback contact details and a copyable GitHub repository link in the options screen.
10. Configurable Fadeleaf reminders near vendors/Auction House and a configurable low Flash Powder warning. Show a last-paid Fadeleaf price only if the current client provides reliable transaction history; never substitute the vendor's asking price or a guessed amount.

## Interaction boundary

Poison coating use must result from an explicit user hardware click. Purchases may be requested by the vendor popup Buy button or by the separately configurable auto-buy option, which is off by default; no low-coating timer may spend gold. If Forever blocks addon-originated merchant purchases, report that clearly and leave Blizzard merchant controls available as the fallback.

## Releases

Use SemVer, beginning at `0.0.1`. Publish a tagged ZIP for every version from the first development preview onward. Announce published GitHub releases to the Fantastiq Labs Discord project-updates channel when the required Actions webhook secret is configured. Keep releases marked pre-release until the current live client smoke-test checklist is complete.

## Follow-up

- Verify interactions in the live Forever client, including combat lockdown, item targeting, saved bar placement, opponent alerts, macro ordering, and shopping counts.
- Add automatic catalog refresh/build from verified game data and patch snapshots.
- Add localized item names and supported locale coverage.
- Verify supply reminders and item IDs in the current Forever client. Revisit last-paid Fadeleaf display only if a reliable transaction-history source becomes available.
