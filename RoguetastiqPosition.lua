local _, ns = ...

function ns.SaveBarPosition(frame, db)
	-- StopMovingOrSizing may replace the drag anchor with a nearer screen edge.
	local point, _, relativePoint, x, y = frame:GetPoint(1)
	if not point or not x or not y then return false end
	db.barPoint = point
	db.barRelativePoint = relativePoint or point
	db.barX, db.barY = x, y
	return true
end

function ns.RestoreBarPosition(frame, parent, db)
	local point = db.barPoint or "CENTER"
	frame:ClearAllPoints()
	frame:SetPoint(point, parent, db.barRelativePoint or point,
		db.barX or 0, db.barY or -140)
end
