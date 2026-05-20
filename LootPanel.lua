AtlasIntegratedEpoch = AtlasIntegratedEpoch or {}
local EDG = AtlasIntegratedEpoch
local T = EDG.Locale.Get

local U = EDG.Utils
local Registry = EDG.DataRegistry

EDG.LootPanel = {}
local LootPanel = EDG.LootPanel

local MAX_ROWS = 14
local ROW_HEIGHT = 26
local BASE_WIDTH = 320
local MIN_WIDTH = BASE_WIDTH
local MAX_WIDTH = 430

local function FirstDropText(...)
	for i = 1, select("#", ...) do
		local value = select(i, ...)
		if type(value) == "string" and value ~= "" then
			if string.find(value, "%%") or string.find(string.lower(value), "drop") then
				return value
			end
		elseif type(value) == "number" then
			return tostring(value).."%"
		end
	end
	return ""
end

local function ParseLootRow(raw)
	if type(raw) ~= "table" then return nil end

	local itemID = raw.itemID or raw[2]
	local isSpell = type(itemID) == "string" and string.sub(itemID, 1, 1) == "s"
	local spellID = isSpell and tonumber(string.sub(itemID, 2)) or nil
	local numericItemID = (not isSpell and tonumber(itemID)) or nil
	local name = raw.name or raw[4] or ""
	local extra = raw.extra or raw[6] or raw[5] or ""
	local icon = raw.icon or raw[3]
	local drop = raw.drop or FirstDropText(raw[7], raw[8], raw[9])
	if drop == "" then
		drop = "|cffff5555N/A %|r"
	end

	if spellID and GetSpellInfo then
		local spellName, _, spellIcon = GetSpellInfo(spellID)
		name = spellName or U.CleanMarkup(name)
		icon = spellIcon or icon
	elseif numericItemID and GetItemInfo and GetItemInfo(numericItemID) then
		local itemName, _, itemQuality, _, _, _, _, _, _, itemTexture = GetItemInfo(numericItemID)
		local _, _, _, color = GetItemQualityColor(itemQuality or 1)
		name = (color or "|cffffffff")..(itemName or U.CleanMarkup(name))
		icon = itemTexture or icon
	else
		name = U.CleanMarkup(name)
	end

	extra = U.CleanMarkup(extra)

	if not icon or icon == "" or icon == "?" then
		icon = (numericItemID and GetItemIcon and GetItemIcon(numericItemID)) or "Interface\\Icons\\INV_Misc_QuestionMark"
	elseif type(icon) == "string" and not string.find(icon, "\\") then
		icon = "Interface\\Icons\\"..icon
	end

	return {
		itemID = numericItemID,
		spellID = spellID,
		name = name ~= "" and name or (numericItemID and ("ItemID: "..numericItemID) or T("UNKNOWN_ITEM")),
		extra = extra,
		icon = icon,
		drop = drop,
	}
end

local function IsHeader(row)
	if type(row) ~= "table" then return false end
	if row.header then return true end
	if row[2] == 0 or row[2] == "0" then return true end
	local text = row[4] or ""
	return type(text) == "string" and string.find(text, "=q6=", 1, true)
end

local function BossSpecificRows(rows, boss)
	if not rows or not boss or not boss.name then return rows end

	local bossKey = U.NameKey(boss.name)
	if bossKey == "" then return rows end

	local startIndex
	for i = 1, table.getn(rows) do
		local row = rows[i]
		if IsHeader(row) then
			local headerKey = U.NameKey(row.name or row[4])
			if headerKey == bossKey or string.find(headerKey, bossKey, 1, true) or string.find(bossKey, headerKey, 1, true) then
				startIndex = i + 1
				break
			end
		end
	end

	if not startIndex then
		local matched = {}
		for i = 1, table.getn(rows) do
			local row = rows[i]
			if not IsHeader(row) then
				local rowText = U.CleanMarkup(
					tostring(row.name or "").." "..
					tostring(row[4] or "").." "..
					tostring(row.extra or "").." "..
					tostring(row[5] or "").." "..
					tostring(row[6] or "")
				)
				local rowKey = U.NameKey(rowText)
				if string.find(rowKey, bossKey, 1, true) then
					table.insert(matched, row)
				end
			end
		end
		if table.getn(matched) > 0 then
			return matched
		end
		return rows
	end

	local filtered = {}
	for i = startIndex, table.getn(rows) do
		local row = rows[i]
		if IsHeader(row) then break end
		table.insert(filtered, row)
	end

	return table.getn(filtered) > 0 and filtered or rows
