# WoW Forever API and coating research

Research snapshot: 2026-11-14. This is a working snapshot, not a promise that Blizzard will keep the same API or item data. Recheck the in-game client build and source after patches.

## Client compatibility

WoW Forever uses the modern WoW UI API surface. The existing Fantastiq Labs TBC addon is a different client and its `20506` interface number and legacy addon assumptions must not be copied here. Forever client references report interface `16001` for the 1.60.1 line; confirm locally with `/dump select(4, GetBuildInfo())` before setting `## Interface` in the TOC.

## Weapon coating status

Blizzard’s Forever UI source calls `C_Item.GetWeaponEnchantInfo(slot)` for each `Enum.WeaponSlot`. It loops through the returned enchant list and uses `hasEnchant`, `enchantType`, `timeLeft` (milliseconds), `charges`, `enchantID`, and `enchantIconID`. The main hand and off hand slots are represented by `Enum.WeaponSlot.MainHand` and `Enum.WeaponSlot.OffHand`.

The UI source distinguishes `Enum.ItemEnchantType.Imbue` from `Enum.ItemEnchantType.Temporary`. Roguetas­tiq can use those categories to track rogue poisons and sharpening stones independently, including when both are on one weapon. Verify poison and stone categorization against a live character before release.

Primary source: [Gethe/wow-ui-source, Forever BuffFrame.lua](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_BuffFrame/BuffFrame.lua). The `UpdateTemporaryEnchantmentBuffs` method iterates all weapon slots, reads `C_Item.GetWeaponEnchantInfo`, renders expiration time and charges, and cancels a slot enchant with `C_Spell.CancelItemTempEnchantment`.

## Opposing-player alert sounds

Forever's `SOUNDKIT` constants include the alert previews used by Roguetastiq: `RAID_WARNING` (8959), `ALARM_CLOCK_WARNING_1` (18871), `PVP_ENTER_QUEUE` (8458), `TELL_MESSAGE` (3081), `MAP_PING` (3175), and `READY_CHECK` (8960). The selector also offers the character emotes Cheer, Laugh, and Roar through `DoEmote`; choosing one makes the character perform that emote when an alert fires. Raid warning remains the default. The player should preview sounds in their own client because loudness and sound settings vary.

Primary source: [Gethe/wow-ui-source, Forever SoundKitConstants.lua](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_SharedXML/Mainline/SoundKitConstants.lua). The sound names and IDs were read from the `forever` branch on 2026-11-14; recheck after client updates.

## Poison and stone catalog scope

The selector will include only poisons currently learnable from a Rogue poison trainer on WoW: Forever. Being present in client files is not enough: client data can retain recipes that are not offered by Forever trainers. Current trainer and recipe observations cover the Instant, Deadly, Wound, Crippling, and Mind-numbing families; ranks are gated by skill and character level. Atrophic, Occult, Numbing, and Sebacious entries marked as not seen at a Forever trainer are excluded until their in-game availability is confirmed.

Sharpening stone choices include Rough, Coarse, Heavy, Solid, Dense, and Elemental Sharpening Stones. Do not include weightstones as sharpening stones: they are distinct weapon coatings and need a separate decision if support is desired.

The family and trainer availability snapshot is from current Forever game-data observations; check it against in-game trainers before adding or removing a rank:

- [ForeverDB Rogue poison guide](https://foreverdb.net/class/Rogue/poisons)
- [WoW Forever poisons recipes](https://thewowdb.com/wow-forever/professions/poisons/)
- [WoW Forever blacksmithing recipes](https://www.wowhead.com/forever/guide/professions/blacksmithing)

## Poison recipe shopping calculator

The calculator uses a versioned catalog of trainer-taught recipes. Select a poison rank and target count, multiply the reagents per craft, subtract items already in the bags, and show the remaining shopping amounts. It is informational: opening a vendor never purchases anything. Vendor-specific sold-item annotations remain follow-up work.

Recipe quantities and material item IDs are based on the current Forever client extraction published in [WoW Forever Guides](https://wowforeverguides.com/professions/poisons) (build 1.60.1.70862) and cross-checked against [TheWoWDB Forever poison table](https://thewowdb.com/wow-forever/professions/poisons/) (build 1.60.1.70124). These are community mirrors of client data, not Blizzard documentation. Keep the client build recorded with catalog changes and verify recipes in game before treating the calculator as authoritative.

## Known verification gaps

- Exact live interface number and Forever patch/build.
- In-game handling of multiple simultaneous coatings per hand and secret/opaque values.
- Verify every catalog recipe, item ID, and reagent count against a live character and current client build.
- Secure click behavior for modifier-based item application and item targeting to a chosen weapon.
- Vendor API behavior, whether bulk purchases can be initiated by one deliberate click, and whether the client limits repeated protected calls.
- Live UI sizing, drag persistence, threshold behavior, and reload persistence.
