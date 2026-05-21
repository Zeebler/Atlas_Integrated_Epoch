AtlasIntegratedEpoch = AtlasIntegratedEpoch or {}
local EDG = AtlasIntegratedEpoch

EDG.MapIntegration = {}
local MapIntegration = EDG.MapIntegration

function MapIntegration:Initialize()
	if self.initialized then return end
	self.initialized = true

	if WorldMapFrame then
		WorldMapFrame:HookScript("OnShow", function()
			if AtlasIntegratedEpochDB then
				AtlasIntegratedEpochDB.selectedDungeon = nil
			end
			if EDG.DungeonMenu then
				EDG.DungeonMenu:SetShown(true)
				EDG.DungeonMenu:RefreshText()
			end
			MapIntegration:Refresh()
		end)
		WorldMapFrame:HookScript("OnHide", function()
			if EDG.DungeonMenu then
				EDG.DungeonMenu:SetShown(false)
			end
			EDG.Overlay:Hide()
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
	if EDG.DungeonMenu then
		EDG.DungeonMenu:RefreshText()
	end

	if selected and dungeon then
		EDG.Overlay:SetMapAddonsSuppressed(true)
		EDG.Overlay:ShowDungeon(dungeon, 1)
	elseif dungeon and EDG.Utils.IsInDungeon() then
		EDG.Overlay:SetMapAddonsSuppressed(true)
		EDG.Overlay:ShowDungeon(dungeon, 1)
	else
		EDG.Overlay:Hide()
	end
end
