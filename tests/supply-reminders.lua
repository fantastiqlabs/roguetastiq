local inventory = { [3818] = 0, [5140] = 4 }
local messages = {}
UIErrorsFrame = { AddMessage = function(_, message) messages[#messages + 1] = message end }
RoguetastiqDB = { fadeleafReminder = true, fadeleafThreshold = 5, flashPowderWarning = true, flashPowderThreshold = 10 }
local ns = { CountItemInBags = function(itemID) return inventory[itemID] or 0 end }
assert(loadfile("RoguetastiqSupplies.lua"))("Roguetastiq", ns)

assert(ns.ShouldShowFadeleafReminder(0, 5, true))
assert(ns.ShouldShowFadeleafReminder(5, 5, true))
assert(not ns.ShouldShowFadeleafReminder(6, 5, true))
assert(not ns.ShouldShowFadeleafReminder(0, 5, false))
assert(ns.CheckFadeleafReminder("vendor"))
assert(messages[#messages]:find("vendor", 1, true))
inventory[3818] = 6
assert(not ns.CheckFadeleafReminder("auction"), "no Fadeleaf alert above its configured threshold")

assert(ns.CheckFlashPowderReminder(), "low Flash Powder warns once")
assert(messages[#messages]:find("Flash Powder", 1, true))
assert(not ns.CheckFlashPowderReminder(), "the same low stock does not repeat the warning")
inventory[5140] = 11
assert(not ns.CheckFlashPowderReminder(), "stock above the threshold resets the warning state")
inventory[5140] = 10
assert(ns.CheckFlashPowderReminder(), "dropping to the threshold can warn again")
RoguetastiqDB.flashPowderWarning = false
assert(not ns.CheckFlashPowderReminder(), "the option disables the warning")

print("supply reminder checks passed")
