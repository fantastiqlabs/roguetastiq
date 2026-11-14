local ns = {}
assert(loadfile((...) .. "/RoguetastiqMacro.lua"))("Roguetastiq", ns)

assert(ns.FoodMacroUseLine("item", 1, " Roasted Quail ") == "/use [stealth] Roasted Quail")
assert(ns.FoodMacroUseLine("actionbar", 7, "Roasted Quail") == "/click [stealth] ActionButton7")
assert(ns.FoodMacroUseLine("actionbar", 99, "Roasted Quail") == "/use [stealth] Roasted Quail")
assert(ns.FoodMacroUseLine("item", 1, " ") == "/use [stealth] Food Name")

print("macro food checks passed")
