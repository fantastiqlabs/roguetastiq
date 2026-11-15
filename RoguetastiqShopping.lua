local _, ns = ...

function ns.CalculatePurchasePlan(recipe, targetCount, vendorItems, inventory, freeSlots, availableMoney)
	local vendorByItem, rows = {}, {}
	for _, item in ipairs(vendorItems or {}) do
		if item.itemID then vendorByItem[item.itemID] = item end
	end
	local moneyLeft = math.max(0, tonumber(availableMoney) or 0)
	local slotsLeft = math.max(0, math.floor(tonumber(freeSlots) or 0))
	local totalCost = 0
	targetCount = math.max(1, math.floor(tonumber(targetCount) or 1))

	for _, reagent in ipairs(recipe.reagents or {}) do
		local itemID, perCraft = reagent[1], reagent[2]
		local bag = inventory[itemID] or {}
		local vendor = vendorByItem[itemID]
		local required = perCraft * targetCount
		local have = math.max(0, tonumber(bag.count) or 0)
		local requested = math.max(0, required - have)
		local maxStack = math.max(1, math.floor(tonumber(bag.maxStack) or 1))
		local stackRoom = math.max(0, tonumber(bag.stackRoom) or 0)
		local spaceLimit = stackRoom + slotsLeft * maxStack
		local stockLimit = vendor and (vendor.numAvailable == nil or vendor.numAvailable < 0)
			and requested or math.max(0, tonumber(vendor and vendor.numAvailable) or 0)
		local unitPrice = vendor and vendor.stackCount and vendor.stackCount > 0
			and math.ceil((tonumber(vendor.price) or 0) / vendor.stackCount) or math.huge
		local moneyLimit = unitPrice == 0 and requested or math.floor(moneyLeft / unitPrice)
		local buy = requested
		local reasons = {}

		if requested == 0 then
			buy = 0
		elseif not vendor then
			buy = 0
			reasons.notSoldHere = true
		elseif not vendor.isPurchasable then
			buy = 0
			reasons.notPurchasable = true
		elseif vendor.hasExtendedCost or vendor.currencyID then
			buy = 0
			reasons.extendedCost = true
		else
			if stockLimit < requested then reasons.stock = true end
			if moneyLimit < requested then reasons.money = true end
			if spaceLimit < requested then reasons.bagSpace = true end
			buy = math.min(requested, stockLimit, moneyLimit, spaceLimit)
		end

		local rowCost = buy * (unitPrice == math.huge and 0 or unitPrice)
		local slotsUsed = math.ceil(math.max(0, buy - stackRoom) / maxStack)
		slotsLeft = math.max(0, slotsLeft - slotsUsed)
		moneyLeft = math.max(0, moneyLeft - rowCost)
		totalCost = totalCost + rowCost
		rows[#rows + 1] = {
			itemID = itemID,
			required = required,
			have = have,
			requested = requested,
			buy = buy,
			remaining = requested - buy,
			unitPrice = unitPrice == math.huge and nil or unitPrice,
			cost = rowCost,
			vendorIndex = vendor and vendor.index,
			vendorStock = vendor and vendor.numAvailable,
			reasons = reasons,
		}
	end

	return { recipe = recipe, targetCount = targetCount, rows = rows, totalCost = totalCost, remainingMoney = moneyLeft, remainingSlots = slotsLeft }
end

local poisonReagentIDs = { 2928, 2930, 5173, 8923, 8924 }

function ns.IsPoisonVendor(vendorItems)
	local sold = {}
	for _, item in ipairs(vendorItems or {}) do
		if item.itemID and item.isPurchasable and not item.hasExtendedCost and not item.currencyID then
			sold[item.itemID] = true
		end
	end
	for _, itemID in ipairs(poisonReagentIDs) do
		if sold[itemID] then return true end
	end
	return false
end

ns.PoisonReagentIDs = poisonReagentIDs

local popup, popupRecipe, popupSummary, popupStatus, popupQuantity, recipeDropdown, buyButton
local materialRows = {}
local autoAttempted = false
local currentVendorKey
local vendorSession = 0
local feedback = ""

local function merchantIsOpen()
	return MerchantFrame and MerchantFrame:IsShown() and GetMerchantNumItems and C_MerchantFrame
end

