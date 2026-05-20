AtlasIntegratedEpoch = AtlasIntegratedEpoch or {}
local EDG = AtlasIntegratedEpoch
local T = EDG.Locale.Get

local Registry = EDG.DataRegistry

EDG.Overlay = {}
local Overlay = EDG.Overlay

local function ApplyParchment(texture)
	if not texture then return end
	texture:SetTexture("Interface\\QuestFrame\\QuestBG")
	texture:SetTexCoord(0, 1, 0, 1)
	if texture.SetHorizTile then texture:SetHorizTile(false) end
	if texture.SetVertTile then texture:SetVertTile(false) end
	texture:SetVertexColor(1, 0.92, 0.76)
	texture:SetAlpha(1)
end

local function ApplySidePanelStyle(panel)
	if not panel then return end

	if EDG.Utils.IsElvUIWorldMapSkinEnabled() then
		local engine = EDG.Utils.GetElvUIEngine()
		if panel.SetBackdrop then
			if panel.SetTemplate then
				panel:SetTemplate("Transparent")
			else
				panel:SetBackdrop({
					bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
					edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
					tile = true,
					tileSize = 16,
					edgeSize = 12,
					insets = { left = 3, right = 3, top = 3, bottom = 3 },
				})
				panel:SetBackdropColor(0.06, 0.06, 0.06, 0.86)
				panel:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
			end
			if engine and engine.media then
				if engine.media.backdropcolor then
					panel:SetBackdropColor(unpack(engine.media.backdropcolor))
				end
				if engine.media.bordercolor then
					panel:SetBackdropBorderColor(unpack(engine.media.bordercolor))
				end
			end
		end
		if panel.parchment then panel.parchment:Hide() end
	else
		if panel.SetBackdrop then
			panel:SetBackdropColor(0, 0, 0, 0)
			panel:SetBackdropBorderColor(0.45, 0.45, 0.45, 0.85)
		end
		if panel.parchment then panel.parchment:Show() end
	end
end

