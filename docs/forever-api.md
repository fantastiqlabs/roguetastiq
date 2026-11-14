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

## Poison recipe shopping and vendors

The calculator uses a versioned catalog of trainer-taught recipes. Select a poison rank and target count, multiply the reagents per craft, subtract items already in the bags, and show the remaining shopping amounts. At a supported vendor that sells a poison reagent, Roguetastiq can show the current recipe, vendor stock, missing quantities, and estimated copper cost. A deliberate button click requests only the available missing reagents; it does not craft poison. An optional setting requests the same purchase once when a supported vendor opens; it is off by default and guarded to one attempt per merchant session.

The Forever merchant UI reads listings through `C_MerchantFrame.GetItemInfo(index)` and `GetMerchantItemID(index)`, and Blizzard's merchant item button calls `BuyMerchantItem(index, quantity)` from its click paths. The Forever generated API documentation does not declare the legacy `BuyMerchantItem` global or specify addon-call and repeat-call policy. Roguetastiq therefore wraps each requested call, caps purchases against the current vendor listing, money, and bag space, declines high-value batch requests that would skip Blizzard's confirmation flow, and reports observed inventory changes rather than claiming success from a function return. Auto-buy remains opt-in. Manual verification on the current Forever client is required to confirm that addon purchase calls are accepted and that partial-stock results match the displayed vendor state.

Vendor recognition uses the presence of a purchasable poison reagent (Dust of Decay, Essence of Pain, Deathweed, Essence of Agony, or Dust of Deterioration), so a general vendor that sells only vials does not trigger the popup. Merchant items with extended currency costs are shown as unavailable to this feature.

Recipe quantities and material item IDs are based on the current Forever client extraction published in [WoW Forever Guides](https://wowforeverguides.com/professions/poisons) (build 1.60.1.70862) and cross-checked against [TheWoWDB Forever poison table](https://thewowdb.com/wow-forever/professions/poisons/) (build 1.60.1.70124). These are community mirrors of client data, not Blizzard documentation. Keep the client build recorded with catalog changes and verify recipes in game before treating the calculator as authoritative.

## Known verification gaps

- Exact live interface number and Forever patch/build.
- In-game handling of multiple simultaneous coatings per hand and secret/opaque values.
- Verify every catalog recipe, item ID, and reagent count against a live character and current client build.
- Secure click behavior for modifier-based item application and item targeting to a chosen weapon.
- Whether the current Forever client permits addon-originated `BuyMerchantItem` calls from deliberate and auto-buy paths, and how it handles rapid multi-reagent requests. The client-side popup and planner have automated checks; verify on a live vendor before relying on purchases.
- Live UI sizing, drag persistence, threshold behavior, and reload persistence.
