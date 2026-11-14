local ns = {}
local root = (...)
loadfile(root .. "/RoguetastiqLocations.lua")("Roguetastiq", ns)

local function equal(actual, expected, message)
	assert(actual == expected, string.format("%s: expected %s, got %s", message, tostring(expected), tostring(actual)))
end

local function truthy(value, message)
	assert(value, message)
end

equal(#ns.MapLocations, 18, "Forever-seen NPC catalog size")
for _, location in ipairs(ns.MapLocations) do
	truthy(location.mapID > 0, location.name .. " has a map ID")
	truthy(location.x >= 0 and location.x <= 1, location.name .. " has normalized X")
	truthy(location.y >= 0 and location.y <= 1, location.name .. " has normalized Y")
end

local defaults = {
	mapShowShadyDealer = true,
	mapShowPoisonVendor = true,
	mapShowRogueTrainer = true,
}
local trainer
local tynnus
for _, location in ipairs(ns.MapLocations) do
	if location.name == "Hogral Bakkan" then trainer = location end
	if location.name == "Tynnus Venomsprout" then tynnus = location end
end
truthy(trainer and ns.ShouldShowMapLocation(trainer, defaults, "Alliance"), "Alliance Rogue trainer is visible")
equal(ns.ShouldShowMapLocation(trainer, defaults, "Horde"), false, "opposite-faction Rogue trainer is hidden")
truthy(ns.ShouldShowMapLocation(tynnus, defaults, "Alliance"), "Shady Dealer that sells reagents is visible")
defaults.mapShowShadyDealer = false
truthy(ns.ShouldShowMapLocation(tynnus, defaults, "Alliance"), "poison vendor remains visible when Shady Dealers are hidden")
defaults.mapShowPoisonVendor = false
equal(ns.ShouldShowMapLocation(tynnus, defaults, "Alliance"), false, "disabled services hide the NPC")

local mockedMixins = { MapCanvasPinMixin = {}, MapCanvasDataProviderMixin = {} }
_G.MapCanvasPinMixin = mockedMixins.MapCanvasPinMixin
_G.MapCanvasDataProviderMixin = mockedMixins.MapCanvasDataProviderMixin
_G.CreateFromMixins = function() return {} end
loadfile(root .. "/RoguetastiqMaps.lua")("Roguetastiq", ns)
local clusters = ns.ClusterMapLocations({
	{ mapID = 1454, x = 0.431, y = 0.536, name = "Shenthul" },
	{ mapID = 1454, x = 0.439, y = 0.542, name = "Ormok" },
	{ mapID = 1453, x = 0.802, y = 0.701, name = "Jasper Fel" },
})
equal(#clusters, 2, "nearby map pins are grouped")
equal(#clusters[1].locations, 2, "group keeps every NPC for its tooltip")

local x, y = ns.MinimapOffset(0, 100, 200, 100, false, 0)
equal(x, 0, "north-up X projection")
equal(y, 25, "north-up Y projection")
local rotatedX, rotatedY = ns.MinimapOffset(0, 100, 200, 100, true, math.pi / 2)
truthy(math.abs(rotatedX + 25) < 0.001, "rotated north projects left when facing east")
truthy(math.abs(rotatedY) < 0.001, "rotated north has no vertical offset when facing east")
local outsideX = ns.MinimapOffset(0, 201, 200, 100, false, 0)
equal(outsideX, nil, "locations outside minimap view are hidden")

print("map-marker checks passed")