function Overlay:Create()
	if self.frame then return self.frame end

	local parent = EDG.Utils.GetMapParent()
	if not parent then return nil end

	local frame = CreateFrame("Frame", "AtlasIntegratedEpochOverlay", parent)
	frame:SetAllPoints(parent)
	frame:SetFrameStrata("FULLSCREEN_DIALOG")
	frame:SetFrameLevel(100)
	frame:EnableMouse(true)
	frame:Hide()
	frame:SetScript("OnUpdate", function(_, elapsed)
		if EDG.DungeonMenu and EDG.DungeonMenu:IsOpen() then return end
		Overlay:RefreshLayout()
		Overlay:SetPfQuestSuppressed(true)
	end)

	frame.bg = frame:CreateTexture(nil, "BACKGROUND")
	frame.bg:SetAllPoints(frame)
	frame.bg:SetTexture(0, 0, 0, 1)

	frame.side = CreateFrame("Frame", "AtlasIntegratedEpochSidePanel", frame)
	frame.side:SetFrameStrata("FULLSCREEN_DIALOG")
	frame.side:SetFrameLevel(frame:GetFrameLevel() + 40)
	frame.side:SetWidth(230)
	frame.side:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -10)
	frame.side:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 10, 10)
	frame.side:EnableMouse(true)
	if frame.side.SetBackdrop then
		frame.side:SetBackdrop({
			bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = true,
			tileSize = 16,
			edgeSize = 12,
			insets = { left = 3, right = 3, top = 3, bottom = 3 },
		})
		frame.side:SetBackdropColor(0, 0, 0, 0)
		frame.side:SetBackdropBorderColor(0.45, 0.45, 0.45, 0.85)
	end

	frame.side.parchment = frame.side:CreateTexture(nil, "BACKGROUND")
	frame.side.parchment:SetPoint("TOPLEFT", frame.side, "TOPLEFT", 4, -4)
	frame.side.parchment:SetPoint("BOTTOMRIGHT", frame.side, "BOTTOMRIGHT", -4, 4)
	ApplyParchment(frame.side.parchment)
	if not frame.side.parchment:GetTexture() then
		frame.side.parchment:SetTexture("Interface\\AchievementFrame\\UI-Achievement-Parchment")
		frame.side.parchment:SetTexCoord(0, 1, 0, 1)
		frame.side.parchment:SetVertexColor(1, 0.92, 0.76)
		frame.side.parchment:SetAlpha(1)
	end
	ApplySidePanelStyle(frame.side)

	frame.mapArea = CreateFrame("Button", "AtlasIntegratedEpochMapArea", frame)
	frame.mapArea:SetFrameStrata("FULLSCREEN_DIALOG")
	frame.mapArea:SetFrameLevel(frame:GetFrameLevel() + 10)
	frame.mapArea:SetPoint("TOPLEFT", frame.side, "TOPRIGHT", 10, 0)
	frame.mapArea:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -8, 10)
	frame.mapArea:RegisterForClicks("RightButtonUp")
	if frame.mapArea.SetBackdrop then
		frame.mapArea:SetBackdrop({
			bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = true,
			tileSize = 16,
			edgeSize = 12,
			insets = { left = 3, right = 3, top = 3, bottom = 3 },
		})
		frame.mapArea:SetBackdropColor(0, 0, 0, 1)
		frame.mapArea:SetBackdropBorderColor(0.45, 0.45, 0.45, 0.85)
	end
	frame.mapArea:SetScript("OnClick", function(_, button)
		if button == "RightButton" then
			if AtlasIntegratedEpochDB then
				AtlasIntegratedEpochDB.selectedDungeon = nil
			end
			Overlay:Hide()
			if EDG.DungeonMenu then
				EDG.DungeonMenu:RefreshText()
			end
		end
	end)

	frame.mapTexture = frame.mapArea:CreateTexture(nil, "ARTWORK")
	frame.mapTexture:SetPoint("TOPLEFT", frame.mapArea, "TOPLEFT", 4, -4)
	frame.mapTexture:SetPoint("BOTTOMRIGHT", frame.mapArea, "BOTTOMRIGHT", -4, 4)
	frame.mapTexture:SetTexCoord(0, 1, 0, 1)

	frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	frame.title:SetPoint("TOPLEFT", frame.mapArea, "TOPLEFT", 8, -8)
	frame.title:SetPoint("RIGHT", frame.mapArea, "RIGHT", -150, 0)
	frame.title:SetJustifyH("LEFT")

	frame.disclaimer = frame.mapArea:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	frame.disclaimer:SetPoint("BOTTOM", frame.mapArea, "BOTTOM", 0, 6)
	frame.disclaimer:SetWidth(420)
	frame.disclaimer:SetJustifyH("CENTER")
	frame.disclaimer:SetTextColor(1, 0.2, 0.2)
	frame.disclaimer:SetText(T("LIVE_POSITIONS_UNAVAILABLE"))

	frame.floorPrev = CreateFrame("Button", "AtlasIntegratedEpochFloorPrev", frame.mapArea, "UIPanelButtonTemplate")
	frame.floorPrev:SetWidth(28)
	frame.floorPrev:SetHeight(20)
	frame.floorPrev:SetPoint("TOPRIGHT", frame.mapArea, "TOPRIGHT", -102, -8)
	frame.floorPrev:SetText("<")
	frame.floorPrev:SetScript("OnClick", function()
		Overlay:ChangeFloor(-1)
	end)

	frame.floorText = frame.mapArea:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	frame.floorText:SetWidth(66)
	frame.floorText:SetPoint("LEFT", frame.floorPrev, "RIGHT", 2, 0)
	frame.floorText:SetJustifyH("CENTER")

	frame.floorNext = CreateFrame("Button", "AtlasIntegratedEpochFloorNext", frame.mapArea, "UIPanelButtonTemplate")
	frame.floorNext:SetWidth(28)
	frame.floorNext:SetHeight(20)
	frame.floorNext:SetPoint("LEFT", frame.floorText, "RIGHT", 2, 0)
	frame.floorNext:SetText(">")
	frame.floorNext:SetScript("OnClick", function()
		Overlay:ChangeFloor(1)
	end)

	frame.pinLayer = CreateFrame("Frame", "AtlasIntegratedEpochPinLayer", frame.mapArea)
	frame.pinLayer:SetPoint("TOPLEFT", frame.mapArea, "TOPLEFT", 4, -4)
	frame.pinLayer:SetPoint("BOTTOMRIGHT", frame.mapArea, "BOTTOMRIGHT", -4, 4)
	frame.pinLayer:SetFrameLevel(frame.mapArea:GetFrameLevel() + 5)

	local bossList = EDG.BossList:Create(frame.side)
	bossList:SetFrameLevel(frame.side:GetFrameLevel() + 20)
	bossList:SetPoint("TOPLEFT", frame.side, "TOPLEFT", 8, -10)
	bossList:SetPoint("BOTTOMRIGHT", frame.side, "BOTTOMRIGHT", -8, 10)

	EDG.LootPanel:Create(frame)

	self.frame = frame
	self.pins = {}
	self:RefreshLayout(true)
	return frame
