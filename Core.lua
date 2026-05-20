local ADDON_NAME = ...
AtlasIntegratedEpoch = AtlasIntegratedEpoch or {}
local EDG = AtlasIntegratedEpoch
local T = EDG.Locale.Get

local defaults = {
	enabled = true,
	debug = false,
	selectedDungeon = nil,
	hideBossListWhenMinimized = true,
}

EDG.Core = CreateFrame("Frame", "AtlasIntegratedEpochCore")
EDG.Core:RegisterEvent("ADDON_LOADED")
EDG.Core:SetScript("OnEvent", function(self, event, ...)
	if self[event] then self[event](self, ...) end
end)

function EDG:RegisterDungeon(definition)
	return EDG.DataRegistry:RegisterDungeon(definition, "native")
end

function EDG:RegisterLootTable(id, rows, metadata)
	return EDG.DataRegistry:RegisterLootTable(id, rows, metadata)
end

local function RefreshOptionsPanel()
	if not EDG.optionsPanel or not EDG.optionsPanel.hideBossListCheck then return end
	EDG.optionsPanel.hideBossListCheck:SetChecked(AtlasIntegratedEpochDB and AtlasIntegratedEpochDB.hideBossListWhenMinimized)
end

local function CreateOptionsPanel()
	if EDG.optionsPanel or not InterfaceOptions_AddCategory then return end

	local panel = CreateFrame("Frame", "AtlasIntegratedEpochOptionsPanel", InterfaceOptionsFramePanelContainer or UIParent)
	panel.name = T("OPTIONS_PANEL_TITLE")

	local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 16, -16)
	title:SetText(T("OPTIONS_PANEL_TITLE"))

	local hideBossList = CreateFrame("CheckButton", "AtlasIntegratedEpochHideBossListWhenMinimized", panel, "InterfaceOptionsCheckButtonTemplate")
	hideBossList:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -18)
	local hideBossListText = hideBossList.Text or getglobal(hideBossList:GetName().."Text")
	if hideBossListText then
		hideBossListText:SetText(T("HIDE_BOSS_LIST_OPTION"))
	end
	hideBossList:SetScript("OnClick", function(button)
		AtlasIntegratedEpochDB.hideBossListWhenMinimized = button:GetChecked() and true or false
		if EDG.Overlay then EDG.Overlay:RefreshLayout(true) end
	end)

	panel:SetScript("OnShow", RefreshOptionsPanel)
	panel.hideBossListCheck = hideBossList
	EDG.optionsPanel = panel
	InterfaceOptions_AddCategory(panel)
	RefreshOptionsPanel()
end

local function OpenOptionsPanel()
	if not EDG.optionsPanel then
		CreateOptionsPanel()
	end
	if InterfaceOptionsFrame_OpenToCategory and EDG.optionsPanel then
		InterfaceOptionsFrame_OpenToCategory(EDG.optionsPanel)
	end
end

function EDG.Core:ADDON_LOADED(addon)
	if addon ~= ADDON_NAME then return end

	AtlasIntegratedEpochDB = EDG.Utils.CopyDefaults(defaults, AtlasIntegratedEpochDB)

	EDG.AtlasAdapter:Load()
	EDG.AtlasLootAdapter:Load()
	EDG.DungeonMenu:Initialize()
	EDG.MapIntegration:Initialize()
	EDG.Events:Initialize()
	EDG.Overlay:Create()
	CreateOptionsPanel()

	SLASH_ATLASINTEGRATEDEPOCH1 = "/aie"
	SLASH_ATLASINTEGRATEDEPOCH2 = "/atlasintegrated"
	SLASH_ATLASINTEGRATEDEPOCH3 = "/edg"
	SLASH_ATLASINTEGRATEDEPOCH4 = "/epochdungeons"
	SlashCmdList.ATLASINTEGRATEDEPOCH = function(msg)
		msg = string.lower(EDG.Utils.Trim(msg or ""))
		if msg == "debug" then
			EDG.Debug.Toggle()
		elseif msg == "current" or msg == "reset" then
			AtlasIntegratedEpochDB.selectedDungeon = nil
			EDG.DungeonMenu:RefreshText()
			EDG.MapIntegration:Refresh()
			EDG.Debug.Print(T("DUNGEON_MENU_RESET"))
		elseif msg == "on" then
			AtlasIntegratedEpochDB.enabled = true
			EDG.Debug.Print(T("ENABLED"))
			EDG.MapIntegration:Refresh()
		elseif msg == "off" then
			AtlasIntegratedEpochDB.enabled = false
			EDG.Overlay:Hide()
			EDG.Debug.Print(T("DISABLED"))
		elseif msg == "toggle" or msg == "" then
			AtlasIntegratedEpochDB.enabled = not AtlasIntegratedEpochDB.enabled
			EDG.Debug.Print(AtlasIntegratedEpochDB.enabled and T("ENABLED") or T("DISABLED"))
			EDG.MapIntegration:Refresh()
		elseif msg == "compactbosslist" or msg == "minimizedbosslist" then
			AtlasIntegratedEpochDB.hideBossListWhenMinimized = not AtlasIntegratedEpochDB.hideBossListWhenMinimized
			RefreshOptionsPanel()
			if EDG.Overlay then EDG.Overlay:RefreshLayout(true) end
			EDG.Debug.Print(AtlasIntegratedEpochDB.hideBossListWhenMinimized and T("COMPACT_BOSS_LIST_ON") or T("COMPACT_BOSS_LIST_OFF"))
		elseif msg == "options" or msg == "config" then
			OpenOptionsPanel()
		else
			EDG.Debug.Print(T("SLASH_HELP"))
		end
	end

	EDG.Debug.Trace("Initialized.")
end
