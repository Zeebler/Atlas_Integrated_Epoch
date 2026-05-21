AtlasIntegratedEpoch = AtlasIntegratedEpoch or {}
local EDG = AtlasIntegratedEpoch

EDG.Events = CreateFrame("Frame", "AtlasIntegratedEpochEvents")
EDG.Events.suppressor = CreateFrame("Frame", "AtlasIntegratedEpochTransitionSuppressor")
EDG.Events.suppressor:Hide()

EDG.Events.suppressor:SetScript("OnUpdate", function(frame)
	if not frame.untilTime or not GetTime or GetTime() > frame.untilTime then
		frame:Hide()
		return
	end
	if EDG.Utils.IsInDungeon() and WorldMapFrame and WorldMapFrame:IsShown() and EDG.Overlay then
		EDG.Overlay:SetMapAddonsSuppressed(true)
	end
end)

EDG.Events:SetScript("OnEvent", function(self, event, ...)
	if self[event] then self[event](self, ...) end
end)

function EDG.Events:Initialize()
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	self:RegisterEvent("ZONE_CHANGED_INDOORS")
	self:RegisterEvent("ZONE_CHANGED")
end

function EDG.Events:SuppressDungeonMapNoise()
	if not EDG.Utils.IsInDungeon() or not EDG.Overlay then return end
	EDG.Overlay:SetMapAddonsSuppressed(true)
	if GetTime then
		self.suppressor.untilTime = GetTime() + 2
		self.suppressor:Show()
	end
end

function EDG.Events:PLAYER_ENTERING_WORLD()
	self:SuppressDungeonMapNoise()
	EDG.MapIntegration:Refresh()
end

function EDG.Events:ZONE_CHANGED_NEW_AREA()
	self:SuppressDungeonMapNoise()
	EDG.MapIntegration:Refresh()
end

function EDG.Events:ZONE_CHANGED_INDOORS()
	self:SuppressDungeonMapNoise()
	EDG.MapIntegration:Refresh()
end

function EDG.Events:ZONE_CHANGED()
	self:SuppressDungeonMapNoise()
	EDG.MapIntegration:Refresh()
end
