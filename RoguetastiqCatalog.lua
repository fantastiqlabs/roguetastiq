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

catalog.materials = {
	[2928] = "Dust of Decay",
	[2930] = "Essence of Pain",
	[3371] = "Empty Vial",
	[3372] = "Leaded Vial",
	[5173] = "Deathweed",
	[8923] = "Essence of Agony",
	[8924] = "Dust of Deterioration",
	[8925] = "Crystal Vial",
}

catalog.recipes = {
	{ key = "crippling1", label = "Crippling Poison", itemID = 3775, reagents = { { 2930, 1 }, { 3371, 1 } } },
	{ key = "instant1", label = "Instant Poison", itemID = 6947, reagents = { { 2928, 1 }, { 3371, 1 } } },
	{ key = "mindnumbing1", label = "Mind-numbing Poison", itemID = 5237, reagents = { { 2928, 1 }, { 2930, 1 }, { 3371, 1 } } },
	{ key = "instant2", label = "Instant Poison II", itemID = 6949, reagents = { { 2928, 3 }, { 3372, 1 } } },
	{ key = "deadly1", label = "Deadly Poison", itemID = 2892, reagents = { { 5173, 1 }, { 3372, 1 } } },
	{ key = "wound1", label = "Wound Poison", itemID = 10918, reagents = { { 2930, 1 }, { 5173, 1 }, { 3372, 1 } } },
	{ key = "instant3", label = "Instant Poison III", itemID = 6950, reagents = { { 8924, 1 }, { 3372, 1 } } },
	{ key = "deadly2", label = "Deadly Poison II", itemID = 2893, reagents = { { 5173, 2 }, { 3372, 1 } } },
	{ key = "mindnumbing2", label = "Mind-numbing Poison II", itemID = 6951, reagents = { { 2928, 4 }, { 2930, 4 }, { 3372, 1 } } },
	{ key = "wound2", label = "Wound Poison II", itemID = 10920, reagents = { { 2930, 1 }, { 5173, 2 }, { 3372, 1 } } },
	{ key = "instant4", label = "Instant Poison IV", itemID = 8926, reagents = { { 8924, 2 }, { 8925, 1 } } },
	{ key = "deadly3", label = "Deadly Poison III", itemID = 8984, reagents = { { 5173, 3 }, { 8925, 1 } } },
	{ key = "wound3", label = "Wound Poison III", itemID = 10921, reagents = { { 8923, 1 }, { 5173, 2 }, { 8925, 1 } } },
	{ key = "crippling2", label = "Crippling Poison II", itemID = 3776, reagents = { { 8923, 3 }, { 8925, 1 } } },
	{ key = "instant5", label = "Instant Poison V", itemID = 8927, reagents = { { 8924, 3 }, { 8925, 1 } } },
	{ key = "mindnumbing3", label = "Mind-numbing Poison III", itemID = 9186, reagents = { { 8924, 2 }, { 8923, 2 }, { 8925, 1 } } },
	{ key = "deadly4", label = "Deadly Poison IV", itemID = 8985, reagents = { { 5173, 5 }, { 8925, 1 } } },
	{ key = "wound4", label = "Wound Poison IV", itemID = 10922, reagents = { { 8923, 2 }, { 5173, 2 }, { 8925, 1 } } },
	{ key = "instant6", label = "Instant Poison VI", itemID = 8928, reagents = { { 8924, 4 }, { 8925, 1 } } },
}
table.sort(catalog.recipes, function(a, b) return a.label < b.label end)

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
catalog.optionsByKey = {}
for key, value in pairs(catalog.poisons) do
	local option = { kind = "poison", key = key, label = value.label .. " - highest in bags", buttonLabel = value.label }
	catalog.options[#catalog.options + 1] = option
	catalog.optionsByKey["poison:" .. key] = option
end
for key, value in pairs(catalog.stones) do
	local option = { kind = "stone", key = key, label = value.label, buttonLabel = value.label }
	catalog.options[#catalog.options + 1] = option
	catalog.optionsByKey["stone:" .. key] = option
end
table.sort(catalog.options, function(a, b) return a.label < b.label end)

function ns.CoatingChoiceLabel(choice)
	if not choice then return "Unconfigured" end
	local group = catalog[choice.kind .. "s"]
	local item = group and group[choice.key]
	return item and (choice.kind == "poison" and (item.label .. " - highest in bags") or item.label) or "Unconfigured"
end

function ns.FindRecipe(key)
	for _, recipe in ipairs(catalog.recipes) do
		if recipe.key == key then return recipe end
	end
	return catalog.recipes[1]
end

function ns.BuildShoppingList(recipeKey, count)
	local recipe = ns.FindRecipe(recipeKey)
	local shoppingList = {}
	count = math.max(1, math.floor(tonumber(count) or 1))
	for _, reagent in ipairs(recipe.reagents) do
		local itemID, perCraft = reagent[1], reagent[2]
		local needed = perCraft * count
		local have = ns.CountItemInBags(itemID)
		shoppingList[#shoppingList + 1] = {
			itemID = itemID,
			name = catalog.materials[itemID],
			required = needed,
			have = have,
			buy = math.max(0, needed - have),
		}
	end
	return recipe, shoppingList
end

ns.Catalog = catalog
