local addonName, ns = ...

local defaults = {
	timeThreshold = 300,
	chargeThreshold = 10,
	poisonEnabled = true,
	stoneEnabled = true,
}

local function copyDefaults(target, source)
	for key, value in pairs(source) do
		if target[key] == nil then
			target[key] = value
		end
	end
end

local function coatingState(slot)
	local results = { poison = nil, stone = nil }
	local enchants = C_Item.GetWeaponEnchantInfo(slot)
	for _, enchant in ipairs(enchants or {}) do
		if enchant.hasEnchant then
			local key
			if enchant.enchantType == Enum.ItemEnchantType.Imbue then
				key = "poison"
			elseif enchant.enchantType == Enum.ItemEnchantType.Temporary then
				key = "stone"
			end
			if key then
				results[key] = {
					seconds = (enchant.timeLeft or 0) / 1000,
					charges = enchant.charges or 0,
					icon = enchant.enchantIconID,
					id = enchant.enchantID,
				}
			end
		end
	end
	return results
end

local function needsRefresh(state, enabled)
	if not enabled then
		return false
	end
	return not state or state.seconds <= RoguetastiqDB.timeThreshold
		or (state.charges > 0 and state.charges <= RoguetastiqDB.chargeThreshold)
end

local function formatState(label, state)
	if not state then
		return label .. ": missing"
	end
	return string.format("%s: %ds · %d", label, math.ceil(state.seconds), state.charges)
end

local hands = {
	{ name = "Main Hand", slot = Enum.WeaponSlot.MainHand },
	{ name = "Off Hand", slot = Enum.WeaponSlot.OffHand },
}

local buttons = {}
local function render()
	for index, hand in ipairs(hands) do
		local state = coatingState(hand.slot)
		local alert = needsRefresh(state.poison, RoguetastiqDB.poisonEnabled)
			or needsRefresh(state.stone, RoguetastiqDB.stoneEnabled)
		local button = buttons[index]
		button.label:SetText(hand.name .. "\n" .. formatState("Poison", state.poison)
			.. "\n" .. formatState("Stone", state.stone))
		if alert then button:Show() else button:Hide() end
	end
end

local function createButton(index, title)
	local button = CreateFrame("Button", "RoguetastiqHand" .. index, UIParent, "BackdropTemplate")
	button:SetSize(178, 64)
	button:SetPoint("CENTER", UIParent, "CENTER", (index == 1 and -92 or 92), -130)
	button:SetMovable(true)
	button:EnableMouse(true)
	button:RegisterForDrag("LeftButton")
	button:SetScript("OnDragStart", button.StartMoving)
	button:SetScript("OnDragStop", button.StopMovingOrSizing)
	button:SetBackdrop({
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		tile = true,
		tileSize = 16,
		edgeSize = 12,
		insets = { left = 3, right = 3, top = 3, bottom = 3 },
	})
	button:SetBackdropColor(0.04, 0.05, 0.07, 0.92)
	button.label = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	button.label:SetPoint("CENTER")
	button.label:SetJustifyH("CENTER")
	button.label:SetText(title)
	buttons[index] = button
end

local function slash(message)
	local command, value = message:match("^(%S+)%s*(.-)$")
	if command == "time" and tonumber(value) then
		RoguetastiqDB.timeThreshold = math.max(0, tonumber(value))
	elseif command == "charges" and tonumber(value) then
		RoguetastiqDB.chargeThreshold = math.max(0, tonumber(value))
	elseif command == "poison" and (value == "on" or value == "off") then
		RoguetastiqDB.poisonEnabled = value == "on"
	elseif command == "stone" and (value == "on" or value == "off") then
		RoguetastiqDB.stoneEnabled = value == "on"
	else
		print("Roguetastiq: /rt time <seconds>, /rt charges <count>, /rt poison <on|off>, /rt stone <on|off>")
	end
	render()
end

SLASH_ROGUETASTIQ1 = "/roguetastiq"
SLASH_ROGUETASTIQ2 = "/rt"
SlashCmdList.ROGUETASTIQ = slash

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("UNIT_INVENTORY_CHANGED")
events:RegisterEvent("UNIT_AURA")
events:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
events:SetScript("OnEvent", function(_, event, unit)
	if event == "PLAYER_LOGIN" then
		RoguetastiqDB = RoguetastiqDB or {}
		copyDefaults(RoguetastiqDB, defaults)
		createButton(1, hands[1].name)
		createButton(2, hands[2].name)
	elseif unit == nil or unit == "player" then
		render()
	end
end)

C_Timer.NewTicker(1, function()
	if RoguetastiqDB and buttons[1] then render() end
end)