end

function Overlay:ShouldHideBossList()
	return AtlasIntegratedEpochDB
		and AtlasIntegratedEpochDB.hideBossListWhenMinimized
		and EDG.Utils.IsWorldMapMinimized()
end

function Overlay:RefreshLayout(force)
	local frame = self.frame
	if not frame or not frame.side or not frame.mapArea then return end

	local hideBossList = self:ShouldHideBossList()
	if not force and self.hideBossListForMinimized == hideBossList then return end
	self.hideBossListForMinimized = hideBossList

	frame.mapArea:ClearAllPoints()
	if hideBossList then
		frame.side:Hide()
		frame.mapArea:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -10)
		frame.mapArea:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -8, 10)
		if EDG.LootPanel then EDG.LootPanel:Hide() end
		self.selectedBoss = nil
		if EDG.BossList then EDG.BossList:SetSelected(nil) end
	else
		ApplySidePanelStyle(frame.side)
		frame.side:Show()
		frame.mapArea:SetPoint("TOPLEFT", frame.side, "TOPRIGHT", 10, 0)
		frame.mapArea:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -8, 10)
	end

	self:RefreshPins()
end

local function RememberAndHide(store, frame)
	if not frame or not frame.Hide then return end
	if store[frame] == nil then
		store[frame] = not frame.IsShown or frame:IsShown()
	end
	frame:Hide()
end

function Overlay:SetPfQuestSuppressed(suppressed)
	self.pfQuestHidden = self.pfQuestHidden or {}

	if suppressed then
		local store = self.pfQuestHidden

		for _, name in ipairs({
			"pfQuestMapDropdown",
			"pfQuestMapDropdownButton",
			"pfQuestRouteDisplay",
		}) do
			RememberAndHide(store, getglobal(name))
		end

		local dropdown = getglobal("pfQuestMapDropdown")
		if dropdown then
			local base = dropdown:GetName()
			for _, suffix in ipairs({ "Left", "Middle", "Right", "Text", "Button", "Icon" }) do
				RememberAndHide(store, getglobal(base..suffix))
			end
		end

		if WorldMapButton and WorldMapButton.routes then
			RememberAndHide(store, WorldMapButton.routes)
		end

		if pfMap and pfMap.pins then
			for _, pin in pairs(pfMap.pins) do
				RememberAndHide(store, pin)
			end
		end

		if WorldMapButton and WorldMapButton.GetChildren then
			for _, child in ipairs({ WorldMapButton:GetChildren() }) do
				local name = child.GetName and child:GetName()
				if name and string.find(name, "^pfQuestContinentPin") then
					RememberAndHide(store, child)
				elseif name and (
					string.find(name, "^WorldMap") or
					string.find(name, "^QuestPOI") or
					string.find(name, "^Map") or
					string.find(name, "^poi")
				) then
					RememberAndHide(store, child)
				end
			end
		end

		for _, frameName in ipairs({
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
		}) do
			RememberAndHide(store, getglobal(frameName))
		end

		if pfMap and pfMap.tooltip then
			RememberAndHide(store, pfMap.tooltip)
		end
	else
		for frame, wasShown in pairs(self.pfQuestHidden) do
			if frame and wasShown and frame.Show then
				frame:Show()
			end
		end
		self.pfQuestHidden = {}
		if pfMap and pfMap.UpdateNodes and WorldMapFrame and WorldMapFrame:IsShown() then
			pfMap:UpdateNodes()
		end
	end
end

function Overlay:ShowDungeon(dungeon, floorIndex)
	local frame = self:Create()
	if not frame or not dungeon then return end

	local totalFloors = table.getn(dungeon.floors or {})
	local requestedIndex = floorIndex or self.currentFloorIndex or 1
	if self.currentDungeon and self.currentDungeon.id ~= dungeon.id then
		requestedIndex = 1
	end
	requestedIndex = EDG.Utils.Clamp(requestedIndex, 1, math.max(totalFloors, 1))
	local floor = dungeon.floors and dungeon.floors[requestedIndex] or Registry:GetDefaultFloor(dungeon)
	if not floor then return end

	if self.currentDungeon and self.currentDungeon.id ~= dungeon.id then
		self.selectedBoss = nil
		EDG.LootPanel:Hide()
	end

	self.currentDungeon = dungeon
	self.currentFloor = floor
	self.currentFloorIndex = requestedIndex
	frame.title:SetText(dungeon.name)
	frame.mapTexture:SetTexture(floor.texture or "")
	frame:Show()
	self:RefreshLayout(true)
	self:SetPfQuestSuppressed(true)

	self:RefreshFloorControls()
	self:RefreshPins()
	EDG.BossList:SetBosses(dungeon.bosses or {})
	EDG.BossList:SetSelected(self.selectedBoss)
	EDG.Debug.Trace("Showing "..dungeon.name)
