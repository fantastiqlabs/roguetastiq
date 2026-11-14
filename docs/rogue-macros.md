# Roguetastiq macro library research

This is the planned starter set for the in-addon macro library. The addon will display and copy text for the player to paste into WoW's macro editor. It will not create or execute combat macros automatically. Recheck spell availability and macro behavior on the current live Forever build before shipping.

## Starter macros

### Kick focus or target

```text
#showtooltip Kick
/cast [@focus,harm,nodead][] Kick
```

### Sap mouseover or target

```text
#showtooltip Sap
/stopattack
/cast [@mouseover,harm,nodead][] Sap
```

Sap needs a valid target and stealth. Poison and bleed effects can break its crowd control; the macro cannot change that game behavior.

### Stealth

```text
#showtooltip Stealth
/cast !Stealth
```

### Pick Pocket before Ambush

```text
#showtooltip Ambush
/cast [stealth] Pick Pocket
/cast Ambush
```

### Cheap Shot from stealth

```text
#showtooltip Cheap Shot
/cast Cheap Shot
```

### Blind

```text
#showtooltip Blind
/cast Blind
```

## Optional `/laugh`

When enabled in the macro builder, add `/laugh` to generated Cheap Shot and Blind text. The setting is off by default and does not affect other macros. The laugh is part of the macro text copied for the player; it only runs when the player presses that macro.

## Sources and limits

Current Forever Rogue macro examples commonly cover focus/mouseover Kick and Sap, stealth, Pick Pocket/openers, Cheap Shot, and Blind. Compare live spell names and copyable macro examples at [WoW Forever Rogue macros](https://muchamielwow.github.io/en/macros/rogue/) and [Wowcalc's Forever focus Kick macro](https://wowcalc.net/en/forever/wiki/macros/rogue/focus-kick). These are secondary references, so final spell names and macro condition behavior still require a live-client check.
