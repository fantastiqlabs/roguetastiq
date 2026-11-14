local _, ns = ...

function ns.FoodMacroUseLine(source, actionButton, itemName)
	if source == "actionbar" then
		local slot = math.floor(tonumber(actionButton) or 0)
		if slot >= 1 and slot <= 12 then
			return string.format("/click [stealth] ActionButton%d", slot)
		end
	end
	local name = (itemName or ""):match("^%s*(.-)%s*$")
	if name == "" then name = "Food Name" end
	return "/use [stealth] " .. name
end
