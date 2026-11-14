local _, ns = ...

local choiceRows = {}
local optionsPanel
local category
local minimapButton
local openDropdown
local shoppingSummary
local shoppingRows = {}
local shoppingRecipeDropdown
local shoppingCountLabel
local updateShopping
local macroPreview
local macroDropdown
local macroNameInput
local macroBodyCount
local macroNameManuallyEdited = false
local threatAlertToggle
local macroOptions = {
	{ key = "kick", label = "Kick - focus or target", text = "#showtooltip Kick\n/cast [@focus,harm,nodead][] Kick" },
	{ key = "sap", label = "Sap - mouseover or target", text = "#showtooltip Sap\n/stopattack\n/cast [@mouseover,harm,nodead][] Sap" },
	{ key = "sapnearest", label = "Sap - nearest enemy", text = "#showtooltip Sap\n/stopattack\n/targetenemy [noharm][dead]\n/cast [harm,nodead] Sap" },
	{ key = "stealth", label = "Stealth - spam safe", text = "#showtooltip Stealth\n/dismount [mounted]\n/cast [nostealth] Stealth" },
	{ key = "opener", label = "Stealth -> opener", text = "#showtooltip\n/cast [nostealth] Stealth; [mod:shift] Garrote; [mod:ctrl] Ambush; Cheap Shot" },
	{ key = "vanish", label = "Stealth / Vanish", text = "#showtooltip\n/stopattack [combat]\n/cast [nocombat] !Stealth; Vanish" },
	{ key = "stealthfood", label = "Stealth, then eat", text = "#showtooltip\n/cast [nostealth] !Stealth\nFOOD_USE_LINE" },
	{ key = "pickpocket", label = "Pick Pocket -> Ambush", text = "#showtooltip Ambush\n/cast [stealth] Pick Pocket\n/cast Ambush" },
	{ key = "pickpocketshot", label = "Pick Pocket -> Cheap Shot", text = "#showtooltip Cheap Shot\n/cast [stealth] Pick Pocket\n/cast Cheap Shot" },
	{ key = "cheapshot", label = "Cheap Shot from Stealth", text = "#showtooltip Cheap Shot\n/cast [nostealth] Stealth; Cheap Shot" },
	{ key = "blind", label = "Blind", text = "#showtooltip Blind\n/cast Blind" },
	{ key = "attack", label = "Sinister Strike + auto attack", text = "#showtooltip Sinister Strike\n/cast Sinister Strike\n/startattack" },
	{ key = "riposte", label = "Riposte, then Sinister Strike", text = "#showtooltip\n/cast Riposte\n/cast Sinister Strike\n/startattack" },
	{ key = "shank", label = "Shank + Sinister Strike", text = "#showtooltip\n/startattack\n/cast Shank\n/cast Sinister Strike" },
	{ key = "stealthambush", label = "Ambush from Stealth, Backstab after", text = "#showtooltip\n/cast [stealth] Ambush; Backstab\n/startattack [nostealth]" },
	{ key = "stealthweapon", label = "Dagger from Stealth, weapon after", text = "#showtooltip [stealth] Ambush; Sinister Strike\nWEAPON_SWAP_LINES\n/cast [stealth] Ambush; Sinister Strike\n/startattack [nostealth]" },
	{ key = "daggerambush", label = "Dagger Ambush / Backstab", text = "#showtooltip [mod:shift] Backstab; Ambush\nDAGGER_USE_LINE\n/cast [mod:shift] Backstab; Ambush\n/startattack [nostealth]" },
	{ key = "evasion", label = "Evasion + Sprint", text = "#showtooltip Evasion\n/cast Evasion\n/cast Sprint" },
	{ key = "flurry", label = "Blade Flurry toggle", text = "#showtooltip Blade Flurry\n/cancelaura Blade Flurry\n/cast Blade Flurry" },
	{ key = "burst", label = "Burst - trinkets + cooldowns", text = "#showtooltip Adrenaline Rush\n/use 13\n/use 14\n/cast %RACIAL%\n/cast Adrenaline Rush\n/cast Blade Flurry" },
}
local racialOptions = {
	{ key = "none", label = "No racial" },
	{ key = "Blood Fury", label = "Orc - Blood Fury" },
	{ key = "Berserking", label = "Troll - Berserking" },
	{ key = "Eureka!", label = "Gnome - Eureka!" },
}

local function setBackdrop(frame, alpha)
	frame:SetBackdrop({
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		tile = true,
		tileSize = 16,
		edgeSize = 10,
		insets = { left = 3, right = 3, top = 3, bottom = 3 },
	})
	frame:SetBackdropColor(0.035, 0.045, 0.065, alpha or 0.96)
end

local function font(parent, text, template, point, relative, relativePoint, x, y)
	local value = parent:CreateFontString(nil, "OVERLAY", template or "GameFontNormal")
	value:SetPoint(point, relative or parent, relativePoint or point, x or 0, y or 0)
	value:SetText(text or "")
	return value
end

local function refresh()
	for _, row in ipairs(choiceRows) do row:Refresh() end
	if updateShopping then updateShopping() end
	ns.RefreshSecureActions()
	ns.Render()
end

local function createButton(parent, text, width, height, point, relative, relativePoint, x, y)
	local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	button:SetSize(width, height)
	button:SetPoint(point, relative or parent, relativePoint or point, x or 0, y or 0)
	button:SetText(text)
	return button
end

