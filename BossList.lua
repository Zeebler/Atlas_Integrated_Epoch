AtlasIntegratedEpoch = AtlasIntegratedEpoch or {}
local EDG = AtlasIntegratedEpoch
local T = EDG.Locale.Get

EDG.BossList = {}
local BossList = EDG.BossList

local MAX_ROWS = 28
local ROW_HEIGHT = 18
local WRAPPED_ROW_HEIGHT = 36
local NUMBER_WIDTH = 18
local NUMBER_GAP = 4
local SUB_LINE_HEIGHT = 12
local LOOT_TEXT_R, LOOT_TEXT_G, LOOT_TEXT_B = 0.52, 0.74, 1

local function BossHasLoot(boss)
	return boss
		and (
			(boss.loot and table.getn(boss.loot) > 0)
			or (boss.sharedLoot and table.getn(boss.sharedLoot) > 0)
		)
end

local function SplitBossDisplay(text)
	text = text or ""
	local number, name = string.match(text, "^%s*([^%s]+[%).])%s+(.+)$")
	if number and name then
		return number, name
	end
	return nil, text
end

local function BuildSubBossText(boss)
	if not boss or not boss.showSubBossSummary or not boss.subBosses or table.getn(boss.subBosses) == 0 then return nil end
	local names = {}
	for _, subBoss in ipairs(boss.subBosses) do
		local name = subBoss.displayName or subBoss.name
		if name and name ~= "" then
			table.insert(names, name)
		end
	end
	if table.getn(names) == 0 then return nil end
	return table.concat(names, ", ")
end

local function GetNumberWidth(number)
	if not number or number == "" then return 0 end
	return math.max(string.len(number) * 8, NUMBER_WIDTH)
end

local function GetTextWidth(frame, number)
	local rowWidth = math.max((frame and frame.GetWidth and frame:GetWidth() or 220) - 4, 120)
	local numberWidth = GetNumberWidth(number)
	local reserved = numberWidth > 0 and (numberWidth + NUMBER_GAP + 6) or 10
	return math.max(rowWidth - reserved, 80)
end

local function WrapText(text, textWidth)
	text = string.gsub(text or "", "%s+", " ")
	text = string.gsub(text, "^%s+", "")
	text = string.gsub(text, "%s+$", "")
	if text == "" then return "", 1 end

	local charsPerLine = math.max(math.floor((textWidth or 178) / 6), 10)
	local lines = {}
	local line = ""

	for word in string.gmatch(text, "%S+") do
		while string.len(word) > charsPerLine do
			if line ~= "" then
				table.insert(lines, line)
				line = ""
			end
			table.insert(lines, string.sub(word, 1, charsPerLine))
			word = string.sub(word, charsPerLine + 1)
		end

		if line == "" then
			line = word
		elseif string.len(line) + 1 + string.len(word) <= charsPerLine then
			line = line.." "..word
		else
			table.insert(lines, line)
			line = word
		end
	end

	if line ~= "" then
		table.insert(lines, line)
	end

	return table.concat(lines, "\n"), math.max(table.getn(lines), 1)
end

local function GetMeasuredTextHeight(fontString, fallbackLines, lineHeight)
	local height
	if fontString and fontString.GetStringHeight then
		height = fontString:GetStringHeight()
	end
	if height and height > 0 then
		return math.ceil(height) + 4
	end
	return math.max(fallbackLines or 1, 1) * (lineHeight or ROW_HEIGHT)
end

local function EstimateBossHeight(frame, boss)
	if not boss then return ROW_HEIGHT end

	local text = boss.displayName or boss.name or boss.id or T("UNKNOWN_BOSS")
	local number, name = SplitBossDisplay(text)
	local displayNumber = boss.isChildEncounter and (boss.parentDisplayNumber or "") or boss.displayNumber or number or ""
	local textWidth = GetTextWidth(frame, displayNumber)
	local _, mainLines = WrapText(name or text, textWidth)
	local mainHeight = math.max(mainLines, 1) * ROW_HEIGHT + 2
	local subText = BuildSubBossText(boss)
	local subHeight = 0
	if subText then
		local _, subLines = WrapText(subText, textWidth)
		subHeight = subLines * SUB_LINE_HEIGHT + 4
	end

	return mainHeight + subHeight
