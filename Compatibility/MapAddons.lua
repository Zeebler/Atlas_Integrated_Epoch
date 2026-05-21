AtlasIntegratedEpoch = AtlasIntegratedEpoch or {}
local EDG = AtlasIntegratedEpoch

EDG.Compatibility = EDG.Compatibility or {}
local Compatibility = EDG.Compatibility

local function RememberAndHide(store, frame)
	if not frame or not frame.Hide then return end
	if store[frame] == nil then
		store[frame] = not frame.IsShown or frame:IsShown()
	end
	frame:Hide()
end

local function HideNamedFrames(store, names)
	for _, name in ipairs(names or {}) do
		RememberAndHide(store, getglobal(name))
	end
end

local function HideDropdownPieces(store, dropdownName)
	local dropdown = getglobal(dropdownName)
	if not dropdown then return end

	RememberAndHide(store, dropdown)
	for _, suffix in ipairs({ "Left", "Middle", "Right", "Text", "Button", "Icon" }) do
		RememberAndHide(store, getglobal(dropdownName..suffix))
	end
end

local function HideMatchingChildren(store, parent, matcher)
	if not parent or not parent.GetChildren then return end
	for _, child in ipairs({ parent:GetChildren() }) do
		if matcher(child) then
			RememberAndHide(store, child)
		end
	end
end

function Compatibility:SuppressPfQuest(store)
	HideNamedFrames(store, {
		"pfQuestMapDropdown",
		"pfQuestMapDropdownButton",
		"pfQuestRouteDisplay",
	})
	HideDropdownPieces(store, "pfQuestMapDropdown")

	if WorldMapButton and WorldMapButton.routes then
		RememberAndHide(store, WorldMapButton.routes)
	end

	if pfMap and pfMap.pins then
		for _, pin in pairs(pfMap.pins) do
			RememberAndHide(store, pin)
		end
	end

	HideMatchingChildren(store, WorldMapButton, function(child)
		local name = child.GetName and child:GetName()
		return name and (
			string.find(name, "^pfQuestContinentPin") or
			string.find(name, "^WorldMap") or
			string.find(name, "^QuestPOI") or
			string.find(name, "^Map") or
			string.find(name, "^poi")
		)
	end)

	HideNamedFrames(store, {
		"WorldMapPlayer",
		"WorldMapPlayerLower",
		"WorldMapPlayerUpper",
		"WorldMapCorpse",
		"WorldMapCorpseLower",
		"WorldMapCorpseUpper",
		"WorldMapPOIFrame",
		"WorldMapQuestFrame",
		"WorldMapBlobFrame",
		"WorldMapFrameAreaLabel",
		"WorldMapFrameAreaDescription",
		"WorldMapZoneInfo",
	})

	if pfMap and pfMap.tooltip then
		RememberAndHide(store, pfMap.tooltip)
	end
end

function Compatibility:SuppressModernMapMarkers(store)
	HideNamedFrames(store, {
		"MMMMarkerLabelFrame",
		"MMMDestMenu",
		"MMMFindPanel",
		"MMMFindScroll",
		"MMMFilterDropdown",
		"MMMFindDropdown",
	})
	HideDropdownPieces(store, "MMMFilterDropdown")
	HideDropdownPieces(store, "MMMFindDropdown")

	local destMenu = getglobal("MMMDestMenu")
	if destMenu and destMenu.intercept then
		RememberAndHide(store, destMenu.intercept)
	end

	if MMM then
		if MMM.HideMarkerInfo then MMM.HideMarkerInfo() end
		if MMM.ClearMarkers then MMM.ClearMarkers() end
		if MMM.SetUpdateEnabled then MMM.SetUpdateEnabled(false) end
	end

	local function IsModernMapMarker(child)
		if not child then return false end
		local name = child.GetName and child:GetName()
		return (name and string.find(name, "^MMM"))
			or child.markerName
			or child.markerDisplay
			or child.markerKind
			or child.transportDest
	end

	HideMatchingChildren(store, WorldMapDetailFrame, IsModernMapMarker)
	HideMatchingChildren(store, WorldMapButton, IsModernMapMarker)
end

function Compatibility:RestoreAfterSuppression()
	if pfMap and pfMap.UpdateNodes and WorldMapFrame and WorldMapFrame:IsShown() then
		pfMap:UpdateNodes()
	end

	if MMM and MMM.SetUpdateEnabled and ModernMapMarkersDB and ModernMapMarkersDB.showMarkers then
		MMM.SetUpdateEnabled(true)
		if MMM.UpdateMarkers and WorldMapFrame and WorldMapFrame:IsShown() then
			MMM.UpdateMarkers()
		end
	end
end

function Compatibility:SetWorldMapAddonsSuppressed(suppressed)
	self.hiddenFrames = self.hiddenFrames or {}

	if suppressed then
		local store = self.hiddenFrames
		self:SuppressPfQuest(store)
		self:SuppressModernMapMarkers(store)
		return
	end

	for frame, wasShown in pairs(self.hiddenFrames) do
		if frame and wasShown and frame.Show then
			frame:Show()
		end
	end
	self.hiddenFrames = {}
	self:RestoreAfterSuppression()
end

