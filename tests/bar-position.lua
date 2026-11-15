local ns = {}
assert(loadfile("RoguetastiqPosition.lua"))("Roguetastiq", ns)

local saved = {}
local restored = {}
local frame = {
	GetPoint = function()
		-- StopMovingOrSizing may replace the original CENTER anchor with a
		-- nearby screen anchor. Preserve the actual resulting anchor tuple.
		return "BOTTOMLEFT", nil, "BOTTOMLEFT", 123, 77
	end,
	ClearAllPoints = function(self) self.cleared = true end,
	SetPoint = function(self, point, relativeTo, relativePoint, x, y)
		restored = { point, relativeTo, relativePoint, x, y }
	end,
}

ns.SaveBarPosition(frame, saved)
assert(saved.barPoint == "BOTTOMLEFT", "save the point chosen by the client")
assert(saved.barRelativePoint == "BOTTOMLEFT", "save the relative point")
assert(saved.barX == 123 and saved.barY == 77, "save offsets unchanged")

ns.RestoreBarPosition(frame, "UIParent", saved)
assert(frame.cleared, "clear the client's transient drag anchor")
assert(restored[1] == "BOTTOMLEFT" and restored[2] == "UIParent" and
	restored[3] == "BOTTOMLEFT" and restored[4] == 123 and restored[5] == 77,
	"restore the same anchor and offsets against UIParent")

local legacy = { barX = -180, barY = 80 }
ns.RestoreBarPosition(frame, "UIParent", legacy)
assert(restored[1] == "CENTER" and restored[3] == "CENTER" and
	restored[4] == -180 and restored[5] == 80,
	"restore older saved positions from their center-offset format")

print("bar position persistence checks passed")