end

local function GetListHeight(frame)
	local height = frame and frame.GetHeight and frame:GetHeight() or 0
	return math.max(height - 80, ROW_HEIGHT)
end

local function BuildPages(frame, bosses)
	local pages = { 1 }
	local available = GetListHeight(frame)
	local used = 0
	local rows = 0

	for index, boss in ipairs(bosses or {}) do
		local rowHeight = EstimateBossHeight(frame, boss)
		if rows > 0 and (used + rowHeight > available or rows >= MAX_ROWS) then
			table.insert(pages, index)
			used = 0
			rows = 0
		end
		used = used + rowHeight
		rows = rows + 1
	end

	return pages
end

function BossList:Create(parent)
	if self.frame then return self.frame end

	local frame = CreateFrame("Frame", "AtlasIntegratedEpochBossList", parent)
	frame:SetWidth(230)
	frame:SetFrameLevel(parent:GetFrameLevel() + 20)
	frame:SetFrameStrata(parent:GetFrameStrata() or "FULLSCREEN_DIALOG")
	frame:EnableMouse(true)

	frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
	frame.title:SetText(T("BOSSES"))

	frame.rows = {}
	for i = 1, MAX_ROWS do
		local row = CreateFrame("Button", "AtlasIntegratedEpochBossRow"..i, frame)
		row:SetFrameLevel(frame:GetFrameLevel() + 5)
		row:EnableMouse(true)
		row:SetHeight(ROW_HEIGHT)
		row:SetPoint("LEFT", frame, "LEFT", 2, 0)
		row:SetPoint("RIGHT", frame, "RIGHT", -2, 0)
		row:RegisterForClicks("LeftButtonUp")
		if i == 1 then
			row:SetPoint("TOP", frame, "TOP", 0, -22)
		else
			row:SetPoint("TOP", frame.rows[i - 1], "BOTTOM", 0, 0)
		end
		row.highlight = row:CreateTexture(nil, "BACKGROUND")
		row.highlight:SetPoint("TOPLEFT", row, "TOPLEFT", 1, -1)
		row.highlight:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -1, 1)
		row.highlight:SetTexture(1, 0.82, 0, 0.15)
		row.highlight:Hide()

		row.number = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		row.number:SetPoint("TOPLEFT", row, "TOPLEFT", 4, -2)
		row.number:SetWidth(NUMBER_WIDTH)
		row.number:SetHeight(ROW_HEIGHT)
		row.number:SetJustifyH("LEFT")
		row.number:SetJustifyV("TOP")

		row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		row.text:SetPoint("TOPLEFT", row.number, "TOPRIGHT", NUMBER_GAP, 0)
		row.text:SetJustifyH("LEFT")
		row.text:SetJustifyV("TOP")
		row.text:SetWidth(178)
		row.text:SetHeight(WRAPPED_ROW_HEIGHT - 4)
		if row.text.SetWordWrap then row.text:SetWordWrap(true) end
		if row.text.SetNonSpaceWrap then row.text:SetNonSpaceWrap(false) end
		if row.text.SetIndentedWordWrap then row.text:SetIndentedWordWrap(false) end

		row.subText = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
		row.subText:SetPoint("TOPLEFT", row.text, "BOTTOMLEFT", 0, -1)
		row.subText:SetJustifyH("LEFT")
		row.subText:SetJustifyV("TOP")
		row.subText:SetWidth(178)
		row.subText:SetHeight(SUB_LINE_HEIGHT)
		if row.subText.SetWordWrap then row.subText:SetWordWrap(true) end
		if row.subText.SetNonSpaceWrap then row.subText:SetNonSpaceWrap(false) end

		row:SetScript("OnEnter", function(button)
			button.hovered = true
			if not BossHasLoot(button.boss) then return end
			if button.number then button.number:SetTextColor(1, 0.82, 0) end
			if button.text then button.text:SetTextColor(1, 0.82, 0) end
		end)
		row:SetScript("OnLeave", function(button)
			button.hovered = nil
			BossList:RefreshRowStyle(button)
		end)
		row:SetScript("OnClick", function(button)
			if not BossHasLoot(button.boss) then return end
			EDG.Overlay:SelectBoss(button.boss, button)
		end)
		row:Hide()
		frame.rows[i] = row
	end

	frame.pager = CreateFrame("Frame", nil, frame)
	frame.pager:SetFrameLevel(frame:GetFrameLevel() + 5)
	frame.pager:EnableMouse(true)
	frame.pager:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 10, 10)
	frame.pager:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -10, 10)
	frame.pager:SetHeight(22)
	frame.pager:Hide()

	frame.pager.prev = CreateFrame("Button", "AtlasIntegratedEpochBossPrev", frame.pager, "UIPanelButtonTemplate")
	frame.pager.prev:SetFrameLevel(frame.pager:GetFrameLevel() + 2)
	frame.pager.prev:SetWidth(74)
	frame.pager.prev:SetHeight(20)
	frame.pager.prev:SetPoint("LEFT", frame.pager, "LEFT", 0, 0)
	frame.pager.prev:SetText(T("PREVIOUS"))
	frame.pager.prev:SetScript("OnClick", function()
		BossList.page = math.max((BossList.page or 1) - 1, 1)
		BossList:Refresh()
		EDG.LootPanel:Hide()
	end)

	frame.pager.next = CreateFrame("Button", "AtlasIntegratedEpochBossNext", frame.pager, "UIPanelButtonTemplate")
	frame.pager.next:SetFrameLevel(frame.pager:GetFrameLevel() + 2)
	frame.pager.next:SetWidth(54)
	frame.pager.next:SetHeight(20)
	frame.pager.next:SetPoint("RIGHT", frame.pager, "RIGHT", 0, 0)
	frame.pager.next:SetText(T("NEXT"))
	frame.pager.next:SetScript("OnClick", function()
		local maxPage = table.getn(BossList.pageStarts or { 1 })
		BossList.page = math.min((BossList.page or 1) + 1, maxPage)
		BossList:Refresh()
		EDG.LootPanel:Hide()
	end)

	frame.pager.text = frame.pager:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	frame.pager.text:SetPoint("CENTER", frame.pager, "CENTER", 0, 0)

	self.frame = frame
	self.page = 1
	return frame
