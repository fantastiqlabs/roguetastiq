local ns = {}
local requestedAddon, requestedField

Enum = { WeaponSlot = { MainHand = 16, OffHand = 17 } }
SlashCmdList = {}
GetAddOnMetadata = function(addon, field)
	requestedAddon, requestedField = addon, field
	return "0.0.13"
end
CreateFrame = function()
	return { RegisterEvent = function() end, SetScript = function() end }
end

assert(loadfile("Roguetastiq.lua"))("Roguetastiq", ns)
assert(ns.GetAddonVersion() == "0.0.13", "version comes from addon metadata")
assert(requestedAddon == "Roguetastiq" and requestedField == "Version",
	"version lookup requests the Roguetastiq TOC Version field")
print("addon version checks passed")
