AtlasIntegratedEpoch = AtlasIntegratedEpoch or {}
local EDG = AtlasIntegratedEpoch

EDG.MapIntegration = {}
local MapIntegration = EDG.MapIntegration

function MapIntegration:ResetToCurrentZone()
	if AtlasIntegratedEpochDB then
		AtlasIntegratedEpochDB.selectedDungeon = nil
	end
	if EDG.Overlay then
		EDG.Overlay:Hide()
	end
	if EDG.DungeonMenu then
		EDG.DungeonMenu:RefreshText()
	end
end

function MapIntegration:Initialize()
	if self.initialized then return end
	self.initialized = true

	if WorldMapFrame then
		WorldMapFrame:HookScript("OnShow", function()
			MapIntegration:ResetToCurrentZone()
			if EDG.DungeonMenu then
				EDG.DungeonMenu:SetShown(true)
			end
			MapIntegration:Refresh()
			if EDG.Events and EDG.Events.StartRefreshRetry then
				EDG.Events:StartRefreshRetry()
			end
		end)
		WorldMapFrame:HookScript("OnHide", function()
			if EDG.DungeonMenu then
				EDG.DungeonMenu:SetShown(false)
			end
			EDG.Overlay:Hide()
		end)
	end

	local zoomOut = WorldMapZoomOutButton or getglobal("WorldMapZoomOutButton")
	if zoomOut and zoomOut.HookScript then
		zoomOut:HookScript("OnClick", function()
			MapIntegration:ResetToCurrentZone()
		end)
	end
end

function MapIntegration:Refresh()
	if EDG.DungeonMenu and EDG.DungeonMenu:IsOpen() then
		return
	end

	if not AtlasIntegratedEpochDB or not AtlasIntegratedEpochDB.enabled then
		EDG.Overlay:Hide()
		return
	end

	if not WorldMapFrame or not WorldMapFrame:IsShown() then
		EDG.Overlay:Hide()
		return
	end

	if EDG.DungeonMenu then
		EDG.DungeonMenu:SetShown(true)
	end

	local selected = EDG.DungeonMenu and EDG.DungeonMenu:GetSelectedDungeon()
	local dungeon = selected or (EDG.DungeonMenu and EDG.DungeonMenu:GetCurrentZoneDungeon()) or EDG.DataRegistry:GetDungeonForCurrentInstance()
	local ambiguousOptions, ambiguousInstanceName
	if not dungeon and EDG.Utils.IsInDungeon() and EDG.DataRegistry.GetAmbiguousCurrentInstanceOptions then
		ambiguousOptions, ambiguousInstanceName = EDG.DataRegistry:GetAmbiguousCurrentInstanceOptions()
	end
	if EDG.DungeonMenu then
		EDG.DungeonMenu:RefreshText()
	end

	if selected and dungeon then
		EDG.Overlay:SetMapAddonsSuppressed(true)
		EDG.Overlay:ShowDungeon(dungeon, 1)
	elseif dungeon and EDG.Utils.IsInDungeon() then
		EDG.Overlay:SetMapAddonsSuppressed(true)
		EDG.Overlay:ShowDungeon(dungeon, 1)
	elseif ambiguousOptions then
		EDG.Overlay:SetMapAddonsSuppressed(true)
		EDG.Overlay:ShowAmbiguousInstance(ambiguousOptions, ambiguousInstanceName)
	else
		EDG.Overlay:Hide()
	end
end