end

function LootPanel:Create(parent)
	if self.frame then return self.frame end

	local frame = CreateFrame("Frame", "AtlasIntegratedEpochLootPanel", parent)
	frame:SetWidth(MIN_WIDTH)
	frame:SetHeight(430)
	frame:SetFrameLevel(parent:GetFrameLevel() + 30)
	frame:EnableMouse(true)
	if frame.SetBackdrop then
		frame:SetBackdrop({
			bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = true,
			tileSize = 16,
			edgeSize = 14,
			insets = { left = 4, right = 4, top = 4, bottom = 4 },
		})
		frame:SetBackdropColor(0, 0, 0, 0.88)
		frame:SetBackdropBorderColor(0.55, 0.55, 0.55, 0.9)
	end
	frame:Hide()

	frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -10)
	frame.title:SetPoint("RIGHT", frame, "RIGHT", -34, 0)
	frame.title:SetJustifyH("LEFT")

	frame.close = CreateFrame("Button", "AtlasIntegratedEpochLootCloseButton", frame, "UIPanelCloseButton")
	frame.close:SetFrameLevel(frame:GetFrameLevel() + 20)
	frame.close:EnableMouse(true)
	frame.close:SetWidth(22)
	frame.close:SetHeight(22)
	frame.close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -5)
	frame.close:SetScript("OnClick", function()
		EDG.LootPanel:Hide()
		if EDG.Overlay then
			EDG.Overlay.selectedBoss = nil
		end
		if EDG.BossList then
			EDG.BossList:SetSelected(nil)
		end
	end)

	frame.rows = {}
	for i = 1, MAX_ROWS do
		local row = CreateFrame("Button", "AtlasIntegratedEpochLootRow"..i, frame)
		row:EnableMouse(true)
		row:SetFrameLevel(frame:GetFrameLevel() + 5)
		row:SetHeight(ROW_HEIGHT)
		row:SetPoint("LEFT", frame, "LEFT", 14, 0)
		row:SetPoint("RIGHT", frame, "RIGHT", -14, 0)
		if i == 1 then
			row:SetPoint("TOP", frame, "TOP", 0, -34)
		else
			row:SetPoint("TOP", frame.rows[i - 1], "BOTTOM", 0, -1)
		end
		row:RegisterForClicks("LeftButtonUp")
		row.hover = row:CreateTexture(nil, "BACKGROUND")
		row.hover:SetAllPoints(row)
		row.hover:SetTexture(1, 0.82, 0, 0.12)
		row.hover:Hide()
		row.icon = row:CreateTexture(nil, "ARTWORK")
		row.icon:SetWidth(22)
		row.icon:SetHeight(22)
		row.icon:SetPoint("LEFT", row, "LEFT", 0, 0)
		row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		row.name:SetPoint("LEFT", row.icon, "RIGHT", 8, 5)
		row.name:SetPoint("RIGHT", row, "RIGHT", -50, 5)
		row.name:SetJustifyH("LEFT")
		row.extra = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
		row.extra:SetPoint("LEFT", row.icon, "RIGHT", 8, -7)
		row.extra:SetPoint("RIGHT", row, "RIGHT", -50, -7)
		row.extra:SetJustifyH("LEFT")
		row.drop = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		row.drop:SetPoint("RIGHT", row, "RIGHT", -2, 0)
		row.drop:SetWidth(44)
		row.drop:SetJustifyH("RIGHT")
		row:SetScript("OnEnter", function(button)
			button.hover:Show()
			EDG.Tooltip.ShowLootRow(button)
		end)
		row:SetScript("OnLeave", function(button)
			button.hover:Hide()
			EDG.Tooltip.Hide()
		end)
		row:SetScript("OnClick", function(button)
			local item = button.item
			if item and item.itemID and IsShiftKeyDown and IsShiftKeyDown() then
				local _, link = GetItemInfo(item.itemID)
				if link and ChatEdit_InsertLink then ChatEdit_InsertLink(link) end
			end
		end)
		row:Hide()
		frame.rows[i] = row
	end

	frame.empty = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	frame.empty:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -36)
	frame.empty:SetPoint("RIGHT", frame, "RIGHT", -14, 0)
	frame.empty:SetJustifyH("LEFT")

	self.frame = frame
	return frame
