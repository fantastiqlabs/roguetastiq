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
	autoBuyMaterials = false,
	vendorPopupEnabled = true,
	fadeleafReminder = true,
	fadeleafThreshold = 5,
	flashPowderWarning = true,
	flashPowderThreshold = 10,
	mapMarkersEnabled = true,
	minimapMarkersEnabled = true,
	mapShowShadyDealer = true,
	mapShowPoisonVendor = true,
	mapShowRogueTrainer = true,
	macroTemplate = "kick",
	macroStorageScope = "character",
	laughInMacros = false,
	macroRacial = "none",
	macroFoodName = "Food Name",
	macroFoodSource = "item",
	macroFoodActionButton = 1,
	macroDaggerName = "Dagger Name",
	macroDaggerSource = "item",
	macroDaggerActionButton = 1,
	macroMainhandName = "Main-Hand Weapon Name",
	macroMainhandSource = "item",
	macroMainhandActionButton = 2,
	playerAlertEnabled = false,
	playerAlertContext = "world",
	playerAlertSound = "raid_warning",
	hideBarInCities = false,
	minimapAngle = 220,
	barPoint = "CENTER",
	barRelativePoint = "CENTER",
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
local alertSounds = {
	{ key = "raid_warning", label = "Raid warning", kind = "sound", soundKit = "RAID_WARNING", soundID = 8959 },
	{ key = "alarm", label = "Alarm clock", kind = "sound", soundKit = "ALARM_CLOCK_WARNING_1", soundID = 18871 },
	{ key = "pvp_queue", label = "PvP queue", kind = "sound", soundKit = "PVP_ENTER_QUEUE", soundID = 8458 },
	{ key = "whisper", label = "Whisper received", kind = "sound", soundKit = "TELL_MESSAGE", soundID = 3081 },
	{ key = "map_ping", label = "Map ping", kind = "sound", soundKit = "MAP_PING", soundID = 3175 },
	{ key = "ready_check", label = "Ready check", kind = "sound", soundKit = "READY_CHECK", soundID = 8960 },
	{ key = "emote_cheer", label = "Emote: Cheer", kind = "emote", emote = "CHEER" },
	{ key = "emote_laugh", label = "Emote: Laugh", kind = "emote", emote = "LAUGH" },
	{ key = "emote_roar", label = "Emote: Roar", kind = "emote", emote = "ROAR" },
}
ns.AlertSounds = alertSounds

function ns.PlayAlertSound()
	local selected
	for _, option in ipairs(alertSounds) do
		if option.key == RoguetastiqDB.playerAlertSound then selected = option; break end
	end
	selected = selected or alertSounds[1]
	if selected.kind == "emote" then
		if DoEmote then DoEmote(selected.emote) end
	elseif PlaySound then
		local soundID = SOUNDKIT and SOUNDKIT[selected.soundKit] or selected.soundID
		PlaySound(soundID, "Master")
	end
end

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
		ns.PlayAlertSound()
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
	if InCombatLockdown() then return end
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
	"UNIT_AURA", "UNIT_INVENTORY_CHANGED", "BAG_UPDATE_DELAYED", "PLAYER_REGEN_ENABLED",
	"MERCHANT_SHOW", "MERCHANT_UPDATE", "MERCHANT_CLOSED", "AUCTION_HOUSE_SHOW", "ZONE_CHANGED_NEW_AREA",
	"MINIMAP_UPDATE_ZOOM" }) do
	events:RegisterEvent(event)
end
events:SetScript("OnEvent", function(_, event, unit)
	if event == "PLAYER_LOGIN" then
		RoguetastiqDB = RoguetastiqDB or {}
		mergeDefaults(RoguetastiqDB, defaults)
		ns.InitializeInterface()
		ns.InitializeShopping()
		ns.InitializeMaps()
		ns.RefreshSecureActions()
		ns.Render()
		ns.CheckFlashPowderReminder()
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
	elseif event == "MERCHANT_SHOW" then
		ns.OnMerchantShow()
		ns.CheckFadeleafReminder("vendor")
		if RoguetastiqDB.autoBuyMaterials then ns.AutoBuyVendorMaterials() end
	elseif event == "MERCHANT_CLOSED" then
		ns.CloseVendorShopping()
	elseif event == "AUCTION_HOUSE_SHOW" then
		ns.CheckFadeleafReminder("auction")
	else
		if event == "BAG_UPDATE_DELAYED" then
			ns.RefreshVendorShopping()
			ns.CheckFlashPowderReminder()
		elseif event == "MERCHANT_UPDATE" then
			ns.RefreshVendorShopping()
		end
		if event == "ZONE_CHANGED_NEW_AREA" or event == "MINIMAP_UPDATE_ZOOM" then ns.RefreshMapMarkers() end
		ns.RefreshSecureActions()
		ns.Render()
	end
end)