end

function Overlay:Hide()
	if self.frame then self.frame:Hide() end
	self:SetPfQuestSuppressed(false)
	self.selectedBoss = nil
	self.currentDungeon = nil
	self.currentFloor = nil
	self.currentFloorIndex = nil
	EDG.BossList:SetSelected(nil)
	EDG.LootPanel:Hide()
	EDG.Tooltip.Hide()
end

function Overlay:ChangeFloor(delta)
	if not self.currentDungeon or not self.currentDungeon.floors then return end
	local total = table.getn(self.currentDungeon.floors)
	if total <= 1 then return end
	local nextIndex = EDG.Utils.Clamp((self.currentFloorIndex or 1) + delta, 1, total)
	if nextIndex ~= self.currentFloorIndex then
		self.selectedBoss = nil
		EDG.LootPanel:Hide()
		self:ShowDungeon(self.currentDungeon, nextIndex)
	end
end

function Overlay:RefreshFloorControls()
	local frame = self.frame
	if not frame or not self.currentDungeon then return end
	local total = table.getn(self.currentDungeon.floors or {})
	if total > 1 then
		frame.floorText:SetText((self.currentFloorIndex or 1).." / "..total)
		frame.floorPrev:Show()
		frame.floorText:Show()
		frame.floorNext:Show()
	else
		frame.floorPrev:Hide()
		frame.floorText:Hide()
		frame.floorNext:Hide()
	end
end

function Overlay:IsShown()
	return self.frame and self.frame:IsShown()
end

function Overlay:SelectBoss(boss, sourceButton)
	if not boss then return end

	if self.selectedBoss and self.selectedBoss.id == boss.id and EDG.LootPanel.frame and EDG.LootPanel.frame:IsShown() then
		self.selectedBoss = nil
		EDG.BossList:SetSelected(nil)
		EDG.LootPanel:Hide()
		return
	end

	self.selectedBoss = boss
	EDG.BossList:SetSelected(boss)
	EDG.LootPanel:Hide()
	EDG.LootPanel:ShowForBoss(boss, sourceButton or self:GetPinForBoss(boss), self.frame)
end

function Overlay:GetPinForBoss(boss)
	for _, pin in ipairs(self.pins or {}) do
		if pin.boss and boss and pin.boss.id == boss.id then return pin end
	end
	return self.frame and self.frame.side
end

function Overlay:RefreshPins()
	if not self.frame then return end
	for _, pin in ipairs(self.pins or {}) do
		pin:Hide()
	end

	local index = 0
	for _, boss in ipairs((self.currentDungeon and self.currentDungeon.bosses) or {}) do
		if boss.floor == self.currentFloor.id and boss.x and boss.y then
			index = index + 1
			local pin = self.pins[index]
			if not pin then
				pin = CreateFrame("Button", "AtlasIntegratedEpochBossPin"..index, self.frame.pinLayer)
				pin:SetWidth(20)
				pin:SetHeight(20)
				pin:RegisterForClicks("LeftButtonUp")
				pin.tex = pin:CreateTexture(nil, "ARTWORK")
				pin.tex:SetAllPoints(pin)
				pin.tex:SetTexture("Interface\\MINIMAP\\TRACKING\\Target")
				pin:SetScript("OnEnter", function(button)
					GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
					GameTooltip:SetText(button.boss and (button.boss.displayName or button.boss.name) or T("UNKNOWN_BOSS"))
					GameTooltip:Show()
				end)
				pin:SetScript("OnLeave", function()
					GameTooltip:Hide()
				end)
				pin:SetScript("OnClick", function(button)
					Overlay:SelectBoss(button.boss, button)
				end)
				self.pins[index] = pin
			end
			pin.boss = boss
			pin:ClearAllPoints()
			pin:SetPoint("CENTER", self.frame.pinLayer, "TOPLEFT", boss.x * self.frame.pinLayer:GetWidth(), -boss.y * self.frame.pinLayer:GetHeight())
			pin:Show()
		end
	end
end
