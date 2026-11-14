# Action-bar and weapon macro references

Research for [issue #10](https://github.com/fantastiqlabs/roguetastiq/issues/10), checked 2026-11-14.

## Findings

- **A numbered action button is a position, not an item identity.** Blizzard's Classic manual describes 12 primary action buttons, multiple pages, and page switching. Forever's UI source computes action-button slots from the active page and button ID, then activates the action associated with that slot. The selected button can therefore resolve to different content after page changes or bar edits. [Blizzard WoW Classic manual](https://us.media.blizzard.com/manuals/wow/wow-classic-manual-enUS.pdf), [Forever `SecureTemplates.lua`, action slot mapping](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_FrameXML/SecureTemplates.lua#L341-L359), [Forever `SecureTemplates.lua`, action button page mapping](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_FrameXML/SecureTemplates.lua#L667-L684).
- **Direct item names are the stable option in this addon.** The generated `/equipslot 16 <item name>` macro names the weapon and its equipment slot directly. Blizzard's Classic forum macro guide discusses equipment commands and identifies `/click` as a macro command whose availability can vary by client version. [Blizzard macro guide](https://us.forums.blizzard.com/en/wow/t/macros-essential-information/21139), [Blizzard Classic equipment macro discussion](https://us.forums.blizzard.com/en/wow/t/how-to-use-an-equip-macro-instead-of-outfitter-itemrack-etc/306941/1000).
- **`/click ActionButtonN` is therefore an optional convenience with a live-client verification requirement.** The Forever UI source establishes that numbered action buttons exist and follow the active page; it does not prove that the current Forever macro parser permits a macro to click them or that weapon actions can equip the intended item. The classic macro guide also documents clients where `/click` is blocked from macros. Roguetastiq keeps typed item names available and labels button mode as something to verify in Forever 1.60.1. [Forever `SecureTemplates.lua`](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_FrameXML/SecureTemplates.lua), [Blizzard macro guide](https://us.forums.blizzard.com/en/wow/t/macros-essential-information/21139).
- **An action button must contain the direct item/equip action.** A blank button has no action, and replacing its content changes what the generated macro attempts to click. The tool does not inspect the selected button's content, page, bindings, or character-specific layout.

## Implementation decision

The macro options retain exact item-name inputs and add primary-bar selectors for the dagger and main-hand weapon. This is opt-in: the default remains direct item names. The generated text makes the selected bar position visible, and the UI warns that bar paging/content changes affect it. Test item use, weapon equip behavior, paging, reload, and combat restrictions in the target Forever client before relying on these selectors.

## Verification still required

1. Put the intended dagger and normal weapon actions on selected primary-bar buttons.
2. Test `/click ActionButtonN` from a macro on Forever 1.60.1.
3. Change primary-bar pages and confirm the warning matches observed behavior.
4. Test the generated Stealth/normal weapon macro, dagger opener macro, reload, and combat behavior.
