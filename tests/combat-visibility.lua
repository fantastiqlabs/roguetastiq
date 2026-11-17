local ns = { GetChoiceIcon = function() return 1 end }
local inCombat = false

Enum = {
	WeaponSlot = { MainHand = 16, OffHand = 17 },
	ItemEnchantType = { Imbue = 1, Temporary = 2 },
}
C_Item = { GetWeaponEnchantInfo = function() return {} end }
InCombatLockdown = function() return inCombat end
IsResting = function() return false end
SlashCmdList = {}
CreateFrame = function()
	return { RegisterEvent = function() end, SetScript = function() end }
end

assert(loadfile("Roguetastiq.lua"))("Roguetastiq", ns)
local function textRegion()
	return { SetText = function() end, SetTexture = function() end, SetDesaturated = function() end }
end
local function handButton()
	return {
		title = textRegion(), poisonStatus = textRegion(), stoneStatus = textRegion(),
		poisonIcon = textRegion(), stoneIcon = textRegion(), poisonLabel = textRegion(), stoneLabel = textRegion(),
	}
end
ns.HandButtons = { handButton(), handButton() }
local showCalls, hideCalls = 0, 0
ns.Bar = {
	Show = function()
		assert(not inCombat, "bar Show is protected during combat")
		showCalls = showCalls + 1
	end,
	Hide = function()
		assert(not inCombat, "bar Hide is protected during combat")
		hideCalls = hideCalls + 1
	end,
}
RoguetastiqDB = {
	forceVisible = false,
	poisonWarnings = false,
	stoneWarnings = false,
	hideBarInCities = false,
	timeThreshold = 300,
	chargeThreshold = 10,
	bindings = {
		mainhand = { left = {}, alt = {} },
		offhand = { left = {}, alt = {} },
	},
}

ns.Render()
assert(hideCalls == 1, "bar hides when warnings are inactive outside combat")
inCombat = true
ns.Render()
assert(hideCalls == 1 and showCalls == 0, "combat render defers all protected visibility calls")
RoguetastiqDB.forceVisible = true
ns.Render()
assert(hideCalls == 1 and showCalls == 0, "combat render defers a requested show too")
inCombat = false
ns.Render()
assert(showCalls == 1, "bar visibility refresh applies the deferred show after combat")
print("combat visibility checks passed")