end

function LootPanel:Hide()
	if self.frame then self.frame:Hide() end
	EDG.Tooltip.Hide()
end

function LootPanel:ShowForBoss(boss, anchor, boundsFrame)
	local frame = self.frame
	if not frame or not boss then return false end

	local rawRows = {}
	for _, tableId in ipairs(boss.loot or {}) do
		local tableData = Registry:GetLootTable(tableId)
		if tableData then
			for _, row in ipairs(BossSpecificRows(tableData.rows, boss)) do
				if not IsHeader(row) then table.insert(rawRows, row) end
			end
		end
	end
	for _, tableId in ipairs(boss.sharedLoot or {}) do
		local tableData = Registry:GetLootTable(tableId)
		if tableData then
			for _, row in ipairs(tableData.rows) do
				if not IsHeader(row) then table.insert(rawRows, row) end
			end
		end
	end

	frame.title:SetText(T("LOOT_TITLE", boss.name or T("UNKNOWN_BOSS")))

	local shown = 0
	local desiredWidth = BASE_WIDTH
	for _, raw in ipairs(rawRows) do
		local item = ParseLootRow(raw)
		if item then
			shown = shown + 1
			if shown > MAX_ROWS then break end
			local row = frame.rows[shown]
			row.item = item
			row.icon:SetTexture(item.icon)
			row.name:SetText(item.name)
			row.extra:SetText(item.extra)
			row.drop:SetText(item.drop or "")
			row.hover:Hide()
			row:Show()
			if row.name.GetStringWidth then
				desiredWidth = math.max(desiredWidth, row.name:GetStringWidth() + 92)
			end
		end
	end

	for i = shown + 1, MAX_ROWS do
		local row = frame.rows[i]
		row.item = nil
		row.icon:SetTexture(nil)
		row.name:SetText("")
		row.extra:SetText("")
		row.drop:SetText("")
		row:Hide()
	end

	if shown == 0 then
		frame.empty:SetText(T("NO_LOOT"))
		frame.empty:Show()
	else
		frame.empty:Hide()
	end

	frame:SetWidth(U.Clamp(desiredWidth, BASE_WIDTH, MAX_WIDTH))
	frame:SetHeight(math.max(78, 46 + (math.max(shown, 1) * (ROW_HEIGHT + 1))))
	self:Position(anchor, boundsFrame)
	frame:Show()
	return true
end

function LootPanel:Position(anchor, boundsFrame)
	local frame = self.frame
	if not frame then return end

	frame:ClearAllPoints()
	if EDG.Overlay and EDG.Overlay.frame and EDG.Overlay.frame.mapArea then
		frame:SetPoint("TOPLEFT", EDG.Overlay.frame.mapArea, "TOPLEFT", 10, -10)
		return
	end

	frame:SetPoint("TOPLEFT", anchor, "TOPRIGHT", 8, 2)

	if not boundsFrame or not boundsFrame.GetRight then return end
	frame:Show()
	local right = frame:GetRight()
	local bottom = frame:GetBottom()
	local boundsRight = boundsFrame:GetRight()
	local boundsBottom = boundsFrame:GetBottom()

	frame:ClearAllPoints()
	local xOffset = 8
	local yOffset = 2
	if right and boundsRight and right > boundsRight then
		xOffset = -(frame:GetWidth() + 8)
		frame:SetPoint("TOPRIGHT", anchor, "TOPLEFT", xOffset, yOffset)
	else
		frame:SetPoint("TOPLEFT", anchor, "TOPRIGHT", xOffset, yOffset)
	end

	if bottom and boundsBottom and bottom < boundsBottom then
		frame:ClearAllPoints()
		frame:SetPoint("BOTTOMLEFT", boundsFrame, "BOTTOMLEFT", 12, 12)
	end
end
