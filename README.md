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
- Map normal, Shift, Ctrl, and Alt clicks to your chosen coating and priority for each hand.
- Prefer the highest rank you have in your bags within each selected poison family.
- Calculate the ingredients for a chosen batch of trainer-taught poisons. For example, plan a batch of 20 and see the exact total, what you already carry, and what to buy from a poison vendor.
- Open a rogue macro library, copy a popular macro, and optionally add `/laugh` to generated Cheap Shot and Blind macros.
- Get Fadeleaf reminders around vendors and the Auction House, plus a low Flash Powder reminder.

The poison picker is restricted to poisons Rogues can currently learn from a poison trainer in WoW: Forever. Entries found only in unused client data stay out of the picker.

## Release 0.0.2

This development preview adds a compact combined Main Hand/Off Hand bar, separate poison and stone icons, independent poison/stone visibility alerts, an Interface → AddOns settings page, a minimap button, and configurable normal/Shift/Ctrl/Alt coating actions for each hand. The coating timers show minutes above one minute and seconds below it. Poison actions choose the highest rank of the selected family in your bags.

**The click-to-apply actions have not yet been verified in the live Forever client.** Please test them in game and report the client build and any Lua error before relying on them.

Every version gets a tagged release and downloadable ZIP from the start. Roguetastiq follows SemVer beginning at `0.0.1`; releases stay marked as pre-releases until the in-game smoke check is recorded. See [the changelog](CHANGELOG.md).

## Install

1. Open [Releases](https://github.com/fantastiqlabs/roguetastiq/releases) and download **`Roguetastiq_0.0.2.zip`** from the release Assets. Do not download GitHub's separate **Source code** archive.
2. Extract the ZIP into the Forever client’s `Interface/AddOns/` directory.
3. Confirm these two files sit directly in the `Roguetastiq` folder (with no extra folder level):

   ```text
   <Forever client folder>/Interface/AddOns/Roguetastiq/Roguetastiq.toc
   <Forever client folder>/Interface/AddOns/Roguetastiq/RoguetastiqCatalog.lua
   <Forever client folder>/Interface/AddOns/Roguetastiq/Roguetastiq.lua
   <Forever client folder>/Interface/AddOns/Roguetastiq/RoguetastiqOptions.lua
   ```

4. Restart the Forever client and enable **Roguetastiq** on the character selection screen if needed.

Check the client interface number in game with `/dump select(4, GetBuildInfo())`. The current TOC targets `16001`; update that value if the live client has moved on.

## Configure

Open **Interface → AddOns → Roguetastiq** or left-click the minimap button to configure warnings and each hand's click actions. Right-click the minimap button to force the bar on or return it to automatic visibility. Use `/rt` to open settings.

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
