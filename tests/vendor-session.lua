local ns = {
	Catalog = { materials = { [2928] = "Dust of Decay" } },
	FindRecipe = function() return { label = "Instant Poison", reagents = { { 2928, 1 } } } end,
}
local purchases, timers, namedFrames, createdFrames = {}, {}, {}, {}
local vendorGUID = "poison-vendor-1"
local shown = true
local methods = {}
function methods:SetSize() end
function methods:SetPoint() end
function methods:SetFrameStrata() end
function methods:SetClampedToScreen() end
function methods:EnableMouse() end
function methods:SetBackdrop() end
function methods:SetBackdropColor() end
function methods:SetWidth() end
function methods:SetJustifyH() end
function methods:SetText(value) self.text = value end
function methods:SetScript(name, callback) self.scripts[name] = callback end
function methods:SetEnabled(value) self.enabled = value end
function methods:ClearAllPoints() end
function methods:Show() self.shown = true end
function methods:Hide() self.shown = false end
function methods:IsShown() return self.shown == true end
function methods:CreateFontString() return setmetatable({ scripts = {} }, { __index = methods }) end

function CreateFrame(_, name)
	local frame = setmetatable({ name = name, scripts = {}, shown = false }, { __index = methods })
	createdFrames[#createdFrames + 1] = frame
	if name then namedFrames[name] = frame end
	return frame
end

MerchantFrame = setmetatable({ shown = true }, { __index = { IsShown = function(self) return self.shown end } })
C_MerchantFrame = { GetItemInfo = function()
	return { price = 50, stackCount = 1, numAvailable = -1, isPurchasable = true, hasExtendedCost = false }
end }
C_Item = { GetItemMaxStackSizeByID = function() return 20 end }
C_Container = {
	GetContainerNumSlots = function() return 0 end,
	GetContainerItemID = function() return nil end,
	GetContainerItemInfo = function() return nil end,
	CalculateTotalNumberOfFreeBagSlots = function() return 1 end,
}
NUM_BAG_SLOTS = 4
GetMerchantNumItems = function() return 1 end
GetMerchantItemID = function() return 2928 end
GetMoney = function() return 5000 end
GetMoneyString = function(value) return tostring(value) end
GetMerchantItemMaxStack = function() return 20 end
UnitGUID = function() return vendorGUID end
UnitName = function() return "Poison Vendor" end
InCombatLockdown = function() return false end
MERCHANT_HIGH_PRICE_COST = 1500000
BuyMerchantItem = function(index, quantity) purchases[#purchases + 1] = { index, quantity } end
C_Timer = { After = function(_, callback) timers[#timers + 1] = callback end }

assert(loadfile("RoguetastiqShopping.lua"))("Roguetastiq", ns)
RoguetastiqDB = { shoppingRecipeKey = "instant1", shoppingCount = 20, autoBuyMaterials = false, vendorPopupEnabled = true }
ns.InitializeShopping()
ns.OnMerchantShow()
assert(namedFrames.RoguetastiqVendorShopping:IsShown(), "supported vendor opens the shopping popup")
createdFrames[3].scripts.OnClick()
assert(#purchases == 1 and purchases[1][1] == 1 and purchases[1][2] == 20,
	"a deliberate popup click requests the exact missing reagent quantity")
for index = #purchases, 1, -1 do table.remove(purchases, index) end
if RoguetastiqDB.autoBuyMaterials then ns.AutoBuyVendorMaterials() end
while #timers > 0 do table.remove(timers, 1)() end
assert(#purchases == 0, "the auto-buy preference defaults off")

RoguetastiqDB.autoBuyMaterials = true
ns.CloseVendorShopping()
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
