# WoW Forever API and coating research

Research snapshot: 2026-11-14. This is a working snapshot, not a promise that Blizzard will keep the same API or item data. Recheck the in-game client build and source after patches.

## Client compatibility

WoW Forever uses the modern WoW UI API surface. The existing Fantastiq Labs TBC addon is a different client and its `20506` interface number and legacy addon assumptions must not be copied here. Forever client references report interface `16001` for the 1.60.1 line; confirm locally with `/dump select(4, GetBuildInfo())` before setting `## Interface` in the TOC.

## Weapon coating status

Blizzard’s Forever UI source calls `C_Item.GetWeaponEnchantInfo(slot)` for each `Enum.WeaponSlot`. It loops through the returned enchant list and uses `hasEnchant`, `enchantType`, `timeLeft` (milliseconds), `charges`, `enchantID`, and `enchantIconID`. The main hand and off hand slots are represented by `Enum.WeaponSlot.MainHand` and `Enum.WeaponSlot.OffHand`.

The UI source distinguishes `Enum.ItemEnchantType.Imbue` from `Enum.ItemEnchantType.Temporary`. Roguetas­tiq can use those categories to track rogue poisons and sharpening stones independently, including when both are on one weapon. Verify poison and stone categorization against a live character before release.

Primary source: [Gethe/wow-ui-source, Forever BuffFrame.lua](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_BuffFrame/BuffFrame.lua). The `UpdateTemporaryEnchantmentBuffs` method iterates all weapon slots, reads `C_Item.GetWeaponEnchantInfo`, renders expiration time and charges, and cancels a slot enchant with `C_Spell.CancelItemTempEnchantment`.

## Poison and stone catalog scope

Forever databases currently list the established poison families (Instant, Deadly, Wound, Crippling, and Mind-numbing) and Forever additions including Atrophic, Occult, Numbing, and Sebacious. Rank availability varies by family and current character level/training. The catalog should be data-driven and include only items actually present in the Forever client; use in-client item data as the release authority.

Sharpening stone choices include Rough, Coarse, Heavy, Solid, Dense, and Elemental Sharpening Stones. Do not include weightstones as sharpening stones: they are distinct weapon coatings and need a separate decision if support is desired.

These catalog names come from current community databases and should be cross-checked against Blizzard’s client data before item IDs are shipped:

- [Forever consumables catalog](https://metaforge.app/wow-forever/database/consumables?sub=Poisons)
- [WoW Forever poisons recipes](https://thewowdb.com/wow-forever/professions/poisons/)
- [WoW Forever blacksmithing recipes](https://www.wowhead.com/forever/guide/professions/blacksmithing)

## Vendor material calculator

The requested initial behavior is a shopping calculator: choose how many poisons to craft, read each recipe’s reagent quantities, subtract reagents already in the bags, and show the exact amount still needed. A vendor-facing view may show which missing materials this vendor sells. Merely opening a vendor must never trigger a purchase. Any future purchase button must be an explicit player click, use the vendor’s current price/stock, and be verified against Forever’s protected-action behavior.

Recipe reagents are subject to change. The exact reagent mapping and per-rank craft yield need a versioned catalog checked against current client data before the calculator can be considered complete.

## Known verification gaps

- Exact live interface number and Forever patch/build.
- In-game handling of multiple simultaneous coatings per hand and secret/opaque values.
- Complete item IDs and reagent recipes for every current poison rank and sharpening stone.
- Secure click behavior for modifier-based item application and item targeting to a chosen weapon.
- Vendor API behavior, whether bulk purchases can be initiated by one deliberate click, and whether the client limits repeated protected calls.
- Live UI sizing, drag persistence, threshold behavior, and reload persistence.
