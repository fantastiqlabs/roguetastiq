local _, ns = ...

local defaults = {
	timeThreshold = 300,
	chargeThreshold = 10,
	poisonWarnings = true,
	stoneWarnings = true,
	forceVisible = false,
	barLocked = true,
	barScale = 1,
	shoppingRecipeKey = "instant6",
	shoppingCount = 20,
	macroTemplate = "kick",
	laughInMacros = false,
	macroRacial = "none",
	macroFoodName = "Food Name",
	playerAlertEnabled = false,
	playerAlertContext = "world",
	hideBarInCities = false,
	minimapAngle = 220,
	barX = 0,
	barY = -140,
	bindings = {
		mainhand = {
			left = { kind = "poison", key = "instant" },
			shift = { kind = "poison", key = "deadly" },
			ctrl = { kind = "poison", key = "wound" },
			alt = { kind = "stone", key = "dense" },
		},
		offhand = {
			left = { kind = "poison", key = "instant" },
			shift = { kind = "poison", key = "deadly" },
			ctrl = { kind = "poison", key = "wound" },
			alt = { kind = "stone", key = "dense" },
		},
	},
}

local hands = {
	{ key = "mainhand", label = "Main Hand", slot = Enum.WeaponSlot.MainHand, inventorySlot = 16 },
	{ key = "offhand", label = "Off Hand", slot = Enum.WeaponSlot.OffHand, inventorySlot = 17 },
}

local modifierNames = { "left", "shift", "ctrl", "alt" }
local updatePending = false
local ticker
local hostilePlayersPresent = false
local lastHostileAlert = 0

local function contextMatchesAlert()
	local inInstance, instanceType = IsInInstance()
	local context = RoguetastiqDB.playerAlertContext
	if context == "all" then return true end
	if context == "world" then return not inInstance end
	if context == "battlegrounds" then return instanceType == "pvp" or instanceType == "arena" end
	if context == "instances" then return inInstance and instanceType ~= "pvp" and instanceType ~= "arena" end
	return false
end

function ns.CheckHostilePlayers()
	if not RoguetastiqDB or not RoguetastiqDB.playerAlertEnabled or not contextMatchesAlert() then
		hostilePlayersPresent = false
		return
	end
	local playerFaction = UnitFactionGroup("player")
	local detected = false
	for index = 1, 40 do
		local unit = "nameplate" .. index
		if UnitExists(unit) and UnitIsPlayer(unit) then
			local faction = UnitFactionGroup(unit)
			local opposite = faction and playerFaction and faction ~= playerFaction
			if opposite or (not faction and UnitIsEnemy("player", unit)) then
				detected = true
				break
			end
		end
	end
	if detected and not hostilePlayersPresent and (GetTime() - lastHostileAlert) >= 10 then
		if PlaySound then PlaySound((SOUNDKIT and SOUNDKIT.RAID_WARNING) or 8959, "Master") end
		lastHostileAlert = GetTime()
	end
	hostilePlayersPresent = detected
end

local function mergeDefaults(target, source)
	for key, value in pairs(source) do
		if type(value) == "table" then
			if type(target[key]) ~= "table" then target[key] = {} end
			mergeDefaults(target[key], value)
		elseif target[key] == nil then
			target[key] = value
		end
	end
end

local function coatingState(slot)
	local results = { poison = nil, stone = nil }
	for _, enchant in ipairs(C_Item.GetWeaponEnchantInfo(slot) or {}) do
		if enchant.hasEnchant then
			local kind
			if enchant.enchantType == Enum.ItemEnchantType.Imbue then
				kind = "poison"
			elseif enchant.enchantType == Enum.ItemEnchantType.Temporary then
				kind = "stone"
			end
			if kind then
				results[kind] = {
					seconds = (enchant.timeLeft or 0) / 1000,
					charges = enchant.charges or 0,
					icon = enchant.enchantIconID,
				}
			end
		end
	end
	return results
end

local function isLow(state)
	return not state or state.seconds <= RoguetastiqDB.timeThreshold
		or (state.charges > 0 and state.charges <= RoguetastiqDB.chargeThreshold)
end

local function timeText(state)
	if not state then return "Missing" end
	local seconds = math.max(0, math.ceil(state.seconds))
	local remaining = seconds < 60 and string.format("%ds", seconds)
		or string.format("%dm", math.floor(seconds / 60))
	return string.format("%s / %d", remaining, state.charges)
end

