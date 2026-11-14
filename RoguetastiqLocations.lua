local _, ns = ...

local categories = {
	{ key = "shadyDealer", label = "Shady dealer", icon = "Interface/Icons/INV_Misc_Coin_01", r = 0.9, g = 0.7, b = 0.2 },
	{ key = "poisonVendor", label = "Poison reagent vendor", icon = "Interface/Icons/INV_Potion_32", r = 0.45, g = 0.9, b = 0.55 },
	{ key = "rogueTrainer", label = "Rogue trainer", icon = "Interface/Icons/Ability_Backstab", r = 0.55, g = 0.7, b = 1 },
}

ns.MapCategories = categories
ns.MapCategoryByKey = {}
for _, category in ipairs(categories) do ns.MapCategoryByKey[category.key] = category end

-- Coordinates are the normalized map positions published as "Seen in Forever"
-- by ForeverDB. Map IDs follow the Forever Blizzard UI map catalog.
ns.MapLocations = {
	{ name = "Kyrai", title = "Poison Vendor", zone = "Darnassus", mapID = 1457, x = 0.329, y = 0.196, faction = "Alliance", services = { poisonVendor = true } },
	{ name = "Jaysin Lanyda", title = "Poisons & Reagents", zone = "Hillsbrad Foothills", mapID = 1424, x = 0.509, y = 0.590, faction = "Alliance", services = { poisonVendor = true } },
	{ name = "Tynnus Venomsprout", title = "Shady Dealer", zone = "Ironforge", mapID = 1455, x = 0.526, y = 0.136, faction = "Alliance", services = { shadyDealer = true, poisonVendor = true } },
	{ name = "Gerald Crawley", title = "Poison Supplier", zone = "Redridge Mountains", mapID = 1433, x = 0.199, y = 0.413, faction = "Alliance", services = { poisonVendor = true } },
	{ name = "Jasper Fel", title = "Shady Dealer", zone = "Stormwind City", mapID = 1453, x = 0.802, y = 0.701, faction = "Alliance", services = { shadyDealer = true, poisonVendor = true } },
	{ name = "Sloan McCoy", title = "Poison Supplier", zone = "Stormwind City", mapID = 1453, x = 0.787, y = 0.708, faction = "Alliance", services = { poisonVendor = true } },
	{ name = "Samor Festivus", title = "Shady Dealer", zone = "Wetlands", mapID = 1437, x = 0.105, y = 0.603, faction = "Alliance", services = { shadyDealer = true, poisonVendor = true } },
	{ name = "Sly Garrett", title = "Shady Goods", zone = "Stranglethorn Vale", mapID = 1434, x = 0.284, y = 0.768, faction = "Alliance", services = { shadyDealer = true, poisonVendor = true } },
	{ name = "Rekkul", title = "Poison Vendor", zone = "Orgrimmar", mapID = 1454, x = 0.422, y = 0.496, faction = "Horde", services = { poisonVendor = true } },
	{ name = "Patrice Dwyer", title = "Poison Supplies", zone = "Silverpine Forest", mapID = 1421, x = 0.430, y = 0.418, faction = "Horde", services = { poisonVendor = true } },
	{ name = "Ezekiel Graves", title = "Poison Vendor", zone = "Undercity", mapID = 1458, x = 0.755, y = 0.516, faction = "Horde", services = { poisonVendor = true } },
	{ name = "Hogral Bakkan", title = "Rogue Trainer", zone = "Dun Morogh", mapID = 1426, x = 0.476, y = 0.526, faction = "Alliance", services = { rogueTrainer = true } },
	{ name = "Jannok Breezesong", title = "Rogue Trainer", zone = "Teldrassil", mapID = 1438, x = 0.563, y = 0.601, faction = "Alliance", services = { rogueTrainer = true } },
	{ name = "Keryn Sylvius", title = "Rogue Trainer", zone = "Elwynn Forest", mapID = 1429, x = 0.438, y = 0.659, faction = "Alliance", services = { rogueTrainer = true } },
	{ name = "Boarton Shadetotem", title = "Rogue Trainer", zone = "Thunder Bluff", mapID = 1456, x = 0.395, y = 0.658, faction = "Horde", services = { rogueTrainer = true } },
	{ name = "Miles Dexter", title = "Rogue Trainer", zone = "Undercity", mapID = 1458, x = 0.851, y = 0.712, faction = "Horde", services = { rogueTrainer = true } },
	{ name = "Ormok", title = "Rogue Trainer", zone = "Orgrimmar", mapID = 1454, x = 0.439, y = 0.542, faction = "Horde", services = { rogueTrainer = true } },
	{ name = "Shenthul", title = "Rogue Trainer", zone = "Orgrimmar", mapID = 1454, x = 0.431, y = 0.536, faction = "Horde", services = { rogueTrainer = true } },
}

function ns.ShouldShowMapLocation(location, settings, faction)
	if location.faction and faction and location.faction ~= faction then return false end
	for _, category in ipairs(categories) do
		if location.services[category.key] and settings["mapShow" .. category.key:sub(1, 1):upper() .. category.key:sub(2)] ~= false then
			return true
		end
	end
	return false
end

function ns.MinimapOffset(dx, dy, radius, diameter, rotate, facing)
	if not radius or radius <= 0 or not diameter or diameter <= 0 then return nil end
	if rotate then
		local cosine, sine = math.cos(facing or 0), math.sin(facing or 0)
		dx, dy = dx * cosine - dy * sine, dx * sine + dy * cosine
	end
	local distance = math.sqrt(dx * dx + dy * dy)
	if distance > radius then return nil end
	local scale = diameter / (2 * radius)
	return dx * scale, dy * scale
end
