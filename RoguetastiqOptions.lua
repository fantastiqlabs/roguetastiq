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
local threatAlertToggle
local macroOptions = {
	{ key = "kick", label = "Kick · focus or target", text = "#showtooltip Kick\n/cast [@focus,harm,nodead][] Kick" },
	{ key = "sap", label = "Sap · mouseover or target", text = "#showtooltip Sap\n/stopattack\n/cast [@mouseover,harm,nodead][] Sap" },
	{ key = "sapnearest", label = "Sap · nearest enemy", text = "#showtooltip Sap\n/stopattack\n/targetenemy [noharm][dead]\n/cast [harm,nodead] Sap" },
	{ key = "stealth", label = "Stealth · spam safe", text = "#showtooltip Stealth\n/dismount [mounted]\n/cast [nostealth] Stealth" },
	{ key = "opener", label = "Stealth → opener", text = "#showtooltip\n/cast [nostealth] Stealth; [mod:shift] Garrote; [mod:ctrl] Ambush; Cheap Shot" },
	{ key = "vanish", label = "Stealth / Vanish", text = "#showtooltip\n/stopattack [combat]\n/cast [nocombat] !Stealth; Vanish" },
	{ key = "stealthfood", label = "Stealth, then eat", text = "#showtooltip\n/cast [nostealth] !Stealth\n/use [stealth] FOOD_ITEM" },
	{ key = "pickpocket", label = "Pick Pocket → Ambush", text = "#showtooltip Ambush\n/cast [stealth] Pick Pocket\n/cast Ambush" },
	{ key = "pickpocketshot", label = "Pick Pocket → Cheap Shot", text = "#showtooltip Cheap Shot\n/cast [stealth] Pick Pocket\n/cast Cheap Shot" },
	{ key = "cheapshot", label = "Cheap Shot from Stealth", text = "#showtooltip Cheap Shot\n/cast [nostealth] Stealth; Cheap Shot" },
	{ key = "blind", label = "Blind", text = "#showtooltip Blind\n/cast Blind" },
	{ key = "attack", label = "Sinister Strike + auto attack", text = "#showtooltip Sinister Strike\n/cast Sinister Strike\n/startattack" },
	{ key = "riposte", label = "Riposte, then Sinister Strike", text = "#showtooltip\n/cast Riposte\n/cast Sinister Strike\n/startattack" },
	{ key = "shank", label = "Shank + Sinister Strike", text = "#showtooltip\n/startattack\n/cast Shank\n/cast Sinister Strike" },
	{ key = "stealthambush", label = "Ambush from Stealth, Backstab after", text = "#showtooltip\n/cast [stealth] Ambush; Backstab\n/startattack [nostealth]" },
	{ key = "stealthweapon", label = "Dagger from Stealth, weapon after", text = "#showtooltip [stealth] Ambush; Sinister Strike\n/equipslot [stealth] 16 Dagger Name; 16 Main-Hand Weapon Name\n/cast [stealth] Ambush; Sinister Strike\n/startattack [nostealth]" },
	{ key = "daggerambush", label = "Dagger Ambush / Backstab", text = "#showtooltip [mod:shift] Backstab; Ambush\n/equipslot 16 Dagger Name\n/cast [mod:shift] Backstab; Ambush\n/startattack [nostealth]" },
	{ key = "evasion", label = "Evasion + Sprint", text = "#showtooltip Evasion\n/cast Evasion\n/cast Sprint" },
	{ key = "flurry", label = "Blade Flurry toggle", text = "#showtooltip Blade Flurry\n/cancelaura Blade Flurry\n/cast Blade Flurry" },
	{ key = "burst", label = "Burst · trinkets + cooldowns", text = "#showtooltip Adrenaline Rush\n/use 13\n/use 14\n/cast %RACIAL%\n/cast Adrenaline Rush\n/cast Blade Flurry" },
}
local racialOptions = {
	{ key = "none", label = "No racial" },
	{ key = "Blood Fury", label = "Orc · Blood Fury" },
	{ key = "Berserking", label = "Troll · Berserking" },
	{ key = "Eureka!", label = "Gnome · Eureka!" },
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
			popup:Hide()
			openDropdown = nil
		end)
		entry:SetBackdrop({ bgFile = "Interface/Buttons/WHITE8X8" })
		entry:SetBackdropColor(0, 0, 0, 0)
	end
	local function updateLabel()
		local selected = getSelected()
		button:SetText((selected and (selected.buttonLabel or selected.label) or "Select") .. "  ▾")
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
	local choiceButton = makeDropdown(optionsPanel, 188, 25, "TOPLEFT", optionsPanel, "TOPLEFT", x + 86, y + 5,
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
	content = content:gsub("FOOD_ITEM", RoguetastiqDB.macroFoodName or "Food Name")
	if key == "burst" then
		local racial = RoguetastiqDB.macroRacial or "none"
		content = content:gsub("/cast %%RACIAL%%\n", racial == "none" and "" or ("/cast " .. racial .. "\n"))
	end
	if RoguetastiqDB.laughInMacros and (key == "cheapshot" or key == "blind") then
		content = content:gsub("\n/cast", "\n/laugh\n/cast")
	end
	macroPreview:SetText(content)
	if macroDropdown then macroDropdown:Refresh() end
end

local function createShoppingPlanner()
	local recipeOptions = {}
	for _, recipe in ipairs(ns.Catalog.recipes) do
		recipeOptions[#recipeOptions + 1] = { key = recipe.key, label = recipe.label, buttonLabel = recipe.label }
	end
	shoppingSummary = font(optionsPanel, "Choose a poison and quantity to calculate materials to buy.",
		"GameFontHighlightSmall", "TOPLEFT", optionsPanel, "TOPLEFT", 20, -500)
	for index = 1, 4 do
		shoppingRows[index] = font(optionsPanel, "", "GameFontHighlightSmall", "TOPLEFT", optionsPanel, "TOPLEFT", 32, -526 - (index - 1) * 22)
	end
	shoppingRecipeDropdown = makeDropdown(optionsPanel, 265, 27, "TOPLEFT", optionsPanel, "TOPLEFT", 20, -460,
		recipeOptions,
		function()
			local key = RoguetastiqDB.shoppingRecipeKey or "instant6"
			for _, option in ipairs(recipeOptions) do if option.key == key then return option end end
			return recipeOptions[1]
		end,
		function(option) RoguetastiqDB.shoppingRecipeKey = option.key; updateShopping() end)
	local countTitle = font(optionsPanel, "Number to make", "GameFontHighlightSmall", "TOPLEFT", optionsPanel, "TOPLEFT", 310, -442)
	shoppingCountLabel = font(optionsPanel, "", "GameFontNormal", "TOPLEFT", optionsPanel, "TOPLEFT", 310, -466)
	local function updateCount(delta)
		RoguetastiqDB.shoppingCount = math.max(1, math.min(200, (RoguetastiqDB.shoppingCount or 20) + delta))
		updateShopping()
	end
	local minusFive = createButton(optionsPanel, "−5", 36, 25, "TOPLEFT", optionsPanel, "TOPLEFT", 390, -455)
	local minusOne = createButton(optionsPanel, "−1", 36, 25, "TOPLEFT", optionsPanel, "TOPLEFT", 430, -455)
	local plusOne = createButton(optionsPanel, "+1", 36, 25, "TOPLEFT", optionsPanel, "TOPLEFT", 470, -455)
	local plusFive = createButton(optionsPanel, "+5", 36, 25, "TOPLEFT", optionsPanel, "TOPLEFT", 510, -455)
	local calculate = createButton(optionsPanel, "Calculate", 108, 25, "TOPLEFT", optionsPanel, "TOPLEFT", 552, -455)
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
		shoppingSummary:SetText(string.format("For %d × %s (no items are purchased automatically):", RoguetastiqDB.shoppingCount or 20, recipe.label))
		for index, row in ipairs(shoppingRows) do
			local material = materials[index]
			if material then
				row:SetText(string.format("%s: need %d · have %d · buy %d", material.name, material.required, material.have, material.buy))
				row:Show()
			else
				row:Hide()
			end
		end
	end
	ns.RefreshShoppingPlanner = updateShopping
	updateShopping()
end

local function createMacroSection()
	font(optionsPanel, "ROGUE MACRO BUILDER", "GameFontNormal", "TOPLEFT", optionsPanel, "TOPLEFT", 20, -625)
	font(optionsPanel, "Select a template, then select its text and copy it into WoW's macro editor.",
		"GameFontHighlightSmall", "TOPLEFT", optionsPanel, "TOPLEFT", 20, -648)
	local macroChoices = {}
	for _, option in ipairs(macroOptions) do
		macroChoices[#macroChoices + 1] = { key = option.key, label = option.label, buttonLabel = option.label }
	end
	macroDropdown = makeDropdown(optionsPanel, 290, 27, "TOPLEFT", optionsPanel, "TOPLEFT", 20, -680,
		macroChoices,
		function()
			for _, option in ipairs(macroChoices) do
				if option.key == (RoguetastiqDB.macroTemplate or "kick") then return option end
			end
			return macroChoices[1]
		end,
		function(option) RoguetastiqDB.macroTemplate = option.key; updateMacroPreview() end)
	local laughToggle = createButton(optionsPanel, "", 260, 27, "TOPLEFT", optionsPanel, "TOPLEFT", 300, -680)
	local function syncLaughToggle()
		laughToggle:SetText("Add /laugh to Cheap Shot/Blind: " .. (RoguetastiqDB.laughInMacros and "ON" or "OFF"))
	end
	laughToggle:SetScript("OnClick", function()
		RoguetastiqDB.laughInMacros = not RoguetastiqDB.laughInMacros
		syncLaughToggle()
		updateMacroPreview()
	end)
	syncLaughToggle()
	local racialDropdown = makeDropdown(optionsPanel, 260, 27, "TOPLEFT", optionsPanel, "TOPLEFT", 20, -715,
		racialOptions,
		function()
			for _, option in ipairs(racialOptions) do if option.key == (RoguetastiqDB.macroRacial or "none") then return option end end
			return racialOptions[1]
		end,
		function(option) RoguetastiqDB.macroRacial = option.key; updateMacroPreview() end)
	font(optionsPanel, "Burst racial", "GameFontHighlightSmall", "TOPLEFT", optionsPanel, "TOPLEFT", 20, -696)
	local foodName = CreateFrame("EditBox", nil, optionsPanel, "InputBoxTemplate")
	foodName:SetAutoFocus(false)
	foodName:SetSize(220, 25)
	foodName:SetPoint("TOPLEFT", optionsPanel, "TOPLEFT", 320, -715)
	foodName:SetText(RoguetastiqDB.macroFoodName or "Food Name")
	foodName:SetScript("OnEnterPressed", function(self)
		RoguetastiqDB.macroFoodName = self:GetText()
		self:ClearFocus()
		updateMacroPreview()
	end)
	font(optionsPanel, "Food item for Stealth → eat (press Enter to save)", "GameFontHighlightSmall",
		"TOPLEFT", optionsPanel, "TOPLEFT", 320, -696)
	macroPreview = CreateFrame("EditBox", nil, optionsPanel, "InputBoxTemplate")
	macroPreview:SetMultiLine(true)
	macroPreview:SetAutoFocus(false)
	macroPreview:SetSize(640, 90)
	macroPreview:SetPoint("TOPLEFT", optionsPanel, "TOPLEFT", 24, -750)
	macroPreview:SetFontObject(GameFontHighlightSmall)
	macroPreview:SetTextInsets(8, 8, 8, 8)
	macroPreview:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	macroPreview:SetScript("OnEditFocusLost", function(self) self:HighlightText(0, 0) end)
	local selectText = createButton(optionsPanel, "Select macro text", 150, 25, "TOPLEFT", optionsPanel, "TOPLEFT", 20, -849)
	selectText:SetScript("OnClick", function() macroPreview:SetFocus(); macroPreview:HighlightText() end)
	font(optionsPanel, "Macros are previews for you to copy; the addon does not create or run them.",
		"GameFontHighlightSmall", "LEFT", selectText, "RIGHT", 12, 0)
	updateMacroPreview()
end

local function createThreatAlertSection()
	font(optionsPanel, "OPPOSING-FACTION PLAYER ALERT", "GameFontNormal", "TOPLEFT", optionsPanel, "TOPLEFT", 20, -900)
	font(optionsPanel, "Sound alert when an opposing player appears on a visible enemy nameplate.",
		"GameFontHighlightSmall", "TOPLEFT", optionsPanel, "TOPLEFT", 20, -923)
	threatAlertToggle = createButton(optionsPanel, "", 190, 27, "TOPLEFT", optionsPanel, "TOPLEFT", 20, -953)
	local contextOptions = {
		{ key = "world", label = "Open world only" },
		{ key = "battlegrounds", label = "Battlegrounds and arenas" },
		{ key = "instances", label = "Dungeons and raids" },
		{ key = "all", label = "Everywhere" },
	}
	local contextDropdown = makeDropdown(optionsPanel, 220, 27, "TOPLEFT", optionsPanel, "TOPLEFT", 225, -953,
		contextOptions,
		function()
			for _, option in ipairs(contextOptions) do if option.key == RoguetastiqDB.playerAlertContext then return option end end
			return contextOptions[1]
		end,
		function(option)
			RoguetastiqDB.playerAlertContext = option.key
			ns.CheckHostilePlayers()
		end)
	local testSound = createButton(optionsPanel, "Test alert sound", 145, 27, "TOPLEFT", optionsPanel, "TOPLEFT", 460, -953)
	testSound:SetScript("OnClick", function()
		if PlaySound then PlaySound((SOUNDKIT and SOUNDKIT.RAID_WARNING) or 8959, "Master") end
	end)
	local function syncAlertToggle()
		threatAlertToggle:SetText("Nearby-player sound: " .. (RoguetastiqDB.playerAlertEnabled and "ON" or "OFF"))
	end
	threatAlertToggle:SetScript("OnClick", function()
		RoguetastiqDB.playerAlertEnabled = not RoguetastiqDB.playerAlertEnabled
		syncAlertToggle()
		ns.CheckHostilePlayers()
	end)
	syncAlertToggle()
	font(optionsPanel, "Detection uses visible nameplates; turn on enemy player nameplates in WoW's interface settings.",
		"GameFontHighlightSmall", "TOPLEFT", optionsPanel, "TOPLEFT", 20, -985)
end

local function createContactSection()
	font(optionsPanel, "CONTACT AND FEEDBACK", "GameFontNormal", "TOPLEFT", optionsPanel, "TOPLEFT", 20, -1025)
	font(optionsPanel, "In-game mail: Steff Stabtastiq · PvP EU · Horde.",
		"GameFontHighlight", "TOPLEFT", optionsPanel, "TOPLEFT", 20, -1050)
	local details = createButton(optionsPanel, "Show mail details in chat", 190, 27, "TOPLEFT", optionsPanel, "TOPLEFT", 20, -1078)
	details:SetScript("OnClick", function()
		ChatFrame1:AddMessage("Roguetastiq feedback: in-game mail Steff Stabtastiq on PvP EU (Horde).")
	end)
	font(optionsPanel, "Repository: click the link field, then Ctrl+C to copy:",
		"GameFontHighlightSmall", "TOPLEFT", optionsPanel, "TOPLEFT", 230, -1077)
	local repository = CreateFrame("EditBox", nil, optionsPanel, "InputBoxTemplate")
	repository:SetAutoFocus(false)
	repository:SetSize(410, 25)
	repository:SetPoint("TOPLEFT", optionsPanel, "TOPLEFT", 230, -1107)
	repository:SetText("https://github.com/fantastiqlabs/roguetastiq")
	repository:SetScript("OnMouseDown", function(self) self:SetFocus(); self:HighlightText() end)
	repository:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
end

local function makeCounter(labelText, key, step, maxValue, x)
	font(optionsPanel, labelText, "GameFontHighlight", "TOPLEFT", optionsPanel, "TOPLEFT", x, -89)
	local value = font(optionsPanel, "", "GameFontNormal", "TOPLEFT", optionsPanel, "TOPLEFT", x, -116)
	local minus = createButton(optionsPanel, "−", 28, 25, "TOPLEFT", optionsPanel, "TOPLEFT", x + 118, -107)
	local plus = createButton(optionsPanel, "+", 28, 25, "TOPLEFT", optionsPanel, "TOPLEFT", x + 150, -107)
	local function update()
		local current = RoguetastiqDB[key]
		if key == "timeThreshold" then
			value:SetText(string.format("%d min %02d sec", math.floor(current / 60), current % 60))
		else
			value:SetText(tostring(current) .. " charges")
		end
	end
	minus:SetScript("OnClick", function()
		RoguetastiqDB[key] = math.max(0, RoguetastiqDB[key] - step)
		update(); ns.Render()
	end)
	plus:SetScript("OnClick", function()
		RoguetastiqDB[key] = math.min(maxValue, RoguetastiqDB[key] + step)
		update(); ns.Render()
	end)
	update()
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
	button:SetSize(148, 68)
	button:SetPoint("LEFT", bar, "LEFT", index == 1 and 2 or 156, 0)
	button:SetFrameLevel(bar:GetFrameLevel() + 2)
	button:RegisterForClicks("AnyDown")
	button:SetAttribute("useOnKeyDown", true)
	setBackdrop(button, 0.98)
	button:SetBackdropColor(0.045, 0.055, 0.075, 0.98)
	button.title = font(button, hand, "GameFontNormalSmall", "TOP", button, "TOP", 0, -7)
	button.poisonIcon = button:CreateTexture(nil, "ARTWORK")
	button.poisonIcon:SetSize(28, 28)
	button.poisonIcon:SetPoint("LEFT", button, "LEFT", 13, -8)
	button.stoneIcon = button:CreateTexture(nil, "ARTWORK")
	button.stoneIcon:SetSize(28, 28)
	button.stoneIcon:SetPoint("RIGHT", button, "RIGHT", -13, -8)
	button.poisonLabel = font(button, "POISON", "GameFontNormalSmall", "TOPLEFT", button, "TOPLEFT", 45, -31)
	button.poisonStatus = font(button, "", "GameFontHighlightSmall", "TOPLEFT", button, "TOPLEFT", 45, -47)
	button.stoneLabel = font(button, "STONE", "GameFontNormalSmall", "TOPRIGHT", button, "TOPRIGHT", -43, -31)
	button.stoneStatus = font(button, "", "GameFontHighlightSmall", "TOPRIGHT", button, "TOPRIGHT", -43, -47)
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
	bar:SetSize(306, 72)
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
		local _, _, _, x, y = bar:GetPoint(1)
		if type(x) == "number" and type(y) == "number" then
			RoguetastiqDB.barX, RoguetastiqDB.barY = x, y
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
	local scroll = CreateFrame("ScrollFrame", nil, settingsCanvas, "UIPanelScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", settingsCanvas, "TOPLEFT", 8, -8)
	scroll:SetPoint("BOTTOMRIGHT", settingsCanvas, "BOTTOMRIGHT", -28, 8)
	optionsPanel = CreateFrame("Frame", nil, scroll)
	optionsPanel:SetSize(700, 1140)
	scroll:SetScrollChild(optionsPanel)
	font(optionsPanel, "Roguetastiq - The giga rogue toolkit!", "GameFontNormalLarge", "TOPLEFT", optionsPanel, "TOPLEFT", 20, -18)
	font(optionsPanel, "Configure coating alerts, click profiles, poison shopping, and macros.",
		"GameFontHighlightSmall", "TOPLEFT", optionsPanel, "TOPLEFT", 20, -45)

	makeCounter("Low coating time", "timeThreshold", 30, 1800, 20)
	makeCounter("Low coating charges", "chargeThreshold", 5, 500, 360)

	local poisonToggle = createButton(optionsPanel, "", 140, 28, "TOPLEFT", optionsPanel, "TOPLEFT", 20, -145)
	local stoneToggle = createButton(optionsPanel, "", 140, 28, "TOPLEFT", optionsPanel, "TOPLEFT", 170, -145)
	local forceToggle = createButton(optionsPanel, "", 170, 28, "TOPLEFT", optionsPanel, "TOPLEFT", 320, -145)
	local lockToggle = createButton(optionsPanel, "", 170, 28, "TOPLEFT", optionsPanel, "TOPLEFT", 480, -145)
	local function syncToggles()
		poisonToggle:SetText("Poison warnings: " .. (RoguetastiqDB.poisonWarnings and "ON" or "OFF"))
		stoneToggle:SetText("Stone warnings: " .. (RoguetastiqDB.stoneWarnings and "ON" or "OFF"))
		forceToggle:SetText("Application bar: " .. (RoguetastiqDB.forceVisible and "FORCED ON" or "Auto"))
		lockToggle:SetText(RoguetastiqDB.barLocked and "Unlock bar to move" or "Lock bar in place")
	end
	local function syncBarLock()
		bar:SetMovable(not RoguetastiqDB.barLocked)
		if RoguetastiqDB.barLocked then bar.dragHandle:Hide() else bar.dragHandle:Show() end
		syncToggles()
	end
	poisonToggle:SetScript("OnClick", function() RoguetastiqDB.poisonWarnings = not RoguetastiqDB.poisonWarnings; syncToggles(); ns.Render() end)
	stoneToggle:SetScript("OnClick", function() RoguetastiqDB.stoneWarnings = not RoguetastiqDB.stoneWarnings; syncToggles(); ns.Render() end)
	forceToggle:SetScript("OnClick", function() ns.ToggleBar(); syncToggles() end)
	lockToggle:SetScript("OnClick", function()
		RoguetastiqDB.barLocked = not RoguetastiqDB.barLocked
		syncBarLock()
	end)
	syncBarLock()
	font(optionsPanel, "Bar size", "GameFontHighlightSmall", "TOPLEFT", optionsPanel, "TOPLEFT", 20, -182)
	local sizeOptions = {
		{ value = 0.8, key = "small", label = "Small · 80%" },
		{ value = 1, key = "standard", label = "Standard · 100%" },
		{ value = 1.2, key = "large", label = "Large · 120%" },
	}
	makeDropdown(optionsPanel, 158, 25, "TOPLEFT", optionsPanel, "TOPLEFT", 86, -190,
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
	font(optionsPanel, "Unlock, drag the purple grip to your preferred position, then lock it.",
		"GameFontHighlightSmall", "LEFT", optionsPanel, "TOPLEFT", 270, -178)

	font(optionsPanel, "MAIN HAND", "GameFontNormal", "TOPLEFT", optionsPanel, "TOPLEFT", 20, -218)
	font(optionsPanel, "OFF HAND", "GameFontNormal", "TOPLEFT", optionsPanel, "TOPLEFT", 360, -218)
	for _, hand in ipairs({ "mainhand", "offhand" }) do
		local x = hand == "mainhand" and 20 or 360
		for index, modifier in ipairs({ "left", "shift", "ctrl", "alt" }) do
			makeChoiceRow(hand, modifier, x, -242 - (index - 1) * 39)
		end
	end
	font(optionsPanel, "Selected poison families use the highest rank in your bags.",
		"GameFontHighlightSmall", "TOPLEFT", optionsPanel, "TOPLEFT", 20, -386)
	font(optionsPanel, "POISON SHOPPING PLANNER", "GameFontNormal", "TOPLEFT", optionsPanel, "TOPLEFT", 20, -409)
	createShoppingPlanner()
	createMacroSection()
	createThreatAlertSection()
	createContactSection()

	if C_AddOns and C_AddOns.LoadAddOn and C_AddOns.IsAddOnLoaded
		and not C_AddOns.IsAddOnLoaded("Blizzard_Settings") then
		C_AddOns.LoadAddOn("Blizzard_Settings")
	end
	if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
		category = Settings.RegisterCanvasLayoutCategory(settingsCanvas, "Roguetastiq")
		Settings.RegisterAddOnCategory(category)
	end
	ns.OptionsPanel = optionsPanel
	ns.OpenSettings = function()
		if category and Settings and Settings.OpenToCategory then
			Settings.OpenToCategory(category.ID or category:GetID())
		else
			settingsCanvas:Show()
		end
	end
	createMinimapButton()
end
