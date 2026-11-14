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

## What it will do

- Track poison and sharpening-stone status independently on both weapons.
- Let you set time and charge warnings.
- Map normal, Shift, Ctrl, and Alt clicks to your chosen coating and priority for each hand.
- Prefer the highest rank you have in your bags within each selected poison family.
- Calculate the ingredients for a chosen batch of trainer-taught poisons. For example, plan a batch of 20 and see the exact total, what you already carry, and what to buy from a poison vendor.
- Open a rogue macro library, copy a popular macro, and optionally add `/laugh` to generated Cheap Shot and Blind macros.
- Get Fadeleaf reminders around vendors and the Auction House, plus a low Flash Powder reminder.

The poison picker is restricted to poisons Rogues can currently learn from a poison trainer in WoW: Forever. Entries found only in unused client data stay out of the picker.

## Release 0.0.1

The first public development preview includes the two hand indicators, configurable time and charge thresholds, and Forever API research. Modifier-based item application, the verified poison catalog, ingredient calculator, supply reminders, and macro builder are still in development. This release has not yet been loaded in the live game client.

Every version gets a tagged release and downloadable ZIP from the start. Roguetastiq follows SemVer beginning at `0.0.1`; releases stay marked as pre-releases until the in-game smoke check is recorded. See [the changelog](CHANGELOG.md).

## Install

1. Open [Releases](https://github.com/fantastiqlabs/roguetastiq/releases) and download **`Roguetastiq_0.0.1.zip`** from the release Assets. Do not download GitHub's separate **Source code** archive.
2. Extract the ZIP into the Forever client’s `Interface/AddOns/` directory.
3. Confirm these two files sit directly in the `Roguetastiq` folder (with no extra folder level):

   ```text
   <Forever client folder>/Interface/AddOns/Roguetastiq/Roguetastiq.toc
   <Forever client folder>/Interface/AddOns/Roguetastiq/Roguetastiq.lua
   ```

4. Restart the Forever client and enable **Roguetastiq** on the character selection screen if needed.

Check the client interface number in game with `/dump select(4, GetBuildInfo())`. The current TOC targets `16001`; update that value if the live client has moved on.

## Configure the preview

Use `/rt time 300` to set the low-time threshold in seconds, `/rt charges 10` for the low-charge threshold, and `/rt poison on|off` or `/rt stone on|off` to enable each warning. Drag the indicators to move them.

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