local function makeDropdown(parent, width, height, point, relative, relativePoint, x, y, options, getSelected, onSelect)
	local button = createButton(parent, "", width, height, point, relative, relativePoint, x, y)
	local popup = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
	popup:SetFrameStrata("DIALOG")
	popup:SetFrameLevel(100)
	popup:SetClampedToScreen(true)
	popup:SetWidth(width)
	popup:SetHeight(math.max(26, #options * 24 + 4))
	setBackdrop(popup, 0.99)
	popup:Hide()
	for index, option in ipairs(options) do
		local entry = CreateFrame("Button", nil, popup, "BackdropTemplate")
		entry:SetSize(width - 8, 22)
		entry:SetPoint("TOPLEFT", popup, "TOPLEFT", 4, -2 - ((index - 1) * 24))
		local label = entry:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		label:SetPoint("LEFT", entry, "LEFT", 7, 0)
		label:SetPoint("RIGHT", entry, "RIGHT", -4, 0)
		label:SetJustifyH("LEFT")
		label:SetText(option.label)
		entry:SetScript("OnEnter", function(self) self:SetBackdropColor(0.28, 0.2, 0.38, 0.95) end)
		entry:SetScript("OnLeave", function(self) self:SetBackdropColor(0, 0, 0, 0) end)
		entry:SetScript("OnClick", function()
			onSelect(option)
			button:SetText(option.buttonLabel or option.label)
			popup:Hide()
			openDropdown = nil
		end)
		entry:SetBackdrop({ bgFile = "Interface/Buttons/WHITE8X8" })
		entry:SetBackdropColor(0, 0, 0, 0)
	end
	local function updateLabel()
		local selected = getSelected()
		button:SetText(selected and (selected.buttonLabel or selected.label) or "Select")
	end
	button:SetScript("OnClick", function()
		if openDropdown and openDropdown ~= popup then openDropdown:Hide() end
		if popup:IsShown() then
			popup:Hide()
			openDropdown = nil
			return
		end
		popup:ClearAllPoints()
		popup:SetPoint("BOTTOMLEFT", button, "TOPLEFT", 0, 3)
		popup:Show()
		openDropdown = popup
	end)
	button.Refresh = updateLabel
	updateLabel()
	return button
end

local function modifierLabel(modifier)
	if modifier == "left" then return "Left click" end
	return modifier:sub(1, 1):upper() .. modifier:sub(2) .. " + click"
end

local function makeChoiceRow(hand, modifier, x, y)
	font(optionsPanel, modifierLabel(modifier), "GameFontHighlightSmall", "TOPLEFT", optionsPanel, "TOPLEFT", x, y)
	local row = {}
	local choiceButton = makeDropdown(optionsPanel, 175, 25, "TOPLEFT", optionsPanel, "TOPLEFT", x + 86, y + 5,
		ns.Catalog.options,
		function() return ns.Catalog.optionsByKey[RoguetastiqDB.bindings[hand][modifier].kind .. ":" .. RoguetastiqDB.bindings[hand][modifier].key] end,
		function(option)
			RoguetastiqDB.bindings[hand][modifier] = { kind = option.kind, key = option.key }
			refresh()
		end)
	function row:Refresh()
		choiceButton:Refresh()
	end
	row:Refresh()
	choiceRows[#choiceRows + 1] = row
end

local function updateMacroPreview()
	if not macroPreview then return end
	local key = RoguetastiqDB.macroTemplate or "kick"
	local macro
	for _, option in ipairs(macroOptions) do if option.key == key then macro = option; break end end
	macro = macro or macroOptions[1]
	local content = macro.text
	content = content:gsub("FOOD_USE_LINE", function()
		return ns.FoodMacroUseLine(
			RoguetastiqDB.macroFoodSource, RoguetastiqDB.macroFoodActionButton, RoguetastiqDB.macroFoodName)
	end)
	content = content:gsub("WEAPON_SWAP_LINES", function()
		return ns.WeaponSwapMacroLines(
			RoguetastiqDB.macroDaggerSource, RoguetastiqDB.macroDaggerActionButton, RoguetastiqDB.macroDaggerName,
			RoguetastiqDB.macroMainhandSource, RoguetastiqDB.macroMainhandActionButton, RoguetastiqDB.macroMainhandName)
	end)
	content = content:gsub("DAGGER_USE_LINE", function()
		return ns.DaggerMacroUseLine(
			RoguetastiqDB.macroDaggerSource, RoguetastiqDB.macroDaggerActionButton, RoguetastiqDB.macroDaggerName)
	end)
	if key == "burst" then
		local racial = RoguetastiqDB.macroRacial or "none"
		content = content:gsub("/cast %%RACIAL%%\n", racial == "none" and "" or ("/cast " .. racial .. "\n"))
	end
	if RoguetastiqDB.laughInMacros and (key == "cheapshot" or key == "blind") then
		content = content:gsub("\n/cast", "\n/laugh\n/cast")
	end
		macroPreview:SetText(content)
	if macroBodyCount then macroBodyCount:SetText(string.format("%d / 255 characters", #content)) end
	if macroNameInput and not macroNameManuallyEdited then
		macroNameInput:SetText(("RT " .. key:gsub("[^%w]", "")):sub(1, 16))
	end
	if macroDropdown then macroDropdown:Refresh() end
end

local function createShoppingPlanner()
	local recipeOptions = {}
	for _, recipe in ipairs(ns.Catalog.recipes) do
		recipeOptions[#recipeOptions + 1] = { key = recipe.key, label = recipe.label, buttonLabel = recipe.label }
	end
	shoppingSummary = font(optionsPanel, "Choose a poison and quantity to calculate materials to buy.",
		"GameFontHighlightSmall", "TOPLEFT", optionsPanel, "TOPLEFT", 20, -418)
	for index = 1, 4 do
		shoppingRows[index] = font(optionsPanel, "", "GameFontHighlightSmall", "TOPLEFT", optionsPanel, "TOPLEFT", 20, -442 - (index - 1) * 20)
	end
	shoppingRecipeDropdown = makeDropdown(optionsPanel, 250, 27, "TOPLEFT", optionsPanel, "TOPLEFT", 20, -382,
		recipeOptions,
		function()
			local key = RoguetastiqDB.shoppingRecipeKey or "instant6"
			for _, option in ipairs(recipeOptions) do if option.key == key then return option end end
			return recipeOptions[1]
		end,
		function(option) RoguetastiqDB.shoppingRecipeKey = option.key; updateShopping() end)
	local countTitle = font(optionsPanel, "Number to make", "GameFontHighlightSmall", "TOPLEFT", optionsPanel, "TOPLEFT", 300, -365)
	shoppingCountLabel = font(optionsPanel, "", "GameFontNormal", "TOPLEFT", optionsPanel, "TOPLEFT", 300, -390)
	local function updateCount(delta)
		RoguetastiqDB.shoppingCount = math.max(1, math.min(200, (RoguetastiqDB.shoppingCount or 20) + delta))
		updateShopping()
	end
	local minusFive = createButton(optionsPanel, "-5", 32, 25, "TOPLEFT", optionsPanel, "TOPLEFT", 350, -382)
	local minusOne = createButton(optionsPanel, "-1", 32, 25, "TOPLEFT", optionsPanel, "TOPLEFT", 385, -382)
	local plusOne = createButton(optionsPanel, "+1", 32, 25, "TOPLEFT", optionsPanel, "TOPLEFT", 420, -382)
	local plusFive = createButton(optionsPanel, "+5", 32, 25, "TOPLEFT", optionsPanel, "TOPLEFT", 455, -382)
	local calculate = createButton(optionsPanel, "Calculate", 88, 25, "TOPLEFT", optionsPanel, "TOPLEFT", 490, -382)
	minusFive:SetScript("OnClick", function() updateCount(-5) end)
	minusOne:SetScript("OnClick", function() updateCount(-1) end)
	plusOne:SetScript("OnClick", function() updateCount(1) end)
	plusFive:SetScript("OnClick", function() updateCount(5) end)
	calculate:SetScript("OnClick", function() updateShopping() end)
	countTitle:Show()
	updateShopping = function()
		if not shoppingSummary then return end
		local recipe, materials = ns.BuildShoppingList(RoguetastiqDB.shoppingRecipeKey or "instant6", RoguetastiqDB.shoppingCount or 20)
		shoppingRecipeDropdown:Refresh()
		shoppingCountLabel:SetText(tostring(RoguetastiqDB.shoppingCount or 20))
		shoppingSummary:SetText(string.format("For %d x %s | reagents only:", RoguetastiqDB.shoppingCount or 20, recipe.label))
		for index, row in ipairs(shoppingRows) do
			local material = materials[index]
			if material then
				row:SetText(string.format("%s: need %d / have %d / buy %d", material.name, material.required, material.have, material.buy))
				row:Show()
			else
				row:Hide()
			end
		end
		if ns.RefreshVendorShopping then ns.RefreshVendorShopping() end
	end
	ns.RefreshShoppingPlanner = updateShopping
	updateShopping()
end

local function createMacroSection()
	font(optionsPanel, "ROGUE MACROS", "GameFontNormal", "TOPLEFT", optionsPanel, "TOPLEFT", 20, -10)
	font(optionsPanel, "Choose a template, review the text, then create it or copy it to WoW's Macro UI.",
		"GameFontHighlightSmall", "TOPLEFT", optionsPanel, "TOPLEFT", 20, -34)
	font(optionsPanel, "Macro template", "GameFontHighlightSmall", "TOPLEFT", optionsPanel, "TOPLEFT", 20, -54)
	font(optionsPanel, "Laugh option for Cheap Shot and Blind", "GameFontHighlightSmall",
		"TOPLEFT", optionsPanel, "TOPLEFT", 305, -54)
	local macroChoices = {}
	for _, option in ipairs(macroOptions) do
		macroChoices[#macroChoices + 1] = { key = option.key, label = option.label, buttonLabel = option.label }
	end
	macroDropdown = makeDropdown(optionsPanel, 270, 27, "TOPLEFT", optionsPanel, "TOPLEFT", 20, -72,
		macroChoices,
		function()
			for _, option in ipairs(macroChoices) do
				if option.key == (RoguetastiqDB.macroTemplate or "kick") then return option end
			end
			return macroChoices[1]
		end,
		function(option) RoguetastiqDB.macroTemplate = option.key; updateMacroPreview() end)
	local laughToggle = createButton(optionsPanel, "", 230, 27, "TOPLEFT", optionsPanel, "TOPLEFT", 305, -72)
	local function syncLaughToggle()
		laughToggle:SetText("Add /laugh: " .. (RoguetastiqDB.laughInMacros and "ON" or "OFF"))
	end
	laughToggle:SetScript("OnClick", function()
		RoguetastiqDB.laughInMacros = not RoguetastiqDB.laughInMacros
		syncLaughToggle()
		updateMacroPreview()
	end)
	syncLaughToggle()
	font(optionsPanel, "Used by the Burst template", "GameFontHighlightSmall",
		"TOPLEFT", optionsPanel, "TOPLEFT", 20, -106)
	font(optionsPanel, "Manual food item name", "GameFontHighlightSmall",
		"TOPLEFT", optionsPanel, "TOPLEFT", 300, -106)
	font(optionsPanel, "Or choose bar button", "GameFontHighlightSmall",
		"TOPLEFT", optionsPanel, "TOPLEFT", 550, -106)
	makeDropdown(optionsPanel, 250, 27, "TOPLEFT", optionsPanel, "TOPLEFT", 20, -124,
		racialOptions,
		function()
			for _, option in ipairs(racialOptions) do if option.key == (RoguetastiqDB.macroRacial or "none") then return option end end
			return racialOptions[1]
		end,
		function(option) RoguetastiqDB.macroRacial = option.key; updateMacroPreview() end)
	local foodName = CreateFrame("EditBox", nil, optionsPanel, "InputBoxTemplate")
	foodName:SetAutoFocus(false)
	foodName:SetSize(250, 25)
	foodName:SetPoint("TOPLEFT", optionsPanel, "TOPLEFT", 300, -124)
	foodName:SetText(RoguetastiqDB.macroFoodName or "Food Name")
	foodName:SetScript("OnEnterPressed", function(self)
		RoguetastiqDB.macroFoodName = self:GetText()
		self:ClearFocus()
		updateMacroPreview()
	end)
	local foodSources = { { key = "item", label = "Item name" } }
	for slot = 1, 12 do
		foodSources[#foodSources + 1] = { key = "actionbar", slot = slot, label = "Button " .. slot }
	end
	local foodSourceDropdown = makeDropdown(optionsPanel, 125, 25, "TOPLEFT", optionsPanel, "TOPLEFT", 540, -124,
		foodSources,
		function()
			if RoguetastiqDB.macroFoodSource == "actionbar" then
				for _, option in ipairs(foodSources) do
					if option.slot == (RoguetastiqDB.macroFoodActionButton or 1) then return option end
				end
			end
			return foodSources[1]
		end,
		function(option)
			RoguetastiqDB.macroFoodSource = option.key
			RoguetastiqDB.macroFoodActionButton = option.slot or RoguetastiqDB.macroFoodActionButton or 1
			foodName:SetEnabled(option.key == "item")
			updateMacroPreview()
		end)
	foodSourceDropdown:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine("Stealth and eat food source", 1, 1, 1)
		GameTooltip:AddLine("Choose an exact item name, or place your preferred food directly on the selected action button. The addon cannot dynamically choose food quality or move food between slots.", 1, 1, 1, true)
		GameTooltip:AddLine("Test /click behavior on the current Forever build before relying on it.", 1, 0.8, 0.3, true)
		GameTooltip:Show()
	end)
	foodSourceDropdown:SetScript("OnLeave", GameTooltip_Hide)
	foodName:SetEnabled(RoguetastiqDB.macroFoodSource ~= "actionbar")
	font(optionsPanel, "Weapon item name or action button (12 primary-bar buttons)", "GameFontHighlightSmall",
		"TOPLEFT", optionsPanel, "TOPLEFT", 20, -158)
	local weaponSources = { { key = "item", label = "Item name" } }
	for slot = 1, 12 do weaponSources[#weaponSources + 1] = { key = "actionbar", slot = slot, label = "Button " .. slot } end
	local function createWeaponSource(key, label, nameKey, slotKey, x)
		font(optionsPanel, label, "GameFontHighlightSmall", "TOPLEFT", optionsPanel, "TOPLEFT", x, -176)
		local name = CreateFrame("EditBox", nil, optionsPanel, "InputBoxTemplate")
		name:SetAutoFocus(false)
		name:SetSize(130, 25)
		name:SetPoint("TOPLEFT", optionsPanel, "TOPLEFT", x + 170, -174)
		name:SetText(RoguetastiqDB[nameKey] or "Weapon Name")
		name:SetScript("OnEnterPressed", function(self)
			RoguetastiqDB[nameKey] = self:GetText()
			self:ClearFocus()
			updateMacroPreview()
		end)
		local dropdown = makeDropdown(optionsPanel, 155, 25, "TOPLEFT", optionsPanel, "TOPLEFT", x, -194,
			weaponSources,
			function()
				if RoguetastiqDB[key] == "actionbar" then
					for _, option in ipairs(weaponSources) do
						if option.slot == (RoguetastiqDB[slotKey] or 1) then return option end
					end
				end
				return weaponSources[1]
			end,
			function(option)
				RoguetastiqDB[key] = option.key
				RoguetastiqDB[slotKey] = option.slot or RoguetastiqDB[slotKey] or 1
				name:SetEnabled(option.key == "item")
				updateMacroPreview()
			end)
		name:SetEnabled(RoguetastiqDB[key] ~= "actionbar")
		return dropdown
	end
	local daggerSource = createWeaponSource("macroDaggerSource", "Dagger", "macroDaggerName", "macroDaggerActionButton", 20)
	local mainhandSource = createWeaponSource("macroMainhandSource", "Normal main-hand", "macroMainhandName", "macroMainhandActionButton", 350)
	local function explainWeaponSource(dropdown)
		dropdown:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:AddLine("Weapon source", 1, 1, 1)
			GameTooltip:AddLine("Use an exact item name or place an item-use/equip action on the selected primary action button. An empty button does nothing; changing the button changes what the macro clicks.", 1, 1, 1, true)
			GameTooltip:AddLine("ActionButtonN follows the active primary bar page. Test paging and /click behavior in the current Forever client.", 1, 0.8, 0.3, true)
			GameTooltip:Show()
		end)
		dropdown:SetScript("OnLeave", GameTooltip_Hide)
	end
	explainWeaponSource(daggerSource)
	explainWeaponSource(mainhandSource)
	font(optionsPanel, "MULTILINE PREVIEW", "GameFontHighlightSmall", "TOPLEFT", optionsPanel, "TOPLEFT", 20, -224)
	local previewFrame = CreateFrame("Frame", nil, optionsPanel, "BackdropTemplate")
	previewFrame:SetSize(590, 165)
	previewFrame:SetPoint("TOPLEFT", optionsPanel, "TOPLEFT", 20, -244)
	setBackdrop(previewFrame, 0.99)
	macroPreview = CreateFrame("EditBox", nil, previewFrame)
	macroPreview:SetMultiLine(true)
	macroPreview:SetAutoFocus(false)
	macroPreview:SetSize(570, 145)
	macroPreview:SetPoint("TOPLEFT", previewFrame, "TOPLEFT", 10, -10)
	macroPreview:SetFontObject(GameFontHighlightSmall)
	macroPreview:SetTextInsets(4, 4, 4, 4)
	macroPreview:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	macroPreview:SetScript("OnEditFocusLost", function(self) self:HighlightText(0, 0) end)
	macroNameInput = CreateFrame("EditBox", nil, optionsPanel, "InputBoxTemplate")
	macroNameInput:SetAutoFocus(false)
	macroNameInput:SetSize(210, 25)
	macroNameInput:SetPoint("TOPLEFT", optionsPanel, "TOPLEFT", 90, -428)
	macroNameInput:SetMaxLetters(16)
	macroNameInput:SetScript("OnTextChanged", function(_, userInput)
		if userInput then macroNameManuallyEdited = true end
	end)
	font(optionsPanel, "Name", "GameFontHighlightSmall", "TOPLEFT", optionsPanel, "TOPLEFT", 20, -420)
	font(optionsPanel, "Save to", "GameFontHighlightSmall", "TOPLEFT", optionsPanel, "TOPLEFT", 320, -420)
	local scopeOptions = {
		{ key = "account", label = "Account" },
		{ key = "character", label = "Character" },
	}
	local scopeDropdown = makeDropdown(optionsPanel, 150, 25, "TOPLEFT", optionsPanel, "TOPLEFT", 370, -428,
		scopeOptions,
		function()
			for _, option in ipairs(scopeOptions) do
				if option.key == RoguetastiqDB.macroStorageScope then return option end
			end
			return scopeOptions[2]
		end,
		function(option)
			RoguetastiqDB.macroStorageScope = option.key
		end)
	local selectText = createButton(optionsPanel, "Select text", 110, 25, "TOPLEFT", optionsPanel, "TOPLEFT", 540, -428)
	selectText:SetScript("OnClick", function() macroPreview:SetFocus(); macroPreview:HighlightText() end)
	macroBodyCount = font(optionsPanel, "", "GameFontHighlightSmall", "LEFT", optionsPanel, "TOPLEFT", 20, -467)
	local macroStatus = font(optionsPanel, "", "GameFontHighlightSmall", "LEFT", optionsPanel, "TOPLEFT", 230, -467)
	local function updateMacroCounts()
		local accountCount, characterCount = GetNumMacros()
		local accountMaximum = (Constants and Constants.MacroConsts and Constants.MacroConsts.MAX_ACCOUNT_MACROS) or 120
		local characterMaximum = (Constants and Constants.MacroConsts and Constants.MacroConsts.MAX_CHARACTER_MACROS) or 30
		macroStatus:SetText(string.format("Account: %d/%d  Character: %d/%d", accountCount, accountMaximum,
			characterCount, characterMaximum))
	end
	local function macroIndexInScope(name, scope)
		local accountCount, characterCount = GetNumMacros()
		local accountMaximum = (Constants and Constants.MacroConsts and Constants.MacroConsts.MAX_ACCOUNT_MACROS) or 120
		local first = scope == "character" and (accountMaximum + 1) or 1
		local count = scope == "character" and characterCount or accountCount
		for index = first, first + count - 1 do
			local existingName = GetMacroInfo(index)
			if existingName == name then return index end
		end
	end
	local function createOrReplaceMacro(name, body, scope, existingIndex)
		if InCombatLockdown() then
			macroStatus:SetText("Wait until combat ends before creating a macro.")
			return
		end
		local index
		if existingIndex then
			index = EditMacro(existingIndex, name, nil, body)
		else
			index = CreateMacro(name, 134400, body, scope == "character")
		end
		if index and index > 0 then
			macroStatus:SetText("Macro saved. Roguetastiq did not run it.")
		else
			macroStatus:SetText("Macro could not be saved. Check the selected storage limit.")
		end
		updateMacroCounts()
	end
	StaticPopupDialogs["ROGUETASTIQ_CONFIRM_MACRO_REPLACE"] = {
		text = "Replace the existing macro named '%s'?",
		button1 = YES,
		button2 = CANCEL,
		OnAccept = function(_, data)
			createOrReplaceMacro(data.name, data.body, data.scope, data.index)
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		showAlert = true,
	}
	local createMacroButton = createButton(optionsPanel, "Create this macro", 180, 28,
		"TOPLEFT", optionsPanel, "TOPLEFT", 20, -492)
	createMacroButton:SetScript("OnClick", function()
		if InCombatLockdown() then
			macroStatus:SetText("Wait until combat ends before creating a macro.")
			return
		end
		local name = macroNameInput:GetText():match("^%s*(.-)%s*$")
		local body = macroPreview:GetText() or ""
		local scope = RoguetastiqDB.macroStorageScope or "character"
		if name == "" then macroStatus:SetText("Enter a macro name first."); return end
		if #name > 16 then macroStatus:SetText("Macro names can use at most 16 characters."); return end
		if body == "" then macroStatus:SetText("Macro text is empty."); return end
		if #body > 255 then macroStatus:SetText("Macro text exceeds the 255-character limit."); return end
		local existingIndex = macroIndexInScope(name, scope)
		if existingIndex then
			StaticPopup_Show("ROGUETASTIQ_CONFIRM_MACRO_REPLACE", name, nil,
				{ name = name, body = body, scope = scope, index = existingIndex })
			return
		end
		createOrReplaceMacro(name, body, scope)
	end)
	font(optionsPanel, "Review the visible text first. Create saves it; it does not execute the macro. Out of combat only.",
		"GameFontHighlightSmall", "TOPLEFT", optionsPanel, "TOPLEFT", 20, -527)
	updateMacroCounts()
	updateMacroPreview()
end

local function createThreatAlertSection()
	font(optionsPanel, "OPPOSING-FACTION ALERT", "GameFontNormal", "TOPLEFT", optionsPanel, "TOPLEFT", 20, -10)
	font(optionsPanel, "Sound alert when an opposing player appears on a visible enemy nameplate.",
		"GameFontHighlightSmall", "TOPLEFT", optionsPanel, "TOPLEFT", 20, -34)
	threatAlertToggle = createButton(optionsPanel, "", 185, 27, "TOPLEFT", optionsPanel, "TOPLEFT", 20, -68)
	local contextOptions = {
		{ key = "world", label = "Open world only" },
		{ key = "battlegrounds", label = "Battlegrounds and arenas" },
		{ key = "instances", label = "Dungeons and raids" },
		{ key = "all", label = "Everywhere" },
	}
	makeDropdown(optionsPanel, 210, 27, "TOPLEFT", optionsPanel, "TOPLEFT", 220, -68,
		contextOptions,
		function()
			for _, option in ipairs(contextOptions) do if option.key == RoguetastiqDB.playerAlertContext then return option end end
			return contextOptions[1]
		end,
		function(option)
			RoguetastiqDB.playerAlertContext = option.key
			ns.CheckHostilePlayers()
		end)
	font(optionsPanel, "Alert sound", "GameFontHighlightSmall", "TOPLEFT", optionsPanel, "TOPLEFT", 20, -112)
	makeDropdown(optionsPanel, 250, 27, "TOPLEFT", optionsPanel, "TOPLEFT", 20, -120,
		ns.AlertSounds,
		function()
			for _, option in ipairs(ns.AlertSounds) do
				if option.key == RoguetastiqDB.playerAlertSound then return option end
			end
			return ns.AlertSounds[1]
		end,
		function(option)
			RoguetastiqDB.playerAlertSound = option.key
		end)
	local testSound = createButton(optionsPanel, "Preview sound", 150, 27, "TOPLEFT", optionsPanel, "TOPLEFT", 285, -120)
	testSound:SetScript("OnClick", ns.PlayAlertSound)
	local function syncAlertToggle()
		threatAlertToggle:SetText("Nearby-player sound: " .. (RoguetastiqDB.playerAlertEnabled and "ON" or "OFF"))
	end
	threatAlertToggle:SetScript("OnClick", function()
		RoguetastiqDB.playerAlertEnabled = not RoguetastiqDB.playerAlertEnabled
		syncAlertToggle()
		ns.CheckHostilePlayers()
	end)
	syncAlertToggle()
	local alertNote = font(optionsPanel, "Emote choices make your character perform that emote. Detection uses visible enemy nameplates.",
		"GameFontHighlightSmall", "TOPLEFT", optionsPanel, "TOPLEFT", 20, -160)
	alertNote:SetWidth(640)
	alertNote:SetWordWrap(true)
end

local function createContactSection()
	font(optionsPanel, "CONTACT AND FEEDBACK", "GameFontNormal", "TOPLEFT", optionsPanel, "TOPLEFT", 20, -265)
	font(optionsPanel, "In-game mail: Steff Stabtastiq - PvP EU - Horde.",
		"GameFontHighlight", "TOPLEFT", optionsPanel, "TOPLEFT", 20, -290)
	local details = createButton(optionsPanel, "Show mail details in chat", 210, 27, "TOPLEFT", optionsPanel, "TOPLEFT", 20, -318)
	details:SetScript("OnClick", function()
		if ChatFrame1 then ChatFrame1:AddMessage("Roguetastiq feedback: in-game mail Steff Stabtastiq on PvP EU (Horde).") end
	end)
	font(optionsPanel, "Repository: https://github.com/fantastiqlabs/roguetastiq",
		"GameFontHighlight", "TOPLEFT", optionsPanel, "TOPLEFT", 20, -365)
	local repository = createButton(optionsPanel, "Show repository link in chat", 210, 27,
		"TOPLEFT", optionsPanel, "TOPLEFT", 20, -393)
	repository:SetScript("OnClick", function()
		if ChatFrame1 then ChatFrame1:AddMessage("Roguetastiq repository: https://github.com/fantastiqlabs/roguetastiq") end
	end)
end

local function syncCityVisibility(button)
	button:SetText("Hide bar in cities/inns: " .. (RoguetastiqDB.hideBarInCities and "ON" or "OFF"))
end

local function makeCounter(labelText, key, step, maxValue, x, top)
	font(optionsPanel, labelText, "GameFontHighlight", "TOPLEFT", optionsPanel, "TOPLEFT", x, top)
	local value = font(optionsPanel, "", "GameFontNormal", "TOPLEFT", optionsPanel, "TOPLEFT", x, top - 27)
	local minus = createButton(optionsPanel, "-", 28, 25, "TOPLEFT", optionsPanel, "TOPLEFT", x + 118, top - 18)
	local plus = createButton(optionsPanel, "+", 28, 25, "TOPLEFT", optionsPanel, "TOPLEFT", x + 150, top - 18)
	local function update()
		local current = RoguetastiqDB[key]
		if key == "timeThreshold" then
			value:SetText(string.format("%d min %02d sec", math.floor(current / 60), current % 60))
		elseif key == "fadeleafThreshold" then
			value:SetText(tostring(current) .. " Fadeleaf or fewer")
		elseif key == "flashPowderThreshold" then
			value:SetText(tostring(current) .. " or fewer")
		else
			value:SetText(tostring(current) .. " charges")
		end
	end
	minus:SetScript("OnClick", function()
		RoguetastiqDB[key] = math.max(0, RoguetastiqDB[key] - step)
		update(); ns.Render()
		if key == "flashPowderThreshold" then ns.CheckFlashPowderReminder() end
	end)
	plus:SetScript("OnClick", function()
		RoguetastiqDB[key] = math.min(maxValue, RoguetastiqDB[key] + step)
		update(); ns.Render()
		if key == "flashPowderThreshold" then ns.CheckFlashPowderReminder() end
	end)
	update()
end

local function makeSupplyToggle(key, label, x, y, onChanged)
	local toggle = CreateFrame("CheckButton", nil, optionsPanel, "UICheckButtonTemplate")
	toggle:SetSize(24, 24)
	toggle:SetPoint("TOPLEFT", optionsPanel, "TOPLEFT", x, y)
	local text = font(optionsPanel, label, "GameFontHighlight", "LEFT", toggle, "RIGHT", 4, 0)
	text:SetWidth(570)
	toggle:SetChecked(RoguetastiqDB[key] == true)
	toggle:SetScript("OnClick", function(self)
		RoguetastiqDB[key] = self:GetChecked()
		if onChanged then onChanged() end
	end)
	return toggle
end

local function setMinimapPosition()
	if not minimapButton then return end
	local angle = math.rad(RoguetastiqDB.minimapAngle or 220)
	local radius = (Minimap:GetWidth() / 2) + 8
	minimapButton:ClearAllPoints()
	minimapButton:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
end

local function createMinimapButton()
	minimapButton = CreateFrame("Button", "RoguetastiqMinimapButton", Minimap)
	minimapButton:SetSize(32, 32)
	minimapButton:SetFrameStrata("MEDIUM")
	minimapButton:SetFrameLevel(Minimap:GetFrameLevel() + 8)
	minimapButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	minimapButton:RegisterForDrag("MiddleButton")
	local icon = minimapButton:CreateTexture(nil, "ARTWORK")
	icon:SetSize(20, 20)
	icon:SetPoint("CENTER")
	icon:SetTexture(C_Item.GetItemIconByID(6947) or 134400)
	local border = minimapButton:CreateTexture(nil, "OVERLAY")
	border:SetSize(54, 54)
	border:SetPoint("CENTER")
	border:SetTexture("Interface/Minimap/MiniMap-TrackingBorder")
	minimapButton:SetScript("OnClick", function(_, button)
		if button == "LeftButton" then ns.OpenSettings() else ns.ToggleBar() end
	end)
	minimapButton:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		GameTooltip:AddLine("Roguetastiq")
		GameTooltip:AddLine("Left-click: settings", 1, 1, 1)
		GameTooltip:AddLine("Right-click: show or hide coating bar", 1, 1, 1)
		GameTooltip:AddLine("Middle-drag: move minimap button", 1, 1, 1)
		GameTooltip:Show()
	end)
	minimapButton:SetScript("OnLeave", GameTooltip_Hide)
	minimapButton:SetScript("OnDragStart", function(self)
		self:SetScript("OnUpdate", function()
			local centerX, centerY = Minimap:GetCenter()
			local cursorX, cursorY = GetCursorPosition()
			local scale = Minimap:GetEffectiveScale()
			cursorX, cursorY = cursorX / scale, cursorY / scale
			RoguetastiqDB.minimapAngle = math.deg(math.atan2(cursorY - centerY, cursorX - centerX))
			setMinimapPosition()
		end)
	end)
	minimapButton:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
	setMinimapPosition()
end

local function makeHandButton(index, hand, bar)
	local button = CreateFrame("Button", "Roguetastiq" .. hand .. "Button", bar,
		"SecureActionButtonTemplate,BackdropTemplate")
	button:SetSize(164, 68)
	button:SetPoint("LEFT", bar, "LEFT", index == 1 and 2 or 174, 0)
	button:SetFrameLevel(bar:GetFrameLevel() + 2)
	button:RegisterForClicks("AnyDown")
	button:SetAttribute("useOnKeyDown", true)
	setBackdrop(button, 0.98)
	button:SetBackdropColor(0.045, 0.055, 0.075, 0.98)
	button.title = font(button, hand, "GameFontNormalSmall", "TOP", button, "TOP", 0, -7)
	button.poisonIcon = button:CreateTexture(nil, "ARTWORK")
	button.poisonIcon:SetSize(20, 20)
	button.poisonIcon:SetPoint("LEFT", button, "LEFT", 7, -8)
	button.stoneIcon = button:CreateTexture(nil, "ARTWORK")
	button.stoneIcon:SetSize(20, 20)
	button.stoneIcon:SetPoint("RIGHT", button, "RIGHT", -7, -8)
	button.poisonLabel = font(button, "POISON", "GameFontNormalSmall", "TOPLEFT", button, "TOPLEFT", 30, -25)
	button.poisonLabel:SetWidth(48)
	button.poisonLabel:SetJustifyH("LEFT")
	button.poisonStatus = font(button, "", "GameFontHighlightSmall", "TOPLEFT", button, "TOPLEFT", 30, -42)
	button.poisonStatus:SetWidth(48)
	button.poisonStatus:SetJustifyH("LEFT")
	button.stoneLabel = font(button, "STONE", "GameFontNormalSmall", "TOPRIGHT", button, "TOPRIGHT", -30, -25)
	button.stoneLabel:SetWidth(48)
	button.stoneLabel:SetJustifyH("RIGHT")
	button.stoneStatus = font(button, "", "GameFontHighlightSmall", "TOPRIGHT", button, "TOPRIGHT", -30, -42)
	button.stoneStatus:SetWidth(48)
	button.stoneStatus:SetJustifyH("RIGHT")
	button:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:AddLine(hand .. " coatings")
		GameTooltip:AddLine("Left-click uses the selected poison. Modifiers use the configured choices.", 1, 1, 1)
		GameTooltip:Show()
	end)
	button:SetScript("OnLeave", GameTooltip_Hide)
	return button
end

function ns.ToggleBar()
	RoguetastiqDB.forceVisible = not RoguetastiqDB.forceVisible
	ns.Render()
end

function ns.InitializeInterface()
	local bar = CreateFrame("Frame", "RoguetastiqApplicationBar", UIParent, "BackdropTemplate")
	bar:SetSize(340, 72)
	bar:SetFrameStrata("MEDIUM")
	bar:SetMovable(not RoguetastiqDB.barLocked)
	bar:SetClampedToScreen(true)
	bar:EnableMouse(true)
	setBackdrop(bar, 0.9)
	bar:SetPoint("CENTER", UIParent, "CENTER", RoguetastiqDB.barX, RoguetastiqDB.barY)
	bar.leftButton = makeHandButton(1, "Main Hand", bar)
	bar.rightButton = makeHandButton(2, "Off Hand", bar)
	local divider = bar:CreateTexture(nil, "OVERLAY")
	divider:SetColorTexture(0.68, 0.48, 0.92, 0.95)
	divider:SetSize(2, 56)
	divider:SetPoint("CENTER", bar, "CENTER")
	bar.dragHandle = CreateFrame("Button", nil, bar, "BackdropTemplate")
	bar.dragHandle:SetSize(94, 18)
	bar.dragHandle:SetPoint("TOP", bar, "TOP", 0, 3)
	bar.dragHandle:SetFrameLevel(bar:GetFrameLevel() + 4)
	bar.dragHandle:SetBackdrop({ bgFile = "Interface/Buttons/WHITE8X8" })
	bar.dragHandle:SetBackdropColor(0.35, 0.22, 0.48, 0.98)
	bar.dragHandle.text = font(bar.dragHandle, "DRAG TO MOVE", "GameFontNormalSmall", "CENTER")
	bar.dragHandle:RegisterForClicks("LeftButtonUp")
	bar.dragHandle:RegisterForDrag("LeftButton")
	bar.dragHandle:SetScript("OnDragStart", function()
		if not RoguetastiqDB.barLocked then bar:StartMoving() end
	end)
	bar.dragHandle:SetScript("OnDragStop", function()
		bar:StopMovingOrSizing()
		local centerX, centerY = bar:GetCenter()
		local parentX, parentY = UIParent:GetCenter()
		if centerX and centerY and parentX and parentY then
			RoguetastiqDB.barX, RoguetastiqDB.barY = centerX - parentX, centerY - parentY
			bar:ClearAllPoints()
			bar:SetPoint("CENTER", UIParent, "CENTER", RoguetastiqDB.barX, RoguetastiqDB.barY)
		end
	end)
	bar.dragHandle:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:AddLine("Drag to place the coating bar")
		GameTooltip:AddLine("Position is saved for this character.", 1, 1, 1)
		GameTooltip:Show()
	end)
	bar.dragHandle:SetScript("OnLeave", GameTooltip_Hide)
	ns.Bar = bar
	bar:SetScale(RoguetastiqDB.barScale or 1)
	ns.HandButtons = { bar.leftButton, bar.rightButton }
	local settingsCanvas = CreateFrame("Frame", "RoguetastiqOptionsPanel", UIParent, "BackdropTemplate")
	settingsCanvas.name = "Roguetastiq"
	settingsCanvas:SetSize(740, 650)
	setBackdrop(settingsCanvas, 0.97)
	font(settingsCanvas, "Roguetastiq - The giga rogue toolkit!", "GameFontNormalLarge", "TOPLEFT", settingsCanvas, "TOPLEFT", 20, -14)
	local tabSpecs = {
		{ key = "qol", label = "QOL" },
		{ key = "macros", label = "Macros" },
		{ key = "settings", label = "Addon Settings" },
		{ key = "pvp", label = "PvP" },
		{ key = "maps", label = "Maps" },
		{ key = "supplies", label = "Supplies" },
	}
	local pages, tabs = {}, {}
	local tabWidth, tabStep = 112, 116
	for index, spec in ipairs(tabSpecs) do
		local tab = createButton(settingsCanvas, spec.label, tabWidth, 28,
			"TOPLEFT", settingsCanvas, "TOPLEFT", 20 + (index - 1) * tabStep, -42)
		local page = CreateFrame("Frame", nil, settingsCanvas)
		page:SetSize(680, 555)
		page:SetPoint("TOPLEFT", settingsCanvas, "TOPLEFT", 20, -78)
		page:Hide()
		pages[spec.key], tabs[spec.key] = page, tab
		local pageKey = spec.key
		tab:SetScript("OnClick", function()
			for key, candidate in pairs(pages) do
				if key == pageKey then candidate:Show() else candidate:Hide() end
			end
			for key, candidate in pairs(tabs) do candidate:SetEnabled(key ~= pageKey) end
		end)
	end
	local function selectPage(key)
		for pageKey, page in pairs(pages) do
			if pageKey == key then page:Show() else page:Hide() end
		end
		for tabKey, tab in pairs(tabs) do tab:SetEnabled(tabKey ~= key) end
	end

	optionsPanel = pages.qol
	font(optionsPanel, "QUALITY OF LIFE", "GameFontNormal", "TOPLEFT", optionsPanel, "TOPLEFT", 20, -8)
	font(optionsPanel, "Coating reminders, click actions, and poison shopping.",
		"GameFontHighlightSmall", "TOPLEFT", optionsPanel, "TOPLEFT", 20, -30)
	makeCounter("Low coating time", "timeThreshold", 30, 1800, 20, -62)
	makeCounter("Low coating charges", "chargeThreshold", 5, 500, 360, -62)
	local poisonToggle = createButton(optionsPanel, "", 175, 28, "TOPLEFT", optionsPanel, "TOPLEFT", 20, -110)
	local stoneToggle = createButton(optionsPanel, "", 175, 28, "TOPLEFT", optionsPanel, "TOPLEFT", 205, -110)
	local function syncToggles()
		poisonToggle:SetText("Poison warnings: " .. (RoguetastiqDB.poisonWarnings and "ON" or "OFF"))
		stoneToggle:SetText("Stone warnings: " .. (RoguetastiqDB.stoneWarnings and "ON" or "OFF"))
	end
	local function syncBarLock()
		bar:SetMovable(not RoguetastiqDB.barLocked)
		if RoguetastiqDB.barLocked then bar.dragHandle:Hide() else bar.dragHandle:Show() end
		syncToggles()
	end
	poisonToggle:SetScript("OnClick", function() RoguetastiqDB.poisonWarnings = not RoguetastiqDB.poisonWarnings; syncToggles(); ns.Render() end)
	stoneToggle:SetScript("OnClick", function() RoguetastiqDB.stoneWarnings = not RoguetastiqDB.stoneWarnings; syncToggles(); ns.Render() end)
	syncToggles()
	font(optionsPanel, "CLICK ACTIONS", "GameFontNormal", "TOPLEFT", optionsPanel, "TOPLEFT", 20, -154)
	font(optionsPanel, "MAIN HAND", "GameFontNormalSmall", "TOPLEFT", optionsPanel, "TOPLEFT", 20, -178)
	font(optionsPanel, "OFF HAND", "GameFontNormalSmall", "TOPLEFT", optionsPanel, "TOPLEFT", 350, -178)
	for _, hand in ipairs({ "mainhand", "offhand" }) do
		local x = hand == "mainhand" and 20 or 350
		for index, modifier in ipairs({ "left", "shift", "ctrl", "alt" }) do
			makeChoiceRow(hand, modifier, x, -200 - (index - 1) * 32)
		end
	end
	font(optionsPanel, "Selected poisons use the highest rank in your bags.",
		"GameFontHighlightSmall", "TOPLEFT", optionsPanel, "TOPLEFT", 20, -330)
	font(optionsPanel, "POISON SHOPPING PLANNER", "GameFontNormal", "TOPLEFT", optionsPanel, "TOPLEFT", 20, -354)
	createShoppingPlanner()
	local autoBuyToggle = CreateFrame("CheckButton", "RoguetastiqAutoBuyMaterials", optionsPanel, "UICheckButtonTemplate")
	autoBuyToggle:SetSize(24, 24)
	autoBuyToggle:SetPoint("TOPLEFT", optionsPanel, "TOPLEFT", 16, -516)
	local autoBuyLabel = font(optionsPanel, "Auto-buy on vendor open (off)",
		"GameFontHighlightSmall", "LEFT", autoBuyToggle, "RIGHT", 2, 0)
	autoBuyLabel:SetWidth(245)
	autoBuyToggle:SetChecked(RoguetastiqDB.autoBuyMaterials == true)
	autoBuyToggle:SetScript("OnClick", function(self)
		RoguetastiqDB.autoBuyMaterials = self:GetChecked()
		if ns.RefreshVendorShopping then ns.RefreshVendorShopping() end
	end)
	autoBuyToggle:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine("Automatic reagent shopping", 1, 1, 1)
		GameTooltip:AddLine("When enabled, opening a supported poison vendor requests only the currently previewed missing reagents. No poison is crafted.", 1, 1, 1, true)
		GameTooltip:Show()
	end)
	autoBuyToggle:SetScript("OnLeave", GameTooltip_Hide)
	local popupToggle = CreateFrame("CheckButton", "RoguetastiqVendorPopupEnabled", optionsPanel, "UICheckButtonTemplate")
	popupToggle:SetSize(24, 24)
	popupToggle:SetPoint("TOPLEFT", optionsPanel, "TOPLEFT", 350, -516)
	local popupLabel = font(optionsPanel, "Show vendor popup", "GameFontHighlightSmall", "LEFT", popupToggle, "RIGHT", 2, 0)
	popupToggle:SetChecked(RoguetastiqDB.vendorPopupEnabled ~= false)
	popupToggle:SetScript("OnClick", function(self)
		RoguetastiqDB.vendorPopupEnabled = self:GetChecked()
		if ns.RefreshVendorShopping then ns.RefreshVendorShopping() end
	end)
	popupToggle:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine("Poison-vendor shopping popup", 1, 1, 1)
		GameTooltip:AddLine("Show the reagent quantities and purchase controls when a supported poison reagent vendor is open.", 1, 1, 1, true)
		GameTooltip:Show()
	end)
	popupToggle:SetScript("OnLeave", GameTooltip_Hide)

	optionsPanel = pages.macros
	createMacroSection()

	optionsPanel = pages.settings
	font(optionsPanel, "ADDON SETTINGS", "GameFontNormal", "TOPLEFT", optionsPanel, "TOPLEFT", 20, -8)
	font(optionsPanel, "Application bar", "GameFontNormalSmall", "TOPLEFT", optionsPanel, "TOPLEFT", 20, -35)
	local forceToggle = createButton(optionsPanel, "", 190, 28, "TOPLEFT", optionsPanel, "TOPLEFT", 20, -55)
	local lockToggle = createButton(optionsPanel, "", 190, 28, "TOPLEFT", optionsPanel, "TOPLEFT", 220, -55)
	local function syncBarSettings()
		forceToggle:SetText(RoguetastiqDB.forceVisible and "Bar visibility: Always on" or "Bar visibility: Automatic")
		lockToggle:SetText(RoguetastiqDB.barLocked and "Unlock bar to move" or "Lock bar in place")
	end
	forceToggle:SetScript("OnClick", function() ns.ToggleBar(); syncBarSettings() end)
	lockToggle:SetScript("OnClick", function()
		RoguetastiqDB.barLocked = not RoguetastiqDB.barLocked
		syncBarLock()
		syncBarSettings()
	end)
	syncBarSettings()
	font(optionsPanel, "Bar size", "GameFontHighlightSmall", "TOPLEFT", optionsPanel, "TOPLEFT", 20, -104)
	local sizeOptions = {
		{ value = 0.8, key = "small", label = "Small (80%)" },
		{ value = 1, key = "standard", label = "Standard (100%)" },
		{ value = 1.2, key = "large", label = "Large (120%)" },
	}
	makeDropdown(optionsPanel, 155, 25, "TOPLEFT", optionsPanel, "TOPLEFT", 92, -110,
		sizeOptions,
		function()
			for _, option in ipairs(sizeOptions) do
				if math.abs((RoguetastiqDB.barScale or 1) - option.value) < 0.01 then return option end
			end
			return sizeOptions[2]
		end,
		function(option)
			RoguetastiqDB.barScale = option.value
			bar:SetScale(option.value)
		end)
	local moveHelp = font(optionsPanel, "Unlock, drag the purple grip, then lock the bar in place.",
		"GameFontHighlightSmall", "TOPLEFT", optionsPanel, "TOPLEFT", 20, -145)
	moveHelp:SetWidth(620)
	local cityVisibility = createButton(optionsPanel, "", 250, 28,
		"TOPLEFT", optionsPanel, "TOPLEFT", 20, -175)
	syncCityVisibility(cityVisibility)
	cityVisibility:SetScript("OnClick", function()
		RoguetastiqDB.hideBarInCities = not RoguetastiqDB.hideBarInCities
		syncCityVisibility(cityVisibility)
		ns.Render()
	end)
	font(optionsPanel, "Uses WoW's resting-area state; includes inns.",
		"GameFontHighlightSmall", "TOPLEFT", optionsPanel, "TOPLEFT", 20, -205)
	createContactSection()

	optionsPanel = pages.maps
	font(optionsPanel, "NPC MAP MARKERS", "GameFontNormal", "TOPLEFT", optionsPanel, "TOPLEFT", 20, -8)
	local mapDescription = font(optionsPanel,
		"Show Forever-seen Shady Dealers, poison reagent vendors, and Rogue trainers on the world map and minimap.",
		"GameFontHighlightSmall", "TOPLEFT", optionsPanel, "TOPLEFT", 20, -32)
	mapDescription:SetWidth(640)
	mapDescription:SetWordWrap(true)
	local function mapToggle(key, label, x, y)
		local toggle = CreateFrame("CheckButton", nil, optionsPanel, "UICheckButtonTemplate")
		toggle:SetSize(24, 24)
		toggle:SetPoint("TOPLEFT", optionsPanel, "TOPLEFT", x, y)
		local text = font(optionsPanel, label, "GameFontHighlight", "LEFT", toggle, "RIGHT", 4, 0)
		text:SetWidth(230)
		toggle:SetChecked(RoguetastiqDB[key] ~= false)
		toggle:SetScript("OnClick", function(self)
			RoguetastiqDB[key] = self:GetChecked()
			ns.RefreshMapMarkers()
		end)
	end
	mapToggle("mapMarkersEnabled", "World map markers", 16, -76)
	mapToggle("minimapMarkersEnabled", "Minimap markers", 350, -76)
	font(optionsPanel, "MARKER CATEGORIES", "GameFontNormal", "TOPLEFT", optionsPanel, "TOPLEFT", 20, -126)
	mapToggle("mapShowShadyDealer", "Shady Dealers", 16, -150)
	mapToggle("mapShowPoisonVendor", "Poison reagent vendors", 16, -184)
	mapToggle("mapShowRogueTrainer", "Rogue trainers", 16, -218)
	local mapNote = font(optionsPanel,
		"NPC locations are sourced from Forever observations. Coordinates can vary by client build; report missing or misplaced pins before release.",
		"GameFontHighlightSmall", "TOPLEFT", optionsPanel, "TOPLEFT", 20, -254)
	mapNote:SetWidth(640)
	mapNote:SetWordWrap(true)

	optionsPanel = pages.supplies
	font(optionsPanel, "ROGUE SUPPLIES", "GameFontNormal", "TOPLEFT", optionsPanel, "TOPLEFT", 20, -8)
	font(optionsPanel, "Configurable bag reminders for Fadeleaf and Flash Powder.",
		"GameFontHighlightSmall", "TOPLEFT", optionsPanel, "TOPLEFT", 20, -30)
	makeSupplyToggle("fadeleafReminder", "Remind me about Fadeleaf at vendors and the Auction House.", 16, -56)
	makeCounter("Fadeleaf reminder at or below", "fadeleafThreshold", 1, 100, 20, -94)
	makeSupplyToggle("flashPowderWarning", "Warn when Flash Powder is running low.", 16, -148,
		function() ns.CheckFlashPowderReminder() end)
	makeCounter("Flash Powder warning at or below", "flashPowderThreshold", 1, 100, 20, -186)
	local priceNote = font(optionsPanel,
		"Last-paid Fadeleaf price is not shown: the current client does not expose a reliable purchase-history value.",
		"GameFontHighlightSmall", "TOPLEFT", optionsPanel, "TOPLEFT", 20, -242)
	priceNote:SetWidth(630)
	priceNote:SetWordWrap(true)

	optionsPanel = pages.pvp
	createThreatAlertSection()
	selectPage("qol")

	if C_AddOns and C_AddOns.LoadAddOn and C_AddOns.IsAddOnLoaded
		and not C_AddOns.IsAddOnLoaded("Blizzard_Settings") then
		C_AddOns.LoadAddOn("Blizzard_Settings")
	end
	if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
		category = Settings.RegisterCanvasLayoutCategory(settingsCanvas, "Roguetastiq")
		Settings.RegisterAddOnCategory(category)
	end
	ns.OptionsPanel = pages.qol
	ns.OpenSettings = function()
		if category and Settings and Settings.OpenToCategory then
			Settings.OpenToCategory(category.ID or category:GetID())
		else
			settingsCanvas:Show()
		end
	end
	createMinimapButton()
end
