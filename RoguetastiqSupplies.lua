local _, ns = ...

local FADELEAF_ITEM_ID = 3818
local FLASH_POWDER_ITEM_ID = 5140
local lowPowderWarningShown = false

local function notify(message)
	if UIErrorsFrame and UIErrorsFrame.AddMessage then
		UIErrorsFrame:AddMessage(message, 0.95, 0.78, 0.32, 1, 5)
	elseif DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
		DEFAULT_CHAT_FRAME:AddMessage(message)
	end
end

function ns.ShouldShowFadeleafReminder(count, threshold, enabled)
	return enabled == true and (tonumber(count) or 0) <= math.max(0, tonumber(threshold) or 0)
end

function ns.ShouldWarnFlashPowder(count, threshold, enabled)
	return enabled == true and (tonumber(count) or 0) <= math.max(0, tonumber(threshold) or 0)
end

function ns.CheckFadeleafReminder(location)
	if not RoguetastiqDB or not ns.CountItemInBags then return false end
	local count = ns.CountItemInBags(FADELEAF_ITEM_ID)
	if not ns.ShouldShowFadeleafReminder(count, RoguetastiqDB.fadeleafThreshold, RoguetastiqDB.fadeleafReminder) then
		return false
	end
	local place = location == "auction" and "Auction House" or "vendor"
	notify(string.format("Roguetastiq: %d Fadeleaf in bags. Remember to restock at the %s.", count, place))
	return true
end

function ns.CheckFlashPowderReminder()
	if not RoguetastiqDB or not ns.CountItemInBags then return false end
	local count = ns.CountItemInBags(FLASH_POWDER_ITEM_ID)
	local low = ns.ShouldWarnFlashPowder(count, RoguetastiqDB.flashPowderThreshold, RoguetastiqDB.flashPowderWarning)
	if not low then
		lowPowderWarningShown = false
		return false
	end
	if lowPowderWarningShown then return false end
	lowPowderWarningShown = true
	notify(string.format("Roguetastiq: low Flash Powder (%d in bags; reminder at %d or fewer).",
		count, math.max(0, tonumber(RoguetastiqDB.flashPowderThreshold) or 0)))
	return true
end

ns.SupplyItemIDs = { fadeleaf = FADELEAF_ITEM_ID, flashPowder = FLASH_POWDER_ITEM_ID }
