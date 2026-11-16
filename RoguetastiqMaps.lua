local _, ns = ...

local pinTemplate = "RoguetastiqMapPinTemplate"
local minimapPins = {}
local mapProvider
local ticker

local function locationCategory(location)
	for _, category in ipairs(ns.MapCategories) do
		if location.services[category.key] then return category end
	end
	return ns.MapCategories[1]
end

local function getWorldPosition(location)
	if location.worldPosition ~= nil then return location.continentID, location.worldPosition end
	if not C_Map or not C_Map.GetWorldPosFromMapPos or not CreateVector2D then return nil end
	local ok, continentID, position = pcall(C_Map.GetWorldPosFromMapPos, location.mapID,
		CreateVector2D(location.x, location.y))
	if not ok or not continentID or not position then return nil end
	location.continentID, location.worldPosition = continentID, position
	return continentID, position
end

local function selectedLocations()
	local result = {}
	local faction = UnitFactionGroup and UnitFactionGroup("player")
	for _, location in ipairs(ns.MapLocations) do
		if ns.ShouldShowMapLocation(location, RoguetastiqDB, faction) then
			result[#result + 1] = location
		end
	end
	return result
end

local function clusterLocations(locations)
	local clusters = {}
	for _, location in ipairs(locations) do
		local match
		for _, cluster in ipairs(clusters) do
			if cluster.mapID == location.mapID
				and math.sqrt((cluster.x - location.x) ^ 2 + (cluster.y - location.y) ^ 2) <= 0.012 then
				match = cluster
				break
			end
		end
		if match then
			local count = #match.locations
			match.x = (match.x * count + location.x) / (count + 1)
			match.y = (match.y * count + location.y) / (count + 1)
			match.locations[#match.locations + 1] = location
		else
			clusters[#clusters + 1] = {
				mapID = location.mapID,
				x = location.x,
				y = location.y,
				locations = { location },
			}
		end
	end
	return clusters
end

ns.ClusterMapLocations = clusterLocations

local function tooltipLines(owner, group)
	if not group then return end
	GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
	for _, location in ipairs(group.locations) do
		GameTooltip:AddLine(location.name, 1, 0.85, 0.35)
		GameTooltip:AddLine(location.title .. " | " .. location.zone, 1, 1, 1)
		for _, category in ipairs(ns.MapCategories) do
			if location.services[category.key] and RoguetastiqDB["mapShow" .. category.key:sub(1, 1):upper() .. category.key:sub(2)] ~= false then
				GameTooltip:AddLine(category.label, category.r, category.g, category.b)
			end
		end
		if location.faction then GameTooltip:AddLine(location.faction, 0.75, 0.75, 0.75) end
	end
	GameTooltip:Show()
end

RoguetastiqMapPinMixin = CreateFromMixins(MapCanvasPinMixin)

function RoguetastiqMapPinMixin:OnLoad()
	self:SetSize(22, 22)
	self:EnableMouse(true)
	self:SetMouseMotionEnabled(true)
end

function RoguetastiqMapPinMixin:IsMouseMotionEnabled()
	return true
end

function RoguetastiqMapPinMixin:OnAcquired(group)
	self.group = group
	local category = locationCategory(group.locations[1])
	self.Icon:SetTexture(category.icon)
	self.Icon:SetVertexColor(category.r, category.g, category.b)
	self:SetPosition(group.x, group.y)
end

function RoguetastiqMapPinMixin:OnMouseEnter()
	tooltipLines(self, self.group)
end

function RoguetastiqMapPinMixin:OnMouseLeave()
	GameTooltip_Hide()
end

local RogueMapDataProviderMixin = CreateFromMixins(MapCanvasDataProviderMixin)

function RogueMapDataProviderMixin:RemoveAllData()
	self:GetMap():RemoveAllPinsByTemplate(pinTemplate)
end

function RogueMapDataProviderMixin:OnMapChanged()
	self:RefreshAllData()
end

function RogueMapDataProviderMixin:RefreshAllData()
	self:RemoveAllData()
	if not RoguetastiqDB or RoguetastiqDB.mapMarkersEnabled == false then return end
	local map = self:GetMap()
	local mapID = map:GetMapID()
	if not mapID or not C_Map.GetMapPosFromWorldPos then return end
	for _, group in ipairs(clusterLocations(selectedLocations())) do
		local category, worldPosition, continentID
		for _, location in ipairs(group.locations) do
			continentID, worldPosition = getWorldPosition(location)
			if worldPosition then break end
		end
		if worldPosition then
			local ok, targetMapID, position = pcall(C_Map.GetMapPosFromWorldPos, continentID, worldPosition, mapID)
			if ok and targetMapID == mapID and position then
				group.x, group.y = position:GetXY()
				map:AcquirePin(pinTemplate, group)
			end
		end
	end
end

local function createMinimapPin(location)
	local pin = CreateFrame("Button", nil, Minimap)
	pin:SetSize(15, 15)
	pin:SetFrameStrata("MEDIUM")
	pin:SetFrameLevel(Minimap:GetFrameLevel() + 4)
	local icon = pin:CreateTexture(nil, "OVERLAY")
	icon:SetAllPoints()
	pin.Icon = icon
	pin.location = location
	local category = locationCategory(location)
	icon:SetTexture(category.icon)
	icon:SetVertexColor(category.r, category.g, category.b)
	pin:SetScript("OnEnter", function(self)
		tooltipLines(self, { locations = { self.location } })
	end)
	pin:SetScript("OnLeave", GameTooltip_Hide)
	pin:Hide()
	return pin
end

local function updateMinimapPins()
	if not Minimap or not C_Minimap or not C_Map or not C_Map.GetPlayerMapPosition
		or not C_Map.GetWorldPosFromMapPos or not C_Minimap.GetViewRadius then return end
	local isEnabled = RoguetastiqDB and RoguetastiqDB.minimapMarkersEnabled ~= false
	local mapID = C_Minimap.GetUiMapID() or C_Map.GetBestMapForUnit("player")
	local playerPosition = mapID and C_Map.GetPlayerMapPosition(mapID, "player")
	local continentID, playerWorldPosition
	if playerPosition then
		continentID, playerWorldPosition = C_Map.GetWorldPosFromMapPos(mapID, playerPosition)
	end
	local radius = C_Minimap.GetViewRadius()
	if type(radius) ~= "number" or radius <= 0 then
		for _, pin in ipairs(minimapPins) do pin:Hide() end
		return
	end
	local diameter = Minimap:GetWidth() - 8
	local rotate = GetCVarBool and GetCVarBool("rotateMinimap")
	local facing = rotate and GetPlayerFacing and GetPlayerFacing() or 0
	local faction = UnitFactionGroup and UnitFactionGroup("player")
	for _, pin in ipairs(minimapPins) do
		local location = pin.location
		if isEnabled and mapID and playerWorldPosition
			and ns.ShouldShowMapLocation(location, RoguetastiqDB, faction) then
			local locationContinent, worldPosition = getWorldPosition(location)
			if locationContinent == continentID and worldPosition then
				local targetX, targetY = worldPosition:GetXY()
				local playerX, playerY = playerWorldPosition:GetXY()
				local offsetX, offsetY = ns.MinimapOffset(targetX - playerX, playerY - targetY,
					radius, diameter, rotate, facing)
				if offsetX then
					pin:ClearAllPoints()
					pin:SetPoint("CENTER", Minimap, "CENTER", offsetX, offsetY)
					pin:Show()
				else
					pin:Hide()
				end
			else
				pin:Hide()
			end
		else
			pin:Hide()
		end
	end
end

function ns.RefreshMapMarkers()
	if mapProvider then mapProvider:RefreshAllData() end
	updateMinimapPins()
end

function ns.InitializeMaps()
	if WorldMapFrame and WorldMapFrame.AddDataProvider and MapCanvasDataProviderMixin
		and MapCanvasPinMixin and not mapProvider then
		mapProvider = CreateFromMixins(RogueMapDataProviderMixin)
		WorldMapFrame:AddDataProvider(mapProvider)
	end
	for _, location in ipairs(ns.MapLocations) do minimapPins[#minimapPins + 1] = createMinimapPin(location) end
	ns.RefreshMapMarkers()
	if C_Timer and C_Timer.NewTicker then
		ticker = C_Timer.NewTicker(0.25, updateMinimapPins)
	end
end
