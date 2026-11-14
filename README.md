<p align="center">
  <img src="assets/fantastiq-mark.svg" alt="Fantastiq Labs" width="132" />
</p>

<h1 align="center">Roguetastiq</h1>

<p align="center"><strong>The giga rogue toolkit!</strong><br />Keep both blades ready with poison, sharpening-stone, and rogue-supply reminders for World of Warcraft: Forever.</p>

<p align="center">
  <a href="https://github.com/fantastiqlabs/roguetastiq/releases"><img alt="Latest release" src="https://img.shields.io/github/v/release/fantastiqlabs/roguetastiq?include_prereleases&label=release"></a>
  <img alt="License" src="https://img.shields.io/badge/license-pending-lightgrey">
  <img alt="World of Warcraft Forever" src="https://img.shields.io/badge/WoW-Forever-8b6bce">
</p>

---

Roguetastiq keeps the two essentials visible and the rest out of the way. Its Main Hand and Off Hand indicators show poison and stone time/charges, then appear when a configured warning threshold is reached.

## Features

- Track poison and sharpening-stone status independently on both weapons.
- Let you set time and charge warnings.
- Unlock the bar, move it to your preferred screen position, lock it, and choose its size.
- Map normal, Shift, Ctrl, and Alt clicks through dropdowns for each hand.
- Prefer the highest rank you have in your bags within each selected poison family.
- Calculate materials for a selected poison recipe and batch size, subtracting what you already carry.
- Preview Rogue macros for Stealth, Sap, weapon swaps, Ambush/Backstab, auto-attack, and cooldowns. Optionally add `/laugh` to Cheap Shot and Blind.
- Get an optional sound when an opposing-faction player appears on a visible enemy nameplate, scoped to the contexts you choose.
- Find in-game mail feedback instructions and a copyable repository link in the options screen.

The poison picker is restricted to poisons Rogues can currently learn from a poison trainer in WoW: Forever. Entries found only in unused client data stay out of the picker.

## Release 0.0.7

This development preview adds an explicit **Create this macro** action with account/character storage and overwrite confirmation. It also fixes racial selection feedback, narrows the multiline preview to fit the options panel, and saves the coating bar's dragged position for reloads. The 0.0.6 release added the multiline preview and explanations for its controls.

**The click-to-apply actions have not yet been verified in the live Forever client.** Please test them in game and report the client build and any Lua error before relying on them.

Every version gets a tagged release and downloadable ZIP from the start. Roguetastiq follows SemVer beginning at `0.0.1`; releases stay marked as pre-releases until the in-game smoke check is recorded. See [the changelog](CHANGELOG.md).

## Install

1. Open [Releases](https://github.com/fantastiqlabs/roguetastiq/releases) and download **`Roguetastiq_0.0.7.zip`** from the release Assets. Do not download GitHub's separate **Source code** archive.
2. Extract the ZIP into the Forever client’s `Interface/AddOns/` directory.
3. Confirm these files sit directly in the `Roguetastiq` folder (with no extra folder level):

   ```text
   <Forever client folder>/Interface/AddOns/Roguetastiq/Roguetastiq.toc
   <Forever client folder>/Interface/AddOns/Roguetastiq/RoguetastiqCatalog.lua
   <Forever client folder>/Interface/AddOns/Roguetastiq/Roguetastiq.lua
   <Forever client folder>/Interface/AddOns/Roguetastiq/RoguetastiqOptions.lua
   ```

4. Restart the Forever client and enable **Roguetastiq** on the character selection screen if needed.

Check the client interface number in game with `/dump select(4, GetBuildInfo())`. The current TOC targets `16001`; update that value if the live client has moved on.

## Configure

Open **Interface → AddOns → Roguetastiq** or left-click the minimap button. Unlock the bar in settings, drag its purple grip, and lock it after placing. Right-click the minimap button to force the bar on or return it to automatic visibility.

## Build from source

```sh
python3 scripts/package.py
```

The script writes a versioned archive to `dist/`. The archive contains only the addon files, ready to copy into `Interface/AddOns/`.

## Research and feedback

- [Forever API and item research](docs/forever-api.md)
- [Rogue macro library research](docs/rogue-macros.md)
- [Product scope and interaction rules](docs/product-scope.md)
- [Open issues](https://github.com/fantastiqlabs/roguetastiq/issues)

Roguetastiq is a Fantastiq Labs project. Please report client errors with the game build, poison family/rank, hand, and the steps that triggered the issue.

Published GitHub releases post to the Fantastiq Labs Discord when the `FANTASTIQLABS_DISCORD_WEBHOOK` Actions secret is configured for this repository.