end

function BossList:SetBosses(bosses)
	self.bosses = bosses or {}
	self.page = 1
	self.selectedBoss = nil
	self:Refresh()
end

function BossList:SetSelected(boss)
	self.selectedBoss = boss
	self:RefreshHighlights()
end

function BossList:Refresh()
	if not self.frame then return end
	local bosses = self.bosses or {}
	local total = table.getn(bosses)
	self.pageStarts = BuildPages(self.frame, bosses)
	local maxPage = math.max(table.getn(self.pageStarts), 1)
	self.page = math.min(math.max(self.page or 1, 1), maxPage)
	local startIndex = self.pageStarts[self.page] or 1
	local nextStart = self.pageStarts[self.page + 1] or (total + 1)

	local previousVisibleRow
	for i = 1, MAX_ROWS do
		local row = self.frame.rows[i]
		local bossIndex = startIndex + i - 1
		local boss = bossIndex < nextStart and bosses[bossIndex] or nil
		if boss then
			row.boss = boss
			local text = boss.displayName or boss.name or boss.id or T("UNKNOWN_BOSS")
			local number, name = SplitBossDisplay(text)
			local subText = BuildSubBossText(boss)
			local displayNumber = boss.isChildEncounter and (boss.parentDisplayNumber or "") or boss.displayNumber or number or ""
			row.number:SetText(boss.isChildEncounter and "" or displayNumber)
			local numberWidth = GetNumberWidth(displayNumber)
			row.number:SetWidth(numberWidth)
			row.text:ClearAllPoints()
			if numberWidth > 0 then
				row.text:SetPoint("TOPLEFT", row.number, "TOPRIGHT", NUMBER_GAP, 0)
			else
				row.text:SetPoint("TOPLEFT", row, "TOPLEFT", 4, -2)
			end

			local textWidth = GetTextWidth(self.frame, displayNumber)
			local displayName = name or text
			local wrappedName, wrappedNameLines = WrapText(displayName, textWidth)
			local wrappedSubText, wrappedSubLines = WrapText(subText or "", textWidth)
			row.text:SetText(wrappedName)
			row.subText:SetText(wrappedSubText)
			row.text:SetWidth(textWidth)
			row.subText:SetWidth(textWidth)
			row.text:SetHeight(WRAPPED_ROW_HEIGHT - 4)
			row.number:SetHeight(WRAPPED_ROW_HEIGHT - 4)

			local mainLines = wrappedNameLines
			local mainHeight = GetMeasuredTextHeight(row.text, mainLines, ROW_HEIGHT)
			local subHeight = 0
			if subText then
				subHeight = GetMeasuredTextHeight(row.subText, wrappedSubLines, SUB_LINE_HEIGHT) + 2
				row.subText:SetHeight(subHeight)
				row.subText:Show()
			else
				row.subText:Hide()
			end
			local rowHeight = mainHeight + subHeight
			row:SetHeight(rowHeight)
			row.text:SetHeight(mainHeight)
			row.number:SetHeight(rowHeight - 4)

			row:ClearAllPoints()
			row:SetPoint("LEFT", self.frame, "LEFT", 2, 0)
			row:SetPoint("RIGHT", self.frame, "RIGHT", -2, 0)
			if previousVisibleRow then
				row:SetPoint("TOP", previousVisibleRow, "BOTTOM", 0, 0)
			else
				row:SetPoint("TOP", self.frame, "TOP", 0, -22)
			end
			row:Show()
			previousVisibleRow = row
		else
			row.boss = nil
			row.number:SetText("")
			row.text:SetText("")
			row.subText:SetText("")
			row.subText:Hide()
			row:Hide()
		end
	end

	if maxPage > 1 then
		self.frame.pager.text:SetText(self.page.." / "..maxPage)
		self.frame.pager:Show()
		if self.page <= 1 then
			self.frame.pager.prev:Disable()
		else
			self.frame.pager.prev:Enable()
		end
		if self.page >= maxPage then
			self.frame.pager.next:Disable()
		else
			self.frame.pager.next:Enable()
		end
	else
		self.frame.pager:Hide()
	end

	self:RefreshHighlights()
end

function BossList:RefreshRowStyle(row)
	if not row then return end
	local selected = row.boss and self.selectedBoss and row.boss.id == self.selectedBoss.id
	row.selected = selected
	if row.highlight then
		if selected then row.highlight:Show() else row.highlight:Hide() end
	end
	if row.text then
		if row.hovered and BossHasLoot(row.boss) then
			if row.number then row.number:SetTextColor(1, 0.82, 0) end
			row.text:SetTextColor(1, 0.82, 0)
		elseif selected then
			if row.number then row.number:SetTextColor(1, 0.82, 0) end
			row.text:SetTextColor(1, 0.82, 0)
		elseif BossHasLoot(row.boss) then
			if row.number then row.number:SetTextColor(LOOT_TEXT_R, LOOT_TEXT_G, LOOT_TEXT_B) end
			row.text:SetTextColor(LOOT_TEXT_R, LOOT_TEXT_G, LOOT_TEXT_B)
		else
			if row.number then row.number:SetTextColor(1, 1, 1) end
			row.text:SetTextColor(1, 1, 1)
		end
	end
end

function BossList:RefreshHighlights()
	if not self.frame then return end
	for _, row in ipairs(self.frame.rows) do
		self:RefreshRowStyle(row)
	end
end
