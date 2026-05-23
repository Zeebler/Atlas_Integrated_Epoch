AtlasIntegratedEpoch = AtlasIntegratedEpoch or {}
local EDG = AtlasIntegratedEpoch

EDG.Events = CreateFrame("Frame", "AtlasIntegratedEpochEvents")
EDG.Events.suppressor = CreateFrame("Frame", "AtlasIntegratedEpochTransitionSuppressor")
EDG.Events.suppressor:Hide()
EDG.Events.refreshRetry = CreateFrame("Frame", "AtlasIntegratedEpochRefreshRetry")
EDG.Events.refreshRetry:Hide()

EDG.Events.suppressor:SetScript("OnUpdate", function(frame)
	if not frame.untilTime or not GetTime or GetTime() > frame.untilTime then
		frame:Hide()
		return
	end
	if EDG.Utils.IsInDungeon() and WorldMapFrame and WorldMapFrame:IsShown() and EDG.Overlay then
		EDG.Overlay:SetMapAddonsSuppressed(true)
	end
end)

EDG.Events.refreshRetry:SetScript("OnUpdate", function(frame)
	if not frame.nextRefresh or not GetTime or GetTime() < frame.nextRefresh then return end

	frame.nextRefresh = GetTime() + 0.75
	frame.remaining = (frame.remaining or 1) - 1

	if EDG.MapIntegration then
		EDG.MapIntegration:Refresh()
	end

	if frame.remaining <= 0 then
		frame:Hide()
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

function EDG.Events:StartRefreshRetry()
	if not GetTime then return end
	self.refreshRetry.remaining = 6
	self.refreshRetry.nextRefresh = GetTime() + 0.25
	self.refreshRetry:Show()
end

function EDG.Events:UpdateInstanceSelectionScope()
	if not EDG.DataRegistry or not EDG.DataRegistry.ClearCurrentInstanceChoice then return end

	if not EDG.Utils.IsInDungeon() then
		self.lastInstanceKey = nil
		EDG.DataRegistry:ClearCurrentInstanceChoice()
		return
	end

	local currentKey = EDG.DataRegistry:GetCurrentInstanceKey()
	if self.lastInstanceKey and currentKey and self.lastInstanceKey ~= currentKey then
		EDG.DataRegistry:ClearCurrentInstanceChoice()
	end
	self.lastInstanceKey = currentKey
end

function EDG.Events:PLAYER_ENTERING_WORLD()
	self:UpdateInstanceSelectionScope()
	self:SuppressDungeonMapNoise()
	self:StartRefreshRetry()
	EDG.MapIntegration:Refresh()
end

function EDG.Events:ZONE_CHANGED_NEW_AREA()
	self:UpdateInstanceSelectionScope()
	self:SuppressDungeonMapNoise()
	self:StartRefreshRetry()
	EDG.MapIntegration:Refresh()
end

function EDG.Events:ZONE_CHANGED_INDOORS()
	self:UpdateInstanceSelectionScope()
	self:SuppressDungeonMapNoise()
	self:StartRefreshRetry()
	EDG.MapIntegration:Refresh()
end

function EDG.Events:ZONE_CHANGED()
	self:UpdateInstanceSelectionScope()
	self:SuppressDungeonMapNoise()
	self:StartRefreshRetry()
	EDG.MapIntegration:Refresh()
end