function ns.Render()
	if not RoguetastiqDB or not ns.HandButtons then return end
	local show = RoguetastiqDB.forceVisible
	for index, hand in ipairs(hands) do
		local button = ns.HandButtons[index]
		local state = coatingState(hand.slot)
		local poisonLow = RoguetastiqDB.poisonWarnings and isLow(state.poison)
		local stoneLow = RoguetastiqDB.stoneWarnings and isLow(state.stone)
		show = show or poisonLow or stoneLow
		button.title:SetText(index == 1 and "MH" or "OH")
		button.poisonStatus:SetText(timeText(state.poison))
		button.stoneStatus:SetText(timeText(state.stone))
		local poisonChoice = RoguetastiqDB.bindings[hand.key].left
		local poisonIcon = state.poison and state.poison.icon
			or ns.GetChoiceIcon(poisonChoice)
		local stoneChoice = RoguetastiqDB.bindings[hand.key].alt
		local stoneIcon = state.stone and state.stone.icon
			or ns.GetChoiceIcon(stoneChoice)
		button.poisonIcon:SetTexture(poisonIcon or 134400)
		button.stoneIcon:SetTexture(stoneIcon or 134400)
		button.poisonIcon:SetDesaturated(not state.poison)
		button.stoneIcon:SetDesaturated(not state.stone)
		button.poisonLabel:SetText("POISON")
		button.stoneLabel:SetText("STONE")
	end
	local hideInCity = RoguetastiqDB.hideBarInCities and IsResting and IsResting()
	if show and not hideInCity then ns.Bar:Show() else ns.Bar:Hide() end
end

local function actionMacro(hand, choice)
	local itemID = ns.FindCoatingItem(choice.kind, choice.key)
	if not itemID then return nil end
	return string.format("/use item:%d\n/use %d", itemID, hand.inventorySlot)
end

function ns.RefreshSecureActions()
	if not RoguetastiqDB or not ns.HandButtons then return end
	if InCombatLockdown() then
		updatePending = true
		return
	end
	for index, hand in ipairs(hands) do
		local button = ns.HandButtons[index]
		for _, modifier in ipairs(modifierNames) do
			local choice = RoguetastiqDB.bindings[hand.key][modifier]
			local prefix = modifier == "left" and "" or (modifier .. "-")
			local macro = choice and actionMacro(hand, choice)
			button:SetAttribute(prefix .. "type1", macro and "macro" or nil)
			button:SetAttribute(prefix .. "macrotext1", macro)
		end
	end
	updatePending = false
end

local function toggleBar()
	RoguetastiqDB.forceVisible = not RoguetastiqDB.forceVisible
	ns.Render()
end

SLASH_ROGUETASTIQ1 = "/roguetastiq"
SLASH_ROGUETASTIQ2 = "/rt"
SlashCmdList.ROGUETASTIQ = function(command)
	local subcommand, value = (command or ""):match("^(%S*)%s*(.-)$")
	if subcommand == "show" then
		RoguetastiqDB.forceVisible = true
		ns.Render()
	elseif subcommand == "hide" then
		RoguetastiqDB.forceVisible = false
		ns.Render()
	elseif subcommand == "time" and tonumber(value) then
		RoguetastiqDB.timeThreshold = math.max(0, tonumber(value))
		ns.Render()
	elseif subcommand == "charges" and tonumber(value) then
		RoguetastiqDB.chargeThreshold = math.max(0, tonumber(value))
		ns.Render()
	else
		ns.OpenSettings()
	end
end

local events = CreateFrame("Frame")
for _, event in ipairs({ "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "PLAYER_EQUIPMENT_CHANGED",
	"UNIT_AURA", "UNIT_INVENTORY_CHANGED", "BAG_UPDATE_DELAYED", "PLAYER_REGEN_ENABLED" }) do
	events:RegisterEvent(event)
end
events:SetScript("OnEvent", function(_, event, unit)
	if event == "PLAYER_LOGIN" then
		RoguetastiqDB = RoguetastiqDB or {}
		mergeDefaults(RoguetastiqDB, defaults)
		ns.InitializeInterface()
		ns.RefreshSecureActions()
		ns.Render()
		if not ticker then ticker = C_Timer.NewTicker(1, function()
			ns.Render()
			ns.CheckHostilePlayers()
			if ns.RefreshShoppingPlanner then ns.RefreshShoppingPlanner() end
		end) end
	elseif event == "PLAYER_REGEN_ENABLED" then
		if updatePending then ns.RefreshSecureActions() end
		ns.Render()
	elseif event == "UNIT_INVENTORY_CHANGED" then
		if unit == "player" then
			ns.RefreshSecureActions()
			ns.Render()
		end
	elseif event == "UNIT_AURA" then
		if unit == "player" then ns.Render() end
	else
		ns.RefreshSecureActions()
		ns.Render()
	end
end)