local function readMerchantItems()
	local items = {}
	if not merchantIsOpen() then return items end
	for index = 1, GetMerchantNumItems() do
		local info = C_MerchantFrame.GetItemInfo(index)
		local itemID = GetMerchantItemID and GetMerchantItemID(index)
		if info and itemID then
			items[#items + 1] = {
				itemID = itemID,
				index = index,
				price = info.price,
				stackCount = info.stackCount,
				numAvailable = info.numAvailable,
				isPurchasable = info.isPurchasable,
				hasExtendedCost = info.hasExtendedCost,
				currencyID = info.currencyID,
			}
		end
	end
	return items
end

local function readBagState()
	local inventory = {}
	for itemID in pairs(ns.Catalog.materials) do
		inventory[itemID] = {
			count = 0,
			stackRoom = 0,
			maxStack = C_Item.GetItemMaxStackSizeByID(itemID) or 1,
		}
	end
	for bag = 0, NUM_BAG_SLOTS or 4 do
		for slot = 1, C_Container.GetContainerNumSlots(bag) do
			local itemID = C_Container.GetContainerItemID(bag, slot)
			local state = itemID and inventory[itemID]
			if state then
				local info = C_Container.GetContainerItemInfo(bag, slot)
				local count = info and info.stackCount or 1
				state.count = state.count + count
				state.stackRoom = state.stackRoom + math.max(0, state.maxStack - count)
			end
		end
	end
	return inventory
end

local function getSelectedPlan()
	if not merchantIsOpen() then return nil end
	local recipe, vendorItems = ns.FindRecipe(RoguetastiqDB.shoppingRecipeKey), readMerchantItems()
	if not ns.IsPoisonVendor(vendorItems) then return nil end
	local freeSlots = C_Container.CalculateTotalNumberOfFreeBagSlots()
	return ns.CalculatePurchasePlan(recipe, RoguetastiqDB.shoppingCount, vendorItems, readBagState(), freeSlots, GetMoney()), vendorItems
end

local function reasonText(row)
	if row.reasons.notSoldHere then return "not sold here" end
	if row.reasons.notPurchasable then return "not purchasable" end
	if row.reasons.extendedCost then return "non-gold cost" end
	if row.reasons.stock and row.reasons.money then return "stock and funds limit" end
	if row.reasons.stock then return "vendor stock limit" end
	if row.reasons.money and row.reasons.bagSpace then return "funds and bag space limit" end
	if row.reasons.money then return "not enough money" end
	if row.reasons.bagSpace then return "not enough bag space" end
	return nil
end

