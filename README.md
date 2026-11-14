# Roguetastiq

Roguetastiq is a minimal World of Warcraft: Forever rogue addon for keeping weapon coatings ready. Its two compact controls represent Main Hand and Off Hand and report poison and sharpening-stone time/charges. They appear when a configured low threshold is reached.

## Planned behavior

- Track Forever weapon imbues and temporary weapon enchants separately for both hands.
- Configure time and charge warning thresholds.
- Map normal, Shift, Ctrl, and Alt clicks to per-hand poison or stone choices; prefer the highest configured rank the character has in their bags.
- Calculate the exact reagent shopping list for a selected number of poison crafts, including current bag counts and vendor availability.
- Provide a vendor view that helps buy chosen quantities after the player explicitly starts the action.

The addon will not make decisions or purchases when the vendor merely opens. The shopping calculator is the initial vendor feature; in-game purchasing behavior must follow the client’s protected-action rules and will be verified before it is enabled.

## Status

Project bootstrap and client research are in progress. The Forever API has a modern `C_Item.GetWeaponEnchantInfo(slot)` API that returns all weapon enchantments, including enchant category, remaining milliseconds, charges, and icon/ID data. See [Forever API notes](docs/forever-api.md).

## Install

Copy the `Roguetastiq` directory into the Forever client’s `Interface/AddOns/` directory. The current shell is only a project scaffold; verify the exact client interface number in game with `/dump select(4, GetBuildInfo())` before packaging.

## Source and documentation

Implementation source lives in this repository. Keep research and user guides in `docs/`; once the GitHub repository is created, register it as a Doctastiq source and follow the Doctastiq documentation publishing routine.
