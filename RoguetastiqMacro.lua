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

local function actionButtonClickLine(source, actionButton, condition)
	if source == "actionbar" then
		local slot = math.floor(tonumber(actionButton) or 0)
		if slot >= 1 and slot <= 12 then
			return string.format("/click %sActionButton%d", condition and ("[" .. condition .. "] ") or "", slot)
		end
	end
	return nil
end

local function equippedWeaponLine(source, actionButton, itemName, condition)
	local clickLine = actionButtonClickLine(source, actionButton, condition)
	if clickLine then return clickLine end
	local name = (itemName or ""):match("^%s*(.-)%s*$")
	if name == "" then name = "Weapon Name" end
	local prefix = condition and ("[" .. condition .. "] ") or ""
	return string.format("/equipslot %s16 %s", prefix, name)
end

function ns.WeaponSwapMacroLines(daggerSource, daggerButton, daggerName, mainhandSource, mainhandButton, mainhandName)
	return table.concat({
		equippedWeaponLine(daggerSource, daggerButton, daggerName, "stealth"),
		equippedWeaponLine(mainhandSource, mainhandButton, mainhandName, "nostealth"),
	}, "\n")
end

function ns.DaggerMacroUseLine(source, actionButton, itemName)
	return actionButtonClickLine(source, actionButton) or equippedWeaponLine("item", nil, itemName)
end
