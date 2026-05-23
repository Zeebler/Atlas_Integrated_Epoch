AtlasIntegratedEpoch = AtlasIntegratedEpoch or {}
local EDG = AtlasIntegratedEpoch
local T = EDG.Locale.Get

EDG.DungeonMenu = {}
local DungeonMenu = EDG.DungeonMenu

local WIDTH = 185

local function StyleLabel(label, menu)
	if not label then return end
	label:SetText(T("DUNGEON"))
	label:SetTextColor(1, 0.82, 0)
	if label.SetDrawLayer then
		label:SetDrawLayer("OVERLAY", 7)
	end
	if menu and menu.GetFrameLevel and label.SetParent then
		label:SetParent(menu)
	end
end

function DungeonMenu:Position()
	if not self.frame or not WorldMapFrame then return end

	local zoomOut = WorldMapZoomOutButton or getglobal("WorldMapZoomOutButton")
	local closeButton = WorldMapFrameCloseButton or getglobal("WorldMapFrameCloseButton")
	local anchor = WorldMapLevelDropDown or WorldMapZoneDropDown or WorldMapContinentDropDown
	self.frame:ClearAllPoints()
	if zoomOut then
		self.frame:SetPoint("LEFT", zoomOut, "RIGHT", 8, -4)
	elseif closeButton then
		self.frame:SetPoint("TOPRIGHT", closeButton, "BOTTOMRIGHT", -8, -36)
	elseif anchor then
		self.frame:SetPoint("TOPRIGHT", anchor, "TOPRIGHT", 0, 0)
	else
		self.frame:SetPoint("TOPLEFT", WorldMapFrame, "TOPLEFT", 560, -70)
	end

	if self.label then
		self.label:ClearAllPoints()
		local anchor = self.frame.backdrop or self.frame
		if EDG.Utils.IsElvUIWorldMapSkinEnabled() and self.frame.backdrop then
			self.label:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", 0, 2)
		else
			self.label:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", 20, -2)
		end
	end
end

function DungeonMenu:Initialize()
	if self.frame or not WorldMapFrame or not UIDropDownMenu_Initialize then return end

	local menu = CreateFrame("Frame", "AtlasIntegratedEpochDungeonDropDown", WorldMapFrame, "UIDropDownMenuTemplate")
	menu:SetFrameStrata("FULLSCREEN_DIALOG")
	menu:SetFrameLevel(120)
	UIDropDownMenu_SetWidth(menu, WIDTH)
	EDG.Utils.SkinDropDownBox(menu, WIDTH)

	local label = menu:CreateFontString("AtlasIntegratedEpochDungeonDropDownLabel", "OVERLAY", "GameFontNormal")
	StyleLabel(label, menu)

	UIDropDownMenu_Initialize(menu, function(_, level)
		local info = UIDropDownMenu_CreateInfo()
		info.text = T("CURRENT_ZONE")
		info.checked = not AtlasIntegratedEpochDB.selectedDungeon
		info.func = function()
			AtlasIntegratedEpochDB.selectedDungeon = nil
			DungeonMenu:RefreshText()
			EDG.MapIntegration:Refresh()
		end
		UIDropDownMenu_AddButton(info, level)

		info = UIDropDownMenu_CreateInfo()
		info.disabled = true
		info.notCheckable = true
		info.text = T("DUNGEON_MENU_HEADER")
		UIDropDownMenu_AddButton(info, level)

		for _, dungeon in ipairs(EDG.DataRegistry.dungeonList or {}) do
			local dungeonId = dungeon.id
			info = UIDropDownMenu_CreateInfo()
			info.text = dungeon.name
			info.value = dungeonId
			info.checked = AtlasIntegratedEpochDB.selectedDungeon == dungeonId
			info.func = function()
				AtlasIntegratedEpochDB.selectedDungeon = dungeonId
				EDG.DataRegistry:RememberCurrentInstanceChoice(dungeonId)
				DungeonMenu:RefreshText()
				EDG.MapIntegration:Refresh()
			end
			UIDropDownMenu_AddButton(info, level)
		end
	end)

	self.frame = menu
	self.label = label
	self:Position()
	self:RefreshText()
	self:SetShown(WorldMapFrame:IsShown())
end

function DungeonMenu:GetSelectedDungeon()
	local id = AtlasIntegratedEpochDB and AtlasIntegratedEpochDB.selectedDungeon
	if not id then return nil end
	local dungeon = EDG.DataRegistry:GetDungeon(id)
	if not dungeon then
		AtlasIntegratedEpochDB.selectedDungeon = nil
	end
	return dungeon
end

function DungeonMenu:GetCurrentZoneDungeon()
	return EDG.DataRegistry:GetDungeonForCurrentInstance()
end

function DungeonMenu:RefreshText()
	if not self.frame then return end

	local text = T("CURRENT_ZONE")
	if AtlasIntegratedEpochDB and AtlasIntegratedEpochDB.selectedDungeon then
		local dungeon = self:GetSelectedDungeon()
		text = dungeon and dungeon.name or T("DUNGEON")
	else
		local current = self:GetCurrentZoneDungeon()
		if current and EDG.Utils.IsInDungeon() then
			text = T("CURRENT_ZONE_DUNGEON", current.name)
		end
	end

	UIDropDownMenu_SetText(self.frame, text)
end

function DungeonMenu:SetShown(shown)
	if shown and EDG.Utils.IsWorldMapMinimized() then
		shown = false
	end
	if shown and DropDownList1 and DropDownList1:IsShown() and UIDROPDOWNMENU_OPEN_MENU == self.frame then
		shown = true
	end
	if shown then
		EDG.Utils.SkinDropDownBox(self.frame, WIDTH)
		StyleLabel(self.label, self.frame)
		self:Position()
	end
	if self.frame then
		if shown then self.frame:Show() else self.frame:Hide() end
	end
	if self.label then
		if shown then self.label:Show() else self.label:Hide() end
	end
end

function DungeonMenu:IsOpen()
	return self.frame
		and UIDROPDOWNMENU_OPEN_MENU == self.frame
		and DropDownList1
		and DropDownList1:IsShown()
end