local function updatePopup()
	if not popup or not popup:IsShown() then return end
	local plan = getSelectedPlan()
	if not plan then
		popup:Hide()
		return
	end
	popupRecipe:SetText(string.format("%d x %s | reagent shopping only", plan.targetCount, plan.recipe.label))
	popupQuantity:SetText(tostring(plan.targetCount))
	recipeDropdown:Refresh()
	local requested, buyable = 0, 0
	for index, rowText in ipairs(materialRows) do
		local row = plan.rows[index]
		if row then
			local itemName = ns.Catalog.materials[row.itemID] or ("Item " .. row.itemID)
			local reason = reasonText(row)
			local stock = row.vendorIndex and (row.vendorStock == nil or row.vendorStock < 0) and "unlimited"
				or (row.vendorIndex and tostring(row.vendorStock) or "n/a")
			rowText:SetText(string.format("%s: need %d | have %d | stock %s | buy %d%s", itemName,
				row.required, row.have, stock, row.buy, reason and (" | " .. reason) or ""))
			rowText:Show()
			requested = requested + row.requested
			buyable = buyable + row.buy
		else
			rowText:Hide()
		end
	end
	local soldCount = 0
	for _, row in ipairs(plan.rows) do if row.vendorIndex then soldCount = soldCount + 1 end end
	popupSummary:SetText(string.format("%d of %d reagent types sold here | estimated reagent cost for this batch: %s",
		soldCount, #plan.rows, GetMoneyString(plan.totalCost)))
	if feedback ~= "" then
		popupStatus:SetText(feedback)
	elseif requested == 0 then
		popupStatus:SetText("You already have the requested materials.")
	elseif buyable < requested then
		popupStatus:SetText("Some materials are unavailable; any purchase will be partial.")
	else
		popupStatus:SetText("Only the missing reagents will be purchased. This does not craft poison.")
	end
	local label = buyable == requested and "Buy required materials" or "Buy available materials"
	buyButton:SetText(label)
	buyButton:SetEnabled(buyable > 0 and plan.totalCost < (MERCHANT_HIGH_PRICE_COST or 1500000))
	if plan.totalCost >= (MERCHANT_HIGH_PRICE_COST or 1500000) then
		popupStatus:SetText("High-value purchase: use Blizzard's merchant controls to confirm each item.")
	end
end

local function requestPurchase(isAutomatic)
	if not merchantIsOpen() or InCombatLockdown() then
		feedback = "Open a vendor out of combat to purchase materials."
		updatePopup()
		return false
	end
	local plan = getSelectedPlan()
	if not plan then return false end
	if plan.totalCost >= (MERCHANT_HIGH_PRICE_COST or 1500000) then
		feedback = "High-value purchase: use Blizzard's merchant controls to confirm each item."
		updatePopup()
		return false
	end
	local before = {}
	for _, row in ipairs(plan.rows) do before[row.itemID] = row.requested end
	local requestedCount = 0
	for _, row in ipairs(plan.rows) do
		if row.buy > 0 and row.vendorIndex then
			local ok, err = pcall(BuyMerchantItem, row.vendorIndex, row.buy)
			if not ok then
				feedback = "The client blocked this purchase request. Use the merchant's own item buttons."
				if isAutomatic then feedback = "Auto-buy was blocked by the client; use the merchant's own item buttons." end
				updatePopup()
				return false, err
			end
			requestedCount = requestedCount + row.buy
		end
	end
	if requestedCount == 0 then
		feedback = "No missing reagents are currently available to buy."
		updatePopup()
		return false
	end
	feedback = string.format("Purchase requested for %d reagent items; checking the updated bags...", requestedCount)
	updatePopup()
	C_Timer.After(0.7, function()
		local updated = getSelectedPlan()
		if not updated then return end
		local acquired, remaining = 0, 0
		for _, row in ipairs(updated.rows) do
			acquired = acquired + math.max(0, (before[row.itemID] or 0) - row.requested)
			remaining = remaining + row.requested
		end
		feedback = string.format("Added %d reagent items to bags; %d still needed.", acquired, remaining)
		updatePopup()
	end)
	return true
end

function ns.InitializeShopping()
	popup = CreateFrame("Frame", "RoguetastiqVendorShopping", UIParent, "BackdropTemplate")
	popup:SetSize(470, 340)
	popup:SetFrameStrata("DIALOG")
	popup:SetClampedToScreen(true)
	popup:EnableMouse(true)
	popup:SetBackdrop({ bgFile = "Interface/Tooltips/UI-Tooltip-Background", edgeFile = "Interface/Tooltips/UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 12, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
	popup:SetBackdropColor(0.035, 0.045, 0.065, 0.98)
	popupRecipe = popup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	popupRecipe:SetPoint("TOPLEFT", popup, "TOPLEFT", 16, -14)
	local recipeLabel = popup:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	recipeLabel:SetPoint("TOPLEFT", popup, "TOPLEFT", 16, -31)
	recipeLabel:SetText("Poison recipe")
	local recipeOptions = {}
	local romanRanks = { "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X" }
	for _, recipe in ipairs(ns.Catalog.recipes) do
		local familyKey, rank = recipe.key:match("^([%a]+)(%d+)$")
		local family = familyKey and ns.Catalog.poisons[familyKey]
		local label = family and romanRanks[tonumber(rank)]
			and (family.label .. " " .. romanRanks[tonumber(rank)]) or recipe.label
		recipeOptions[#recipeOptions + 1] = {
			key = recipe.key,
			label = label,
			buttonLabel = label,
			family = family and family.label or recipe.label,
			rank = tonumber(rank) or 0,
		}
	end
	table.sort(recipeOptions, function(a, b)
		if a.family ~= b.family then return a.family < b.family end
		return a.rank > b.rank
	end)
	recipeDropdown = ns.MakeDropdown(popup, 250, 25, "TOPLEFT", popup, "TOPLEFT", 16, -38,
		recipeOptions,
		function()
			for _, option in ipairs(recipeOptions) do
				if option.key == (RoguetastiqDB.shoppingRecipeKey or "instant6") then return option end
			end
			return recipeOptions[1]
		end,
		function(option)
			RoguetastiqDB.shoppingRecipeKey = option.key
			feedback = ""
			updatePopup()
		end)
	local quantityLabel = popup:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	quantityLabel:SetPoint("TOPLEFT", popup, "TOPLEFT", 286, -31)
	quantityLabel:SetText("Amount to make")
	popupQuantity = popup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	popupQuantity:SetPoint("TOPLEFT", popup, "TOPLEFT", 286, -55)
	local function adjustQuantity(delta)
		RoguetastiqDB.shoppingCount = math.max(1, math.min(200,
			(RoguetastiqDB.shoppingCount or 20) + delta))
		feedback = ""
		updatePopup()
	end
	for index, option in ipairs({
		{ label = "-5", delta = -5 }, { label = "-1", delta = -1 },
		{ label = "+1", delta = 1 }, { label = "+5", delta = 5 },
	}) do
		local delta = option.delta
		local button = CreateFrame("Button", "RoguetastiqVendorQuantity" .. (option.delta < 0 and "Minus" or "Plus") .. math.abs(option.delta), popup, "UIPanelButtonTemplate")
		button:SetSize(34, 23)
		button:SetPoint("TOPLEFT", popup, "TOPLEFT", 316 + (index - 1) * 36, -51)
		button:SetText(option.label)
		button:SetScript("OnClick", function() adjustQuantity(delta) end)
	end
	popupSummary = popup:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	popupSummary:SetPoint("TOPLEFT", popup, "TOPLEFT", 16, -83)
	popup.summary = popupSummary
	popup.recipeDropdown = recipeDropdown
	for index = 1, 4 do
		local row = popup:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		row:SetPoint("TOPLEFT", popup, "TOPLEFT", 16, -105 - (index - 1) * 20)
		row:SetWidth(438)
		row:SetJustifyH("LEFT")
		materialRows[index] = row
	end
	popupStatus = popup:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	popupStatus:SetPoint("BOTTOMLEFT", popup, "BOTTOMLEFT", 16, 48)
	popupStatus:SetWidth(438)
	popupStatus:SetJustifyH("LEFT")
	local closeButton = CreateFrame("Button", nil, popup, "UIPanelCloseButton")
	closeButton:SetPoint("TOPRIGHT", popup, "TOPRIGHT", -2, -2)
	buyButton = CreateFrame("Button", "RoguetastiqVendorBuyButton", popup, "UIPanelButtonTemplate")
	buyButton:SetSize(180, 28)
	buyButton:SetPoint("BOTTOMLEFT", popup, "BOTTOMLEFT", 14, 12)
	buyButton:SetScript("OnClick", function() requestPurchase(false) end)
	local dismissButton = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
	dismissButton:SetSize(100, 28)
	dismissButton:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -14, 12)
	dismissButton:SetText("Close")
	dismissButton:SetScript("OnClick", function() popup:Hide() end)
	popup:Hide()
end

function ns.RefreshVendorShopping()
	if not popup then return end
	if not merchantIsOpen() then popup:Hide(); return end
	if not RoguetastiqDB.vendorPopupEnabled then popup:Hide(); return end
	local vendorItems = readMerchantItems()
	if not ns.IsPoisonVendor(vendorItems) then popup:Hide(); return end
	if not popup:IsShown() then
		popup:ClearAllPoints()
		if MerchantFrame then popup:SetPoint("TOPLEFT", MerchantFrame, "TOPRIGHT", 10, 0)
		else popup:SetPoint("CENTER", UIParent, "CENTER") end
		popup:Show()
	end
	updatePopup()
end

function ns.OnMerchantShow()
	local vendorKey = (UnitGUID and UnitGUID("npc")) or (UnitName and UnitName("npc")) or "unknown"
	vendorKey = vendorKey .. ":" .. tostring(GetMerchantNumItems and GetMerchantNumItems() or 0)
	if currentVendorKey ~= vendorKey then
		currentVendorKey = vendorKey
		vendorSession = vendorSession + 1
		autoAttempted = false
	end
	feedback = ""
	ns.RefreshVendorShopping()
end

function ns.AutoBuyVendorMaterials()
	if autoAttempted then return end
	autoAttempted = true
	local session = vendorSession
	C_Timer.After(0.25, function()
		if session == vendorSession and merchantIsOpen() and RoguetastiqDB and RoguetastiqDB.autoBuyMaterials then
			requestPurchase(true)
		end
	end)
end

function ns.CloseVendorShopping()
	autoAttempted = false
	vendorSession = vendorSession + 1
	currentVendorKey = nil
	feedback = ""
	if popup then popup:Hide() end
end
