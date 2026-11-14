local _, ns = ...

local choiceRows = {}
local optionsPanel
local category
local minimapButton

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

local function modifierLabel(modifier)
	if modifier == "left" then return "Left click" end
	return modifier:sub(1, 1):upper() .. modifier:sub(2) .. " + click"
end

local function makeChoiceRow(hand, modifier, x, y)
	font(optionsPanel, modifierLabel(modifier), "GameFontHighlightSmall", "TOPLEFT", optionsPanel, "TOPLEFT", x, y)
	local choiceButton = createButton(optionsPanel, "", 218, 27, "TOPLEFT", optionsPanel, "TOPLEFT", x + 92, y + 6)
	local row = {}
	function row:Refresh()
		local binding = RoguetastiqDB.bindings[hand][modifier]
		choiceButton:SetText(ns.CoatingChoiceLabel(binding))
	end
	choiceButton:SetScript("OnClick", function()
		local current = RoguetastiqDB.bindings[hand][modifier]
		local currentIndex = 0
		for index, option in ipairs(ns.Catalog.options) do
			if option.kind == current.kind and option.key == current.key then currentIndex = index; break end
		end
		local option = ns.Catalog.options[(currentIndex % #ns.Catalog.options) + 1]
		RoguetastiqDB.bindings[hand][modifier] = { kind = option.kind, key = option.key }
		refresh()
	end)
	row:Refresh()
	choiceRows[#choiceRows + 1] = row
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
	bar:SetMovable(true)
	bar:EnableMouse(true)
	setBackdrop(bar, 0.9)
	bar:SetPoint("CENTER", UIParent, "CENTER", RoguetastiqDB.barX, RoguetastiqDB.barY)
	bar.leftButton = makeHandButton(1, "Main Hand", bar)
	bar.rightButton = makeHandButton(2, "Off Hand", bar)
	local divider = bar:CreateTexture(nil, "OVERLAY")
	divider:SetColorTexture(0.68, 0.48, 0.92, 0.95)
	divider:SetSize(2, 56)
	divider:SetPoint("CENTER", bar, "CENTER")
	bar.dragHandle = CreateFrame("Frame", nil, bar)
	bar.dragHandle:SetSize(42, 6)
	bar.dragHandle:SetPoint("TOP", bar, "TOP", 0, 1)
	bar.dragHandle:EnableMouse(true)
	bar.dragHandle:RegisterForDrag("LeftButton")
	bar.dragHandle:SetScript("OnDragStart", function() bar:StartMoving() end)
	bar.dragHandle:SetScript("OnDragStop", function()
		bar:StopMovingOrSizing()
		local _, _, _, x, y = bar:GetPoint(1)
		RoguetastiqDB.barX, RoguetastiqDB.barY = x, y
	end)
	ns.Bar = bar
	ns.HandButtons = { bar.leftButton, bar.rightButton }
	optionsPanel = CreateFrame("Frame", "RoguetastiqOptionsPanel", UIParent, "BackdropTemplate")
	optionsPanel.name = "Roguetastiq"
	optionsPanel:SetSize(700, 570)
	setBackdrop(optionsPanel, 0.97)
	font(optionsPanel, "Roguetastiq - The giga rogue toolkit!", "GameFontNormalLarge", "TOPLEFT", optionsPanel, "TOPLEFT", 20, -18)
	font(optionsPanel, "Configure coating alerts and every click profile. Click an entry to cycle its choice.",
		"GameFontHighlightSmall", "TOPLEFT", optionsPanel, "TOPLEFT", 20, -45)

	makeCounter("Low coating time", "timeThreshold", 30, 1800, 20)
	makeCounter("Low coating charges", "chargeThreshold", 5, 500, 360)

	local poisonToggle = createButton(optionsPanel, "", 164, 28, "TOPLEFT", optionsPanel, "TOPLEFT", 20, -145)
	local stoneToggle = createButton(optionsPanel, "", 164, 28, "TOPLEFT", optionsPanel, "TOPLEFT", 190, -145)
	local forceToggle = createButton(optionsPanel, "", 200, 28, "TOPLEFT", optionsPanel, "TOPLEFT", 360, -145)
	local function syncToggles()
		poisonToggle:SetText("Poison warnings: " .. (RoguetastiqDB.poisonWarnings and "ON" or "OFF"))
		stoneToggle:SetText("Stone warnings: " .. (RoguetastiqDB.stoneWarnings and "ON" or "OFF"))
		forceToggle:SetText("Application bar: " .. (RoguetastiqDB.forceVisible and "FORCED ON" or "Auto"))
	end
	poisonToggle:SetScript("OnClick", function() RoguetastiqDB.poisonWarnings = not RoguetastiqDB.poisonWarnings; syncToggles(); ns.Render() end)
	stoneToggle:SetScript("OnClick", function() RoguetastiqDB.stoneWarnings = not RoguetastiqDB.stoneWarnings; syncToggles(); ns.Render() end)
	forceToggle:SetScript("OnClick", function() ns.ToggleBar(); syncToggles() end)
	syncToggles()

	font(optionsPanel, "MAIN HAND", "GameFontNormal", "TOPLEFT", optionsPanel, "TOPLEFT", 20, -190)
	font(optionsPanel, "OFF HAND", "GameFontNormal", "TOPLEFT", optionsPanel, "TOPLEFT", 360, -190)
	for _, hand in ipairs({ "mainhand", "offhand" }) do
		local x = hand == "mainhand" and 20 or 360
		for index, modifier in ipairs({ "left", "shift", "ctrl", "alt" }) do
			makeChoiceRow(hand, modifier, x, -214 - (index - 1) * 39)
		end
	end
	font(optionsPanel, "Selected poisons use the highest rank in your bags. Each button applies only after your click.",
		"GameFontHighlightSmall", "BOTTOMLEFT", optionsPanel, "BOTTOMLEFT", 20, 22)

	if C_AddOns and C_AddOns.LoadAddOn and C_AddOns.IsAddOnLoaded
		and not C_AddOns.IsAddOnLoaded("Blizzard_Settings") then
		C_AddOns.LoadAddOn("Blizzard_Settings")
	end
	if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
		category = Settings.RegisterCanvasLayoutCategory(optionsPanel, "Roguetastiq")
		Settings.RegisterAddOnCategory(category)
	end
	ns.OptionsPanel = optionsPanel
	ns.OpenSettings = function()
		if category and Settings and Settings.OpenToCategory then
			Settings.OpenToCategory(category.ID or category:GetID())
		else
			optionsPanel:Show()
		end
	end
	createMinimapButton()
end
