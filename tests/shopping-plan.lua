local ns = {}
assert(loadfile("RoguetastiqShopping.lua"))("Roguetastiq", ns)

local recipe = {
	label = "Instant Poison II",
	reagents = { { 2928, 3 }, { 3372, 1 } },
}
local vendor = {
	{ itemID = 2928, index = 3, price = 50, stackCount = 1, numAvailable = -1, isPurchasable = true },
	{ itemID = 3372, index = 7, price = 20, stackCount = 1, numAvailable = -1, isPurchasable = true },
}

local plan = ns.CalculatePurchasePlan(recipe, 20, vendor, {
	[2928] = { count = 5, stackRoom = 5, maxStack = 20 },
	[3372] = { count = 4, stackRoom = 16, maxStack = 20 },
	}, 3, 10000)
assert(plan.rows[1].requested == 55 and plan.rows[1].buy == 55)
assert(plan.rows[2].requested == 16 and plan.rows[2].buy == 16)
assert(plan.totalCost == 3070)

local stackedPrice = ns.CalculatePurchasePlan({ label = "Dust", reagents = { { 2928, 1 } } }, 10, {
	{ itemID = 2928, index = 3, price = 100, stackCount = 5, numAvailable = -1, isPurchasable = true },
}, { [2928] = { maxStack = 20 } }, 1, 200)
assert(stackedPrice.rows[1].buy == 10 and stackedPrice.totalCost == 200,
	"merchant price is normalized from the vendor's displayed stack price")

local stocked = ns.CalculatePurchasePlan(recipe, 20, {
	{ itemID = 2928, index = 3, price = 50, stackCount = 1, numAvailable = 10, isPurchasable = true },
	}, { [2928] = { maxStack = 20 }, [3372] = { maxStack = 20 } }, 4, 10000)
assert(stocked.rows[1].buy == 10 and stocked.rows[1].vendorStock == 10 and stocked.rows[1].reasons.stock)
assert(stocked.rows[2].buy == 0 and stocked.rows[2].reasons.notSoldHere)

local limited = ns.CalculatePurchasePlan(recipe, 20, vendor, {
	[2928] = { maxStack = 20 }, [3372] = { maxStack = 20 },
}, 1, 100)
assert(limited.rows[1].buy == 2 and limited.rows[1].reasons.money)
assert(limited.rows[2].buy == 0 and limited.rows[2].reasons.money and limited.rows[2].reasons.bagSpace)

local extended = ns.CalculatePurchasePlan(recipe, 1, {
	{ itemID = 2928, index = 3, price = 50, stackCount = 1, numAvailable = -1, isPurchasable = true, hasExtendedCost = true },
}, {}, 4, 10000)
assert(extended.rows[1].buy == 0 and extended.rows[1].reasons.extendedCost)
assert(not ns.IsPoisonVendor({
	{ itemID = 3371, index = 1, isPurchasable = true },
}), "vial-only general vendors do not open the poison popup")
assert(ns.IsPoisonVendor(vendor), "vendors selling poison reagents are recognized")

print("shopping-plan checks passed")
