local recipes = {
	{ key = "instant1", label = "Instant Poison", reagents = { { 2928, 1 } } },
	{ key = "instant2", label = "Instant Poison II", reagents = { { 2928, 3 }, { 3372, 1 } } },
	{ key = "instant6", label = "Instant Poison VI", reagents = { { 2928, 4 } } },
}
local ns = {
	Catalog = {
		materials = { [2928] = "Dust of Decay", [3372] = "Leaded Vial" },
		poisons = { instant = { label = "Instant Poison" } },
		recipes = recipes,
	},
	FindRecipe = function(key)
		for _, recipe in ipairs(recipes) do if recipe.key == key then return recipe end end
		return recipes[1]
	end,
}
local purchases, timers, namedFrames = {}, {}, {}
local bags = {}
local fillBags = false
local vendorGUID = "poison-vendor-1"
local vendorName = "Rekkul"
local vendorItemID = 2928
local methods = {}
function methods:SetSize() end
function methods:LockHighlight() self.selected = true end
function methods:UnlockHighlight() self.selected = false end
function methods:SetPoint() end
function methods:SetFrameStrata() end
function methods:SetClampedToScreen() end
function methods:EnableMouse() end
function methods:SetBackdrop() end
function methods:SetBackdropColor() end
function methods:SetWidth() end
function methods:SetJustifyH() end
function methods:SetText(value) self.text = value end
function methods:GetText() return self.text end
function methods:SetScript(name, callback) self.scripts[name] = callback end
function methods:SetEnabled(value) self.enabled = value end
function methods:ClearAllPoints() end
function methods:Show() self.shown = true end
function methods:Hide() self.shown = false end
function methods:IsShown() return self.shown == true end
function methods:CreateFontString() return setmetatable({ scripts = {} }, { __index = methods }) end

function CreateFrame(_, name)
	local frame = setmetatable({ name = name, scripts = {}, shown = false }, { __index = methods })
	if name then namedFrames[name] = frame end
	return frame
end

