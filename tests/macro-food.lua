local ns = {}
assert(loadfile((...) .. "/RoguetastiqMacro.lua"))("Roguetastiq", ns)

assert(ns.FoodMacroUseLine("item", 1, " Roasted Quail ") == "/use [stealth] Roasted Quail")
assert(ns.FoodMacroUseLine("actionbar", 7, "Roasted Quail") == "/click [stealth] ActionButton7")
assert(ns.FoodMacroUseLine("actionbar", 99, "Roasted Quail") == "/use [stealth] Roasted Quail")
assert(ns.FoodMacroUseLine("item", 1, " ") == "/use [stealth] Food Name")
assert(ns.WeaponSwapMacroLines("item", 1, " Dagger ", "item", 2, "Sword") ==
	"/equipslot [stealth] 16 Dagger\n/equipslot [nostealth] 16 Sword")
assert(ns.WeaponSwapMacroLines("actionbar", 3, "Dagger", "actionbar", 8, "Sword") ==
	"/click [stealth] ActionButton3\n/click [nostealth] ActionButton8")
assert(ns.DaggerMacroUseLine("item", 1, "Dagger") == "/equipslot 16 Dagger")
assert(ns.DaggerMacroUseLine("actionbar", 11, "Dagger") == "/click ActionButton11")
assert(ns.DaggerMacroUseLine("actionbar", 99, "Dagger") == "/equipslot 16 Dagger")

print("macro food checks passed")
