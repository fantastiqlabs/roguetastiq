# Roguetastiq macro library research

This is the starter set for the in-addon macro library. The addon displays macro text for the player to copy into WoW's macro editor. It does not create or execute combat macros automatically. Recheck spell availability and behavior on the current live Forever build before relying on each example.

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

### Stealth and choose an opener

```text
#showtooltip
/cast [nostealth] Stealth; [mod:shift] Garrote; [mod:ctrl] Ambush; Cheap Shot
```

### Sap nearest hostile target

```text
#showtooltip Sap
/stopattack
/targetenemy [noharm][dead]
/cast [harm,nodead] Sap
```

This is a repeated-press helper, not an automatic search: it may need another deliberate press to get within range, and the player must confirm the selected target is a valid Sap target.

### Pick Pocket, then Cheap Shot

```text
#showtooltip Cheap Shot
/cast [stealth] Pick Pocket
/cast Cheap Shot
```

### Start auto-attack with damage

```text
#showtooltip Sinister Strike
/cast Sinister Strike
/startattack
```

The same pattern can be adapted for other damage abilities. Check the result in game; combat behavior can depend on which commands are off the global cooldown in the current build.

### Stealth, then eat

```text
#showtooltip
/cast [nostealth] !Stealth
/use [stealth] FOOD_ITEM
```

In the addon's macro options, choose an exact item name or select one of the first 12 action buttons. For action-button mode, put the food you want to use directly on that button; the generated macro uses `/click [stealth] ActionButtonN`. The addon cannot inspect the bar at macro runtime, dynamically rank bag food, or move food between slots. The intended flow is one press to enter Stealth, then another press to eat. Verify whether food use exits Stealth and whether `/click` works in a macro on the current Forever build.

### Dagger Ambush / Backstab

```text
#showtooltip [mod:shift] Backstab; Ambush
/equipslot 16 Dagger Name
/cast [mod:shift] Backstab; Ambush
/startattack [nostealth]
```

Replace `Dagger Name` with an exact main-hand dagger name. Shift uses Backstab; a normal press uses Ambush.

### Swap dagger for Stealth opener and normal weapon afterward

```text
#showtooltip [stealth] Ambush; Sinister Strike
/equipslot [stealth] 16 Dagger Name; 16 Main-Hand Weapon Name
/cast [stealth] Ambush; Sinister Strike
/startattack [nostealth]
```

Replace both weapon placeholders. This swaps the main-hand weapon based on Stealth state; verify weapon swapping and timing in combat before depending on it.

### Combat burst with trinkets and racial

```text
#showtooltip Adrenaline Rush
/use 13
/use 14
/cast Blood Fury
/cast Adrenaline Rush
/cast Blade Flurry
```

Replace `Blood Fury` with the character's usable racial, or remove that line. The settings panel offers Blood Fury, Berserking, and Eureka! choices. Cooldown availability, global-cooldown ordering, and racial names need an in-game check.

### Stealth out of combat, Vanish in combat

```text
#showtooltip
/stopattack [combat]
/cast [nocombat] !Stealth; Vanish
```

### Evasion and Sprint

```text
#showtooltip Evasion
/cast Evasion
/cast Sprint
```

### Blade Flurry toggle

```text
#showtooltip Blade Flurry
/cancelaura Blade Flurry
/cast Blade Flurry
```

### Shank and Sinister Strike

```text
#showtooltip
/startattack
/cast Shank
/cast Sinister Strike
```

Shank is Forever-specific. Verify the ability name and one-press ordering at the character's level and build.

## Optional `/laugh`

When enabled in the macro builder, add `/laugh` to generated Cheap Shot and Blind text. The setting is off by default and does not affect other macros. The laugh is part of the macro text copied for the player; it only runs when the player presses that macro.

## Sources and limits

Current Forever Rogue macro examples include focus/mouseover targeting, Sap, Stealth openers, auto-attack starts, cooldown combinations, and weapon swaps. Research references: [Mobalytics Combat Rogue guide](https://mobalytics.gg/wow-forever/classes/combat-rogue-guide#26-macros-4), [60.tools Rogue macro library](https://www.60.tools/macros/rogue), [EndgameTools Forever Rogue macros](https://endgametools.com/en/wow-forever/news/wow-forever-rogue-macros), [WoW Forever Rogue macros](https://muchamielwow.github.io/en/macros/rogue/), and [Wowcalc's Forever focus Kick macro](https://wowcalc.net/en/forever/wiki/macros/rogue/focus-kick). These are community references; confirm spell names, item placeholders, and macro ordering in the live client.