MerchantFrame = setmetatable({ shown = true }, { __index = { IsShown = function(self) return self.shown end } })
C_MerchantFrame = { GetItemInfo = function()
	return { price = 50, stackCount = 1, numAvailable = -1, isPurchasable = true, hasExtendedCost = false }
end }
C_Item = { GetItemMaxStackSizeByID = function() return 20 end }
C_Container = {
	GetContainerNumSlots = function(bag) return bag == 0 and #bags or 0 end,
	GetContainerItemID = function(_, slot) return bags[slot].itemID end,
	GetContainerItemInfo = function(_, slot) return bags[slot] end,
	CalculateTotalNumberOfFreeBagSlots = function() return 10 end,
}
NUM_BAG_SLOTS = 4
GetMerchantNumItems = function() return 2 end
GetMerchantItemID = function(index) return index == 1 and vendorItemID or 3372 end
GetMoney = function() return 5000 end
GetMoneyString = function(value) return tostring(value) end
GetMerchantItemMaxStack = function() return 20 end
UnitGUID = function() return vendorGUID end
UnitName = function() return vendorName end
InCombatLockdown = function() return false end
MERCHANT_HIGH_PRICE_COST = 1500000
BuyMerchantItem = function(index, quantity)
	if quantity <= GetMerchantItemMaxStack(index) then
		purchases[#purchases + 1] = { index, quantity }
		if fillBags then bags[#bags + 1] = { itemID = GetMerchantItemID(index), stackCount = quantity } end
	end
end
C_Timer = { After = function(_, callback) timers[#timers + 1] = callback end }

assert(loadfile("RoguetastiqLocations.lua"))("Roguetastiq", ns)
assert(loadfile("RoguetastiqShopping.lua"))("Roguetastiq", ns)
RoguetastiqDB = { shoppingRecipeKey = "instant1", shoppingCount = 20, autoBuyMaterials = false, vendorPopupEnabled = true }
ns.InitializeShopping()
ns.OnMerchantShow()
assert(namedFrames.RoguetastiqVendorShopping:IsShown(), "supported vendor opens the shopping popup")
namedFrames.RoguetastiqVendorBuyButton.scripts.OnClick()
assert(#purchases == 1 and purchases[1][1] == 1 and purchases[1][2] == 20,
	"a deliberate popup click requests the exact missing reagent quantity")
for index = #purchases, 1, -1 do table.remove(purchases, index) end
local popup = namedFrames.RoguetastiqVendorShopping
assert(popup.recipeButtons.instant6:GetText() == "Instant Poison VI",
	"the highest rank is visible as a direct recipe button")
namedFrames.RoguetastiqVendorBuyButton.scripts.OnClick()
assert(#purchases == 0, "duplicate purchases wait for the bag check")
while #timers > 0 do table.remove(timers, 1)() end
popup.recipeButtons.instant2.scripts.OnClick()
assert(popup.recipeButtons.instant2.selected, "the active recipe is highlighted")
namedFrames.RoguetastiqVendorQuantityPlus5.scripts.OnClick()
assert(RoguetastiqDB.shoppingRecipeKey == "instant2" and RoguetastiqDB.shoppingCount == 25,
	"the popup selection and quantity controls update the saved shopping plan")
assert(popup.summary:GetText():find("estimated reagent cost for this batch: 5000", 1, true),
	"the displayed cost recalculates for the selected recipe and batch size")
fillBags = true
namedFrames.RoguetastiqVendorBuyButton.scripts.OnClick()
local bought = { 0, 0 }
for _, purchase in ipairs(purchases) do
	bought[purchase[1]] = bought[purchase[1]] + purchase[2]
end
assert(bought[1] == 75 and bought[2] == 25,
	"a popup purchase requests every reagent across merchant stack limits")
for index = #purchases, 1, -1 do table.remove(purchases, index) end
while #timers > 0 do table.remove(timers, 1)() end
assert(popup.status:GetText():find("Added 100 reagent items to bags; 0 still needed.", 1, true),
	"the completed purchase is confirmed against bag counts")
bags, fillBags = {}, false
RoguetastiqDB.shoppingRecipeKey, RoguetastiqDB.shoppingCount = "instant1", 20
if RoguetastiqDB.autoBuyMaterials then ns.AutoBuyVendorMaterials() end
while #timers > 0 do table.remove(timers, 1)() end
assert(#purchases == 0, "the auto-buy preference defaults off")

ns.CloseVendorShopping()
vendorGUID = "ordinary-vendor"
vendorName = "Trade Supplies Vendor"
vendorItemID = 2928
RoguetastiqDB.autoBuyMaterials = true
ns.OnMerchantShow()
assert(not namedFrames.RoguetastiqVendorShopping:IsShown(), "ordinary vendors do not show poison shopping even with a shared reagent")
ns.AutoBuyVendorMaterials()
while #timers > 0 do table.remove(timers, 1)() end
assert(#purchases == 0, "ordinary vendors never auto-buy poison reagents")

RoguetastiqDB.autoBuyMaterials = true
ns.CloseVendorShopping()
vendorGUID = "shady-dealer"
vendorName = "Jasper Fel"
vendorItemID = 2928
ns.OnMerchantShow()
ns.AutoBuyVendorMaterials()
ns.AutoBuyVendorMaterials()
while #timers > 0 do table.remove(timers, 1)() end
assert(#purchases == 1 and purchases[1][1] == 1 and purchases[1][2] == 20,
	"opt-in auto-buy requests the exact missing reagent quantity once per vendor session")

ns.AutoBuyVendorMaterials()
while #timers > 0 do table.remove(timers, 1)() end
assert(#purchases == 1, "duplicate merchant events do not repeat the same session purchase")

MERCHANT_HIGH_PRICE_COST = 500
ns.CloseVendorShopping()
ns.OnMerchantShow()
ns.AutoBuyVendorMaterials()
while #timers > 0 do table.remove(timers, 1)() end
assert(#purchases == 1, "high-value requests leave Blizzard's confirmation flow to the vendor UI")
MERCHANT_HIGH_PRICE_COST = 1500000

BuyMerchantItem = function() error("protected purchase") end
ns.CloseVendorShopping()
vendorGUID = "protected-vendor-2"
ns.OnMerchantShow()
ns.AutoBuyVendorMaterials()
while #timers > 0 do table.remove(timers, 1)() end
assert(#purchases == 1, "a client-blocked purchase fails closed without an unhandled error")

RoguetastiqDB.vendorPopupEnabled = false
ns.CloseVendorShopping()
ns.OnMerchantShow()
assert(not namedFrames.RoguetastiqVendorShopping:IsShown(), "the popup visibility option is respected")

print("vendor-session checks passed")
