local _, ns = ...

local catalog = {
	poisons = {
		instant = { label = "Instant Poison", ranks = { 6947, 6949, 6950, 8926, 8927, 8928 } },
		deadly = { label = "Deadly Poison", ranks = { 2892, 2893, 8984, 8985 } },
		wound = { label = "Wound Poison", ranks = { 10918, 10920, 10921, 10922 } },
		crippling = { label = "Crippling Poison", ranks = { 3775, 3776 } },
		mindnumbing = { label = "Mind-numbing Poison", ranks = { 5237, 6951, 9186 } },
	},
	stones = {
		rough = { label = "Rough Sharpening Stone", itemID = 2862 },
		coarse = { label = "Coarse Sharpening Stone", itemID = 2863 },
		heavy = { label = "Heavy Sharpening Stone", itemID = 2871 },
		solid = { label = "Solid Sharpening Stone", itemID = 7964 },
		dense = { label = "Dense Sharpening Stone", itemID = 12404 },
		elemental = { label = "Elemental Sharpening Stone", itemID = 18262 },
	},
}

local bags = {}
for bag = 0, NUM_BAG_SLOTS or 4 do
	bags[#bags + 1] = bag
end

function ns.CountItemInBags(itemID)
	local count = 0
	for _, bag in ipairs(bags) do
		for slot = 1, C_Container.GetContainerNumSlots(bag) do
			if C_Container.GetContainerItemID(bag, slot) == itemID then
				local info = C_Container.GetContainerItemInfo(bag, slot)
				count = count + (info and info.stackCount or 1)
			end
		end
	end
	return count
end

function ns.FindCoatingItem(kind, key)
	if not kind or not key then return nil end
	if kind == "poison" then
		local family = catalog.poisons[key]
		if not family then return nil end
		for index = #family.ranks, 1, -1 do
			local itemID = family.ranks[index]
			if ns.CountItemInBags(itemID) > 0 then return itemID end
		end
	elseif kind == "stone" then
		local stone = catalog.stones[key]
		if stone and ns.CountItemInBags(stone.itemID) > 0 then return stone.itemID end
	end
	return nil
end

function ns.GetChoiceIcon(choice)
	if not choice then return nil end
	local itemID = ns.FindCoatingItem(choice.kind, choice.key)
	if not itemID then
		local group = catalog[choice.kind .. "s"]
		local item = group and group[choice.key]
		if item then
			itemID = choice.kind == "poison" and item.ranks[#item.ranks] or item.itemID
		end
	end
	return itemID and C_Item.GetItemIconByID(itemID)
end

catalog.options = {}
for key, value in pairs(catalog.poisons) do
	catalog.options[#catalog.options + 1] = { kind = "poison", key = key, label = value.label .. " · highest in bags" }
end
for key, value in pairs(catalog.stones) do
	catalog.options[#catalog.options + 1] = { kind = "stone", key = key, label = value.label }
end
table.sort(catalog.options, function(a, b) return a.label < b.label end)

function ns.CoatingChoiceLabel(choice)
	if not choice then return "Unconfigured" end
	local group = catalog[choice.kind .. "s"]
	local item = group and group[choice.key]
	return item and (choice.kind == "poison" and (item.label .. " · highest in bags") or item.label) or "Unconfigured"
end

ns.Catalog = catalog
