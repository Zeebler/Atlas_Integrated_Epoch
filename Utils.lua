AtlasIntegratedEpoch = AtlasIntegratedEpoch or {}
local EDG = AtlasIntegratedEpoch

local defaultLocale = {
	BOSSES = "Bosses",
	COMPACT_BOSS_LIST_OFF = "Boss list will stay visible on minimized map.",
	COMPACT_BOSS_LIST_ON = "Boss list will hide on minimized map.",
	CURRENT_ZONE = "Current Zone",
	CURRENT_ZONE_DUNGEON = "Current Zone: %s",
	DUNGEON = "Dungeon",
	DUNGEON_MENU_HEADER = "Dungeons",
	DUNGEON_MENU_RESET = "Dungeon menu set to Current Zone.",
	AMBIGUOUS_DUNGEON_TITLE = "Select Dungeon Map",
	AMBIGUOUS_DUNGEON_BODY = "This instance does not report which wing you are in. Choose a map to continue.",
	ENABLED = "Enabled.",
	DISABLED = "Disabled.",
	HIDE_BOSS_LIST_OPTION = "Hide boss list when the world map is minimized",
	LIVE_POSITIONS_UNAVAILABLE = "Live player positions are not available on dungeon maps.",
	LOOT_TITLE = "Loot - %s",
	NO_LOOT = "No loot registered for this boss.",
	OPTIONS_PANEL_TITLE = "Atlas Integrated Epoch",
	PREVIOUS = "Previous",
	NEXT = "Next",
	SLASH_HELP = "/aie, /edg, /edg on, /edg off, /edg debug, /edg where, /edg compactbosslist, /edg options",
	TRASH = "Trash",
	UNKNOWN_BOSS = "Boss",
	UNKNOWN_ITEM = "Unknown",
}

EDG.L = EDG.L or {}
for key, value in pairs(defaultLocale) do
	if rawget(EDG.L, key) == nil then
		EDG.L[key] = value
	end
end

setmetatable(EDG.L, {
	__index = function(_, key)
		return key
	end,
})

EDG.Locale = EDG.Locale or {}

EDG.Utils = {}
local U = EDG.Utils

function EDG.Locale.Get(key, ...)
	local value = EDG.L and EDG.L[key] or key
	if select("#", ...) > 0 then
		return string.format(value, ...)
	end
	return value
end

function U.CopyDefaults(src, dst)
	if type(dst) ~= "table" then dst = {} end
	for k, v in pairs(src or {}) do
		if type(v) == "table" then
			dst[k] = U.CopyDefaults(v, dst[k])
		elseif dst[k] == nil then
			dst[k] = v
		end
	end
	return dst
end

function U.StripColors(text)
	if not text then return "" end
	text = string.gsub(text, "|c%x%x%x%x%x%x%x%x", "")
	text = string.gsub(text, "|r", "")
	return text
end

function U.Trim(text)
	text = text or ""
	text = string.gsub(text, "^%s+", "")
	text = string.gsub(text, "%s+$", "")
	return text
end

function U.CleanMarkup(text)
	text = U.StripColors(text or "")
	if AtlasLoot_FixText then
		text = AtlasLoot_FixText(text)
	end
	text = string.gsub(text, "=q%d=", "")
	text = string.gsub(text, "=ds=", "")
	text = string.gsub(text, "#[%w%d_]+#", "")
	return U.Trim(text)
end

function U.NameKey(text)
	text = string.lower(U.CleanMarkup(text or ""))
	text = string.gsub(text, "%s*%b()", "")
	text = string.gsub(text, "^the%s+", "")
	text = string.gsub(text, "[^%w]+", "")
	return text
end

function U.Clamp(value, minValue, maxValue)
	if value < minValue then return minValue end
	if value > maxValue then return maxValue end
	return value
end

function U.GetInstanceName()
	if GetInstanceInfo then
		local name = GetInstanceInfo()
		return name
	end
	return nil
end

function U.IsInDungeon()
	if not IsInInstance then return false end
	local inInstance, instanceType = IsInInstance()
	return inInstance and (instanceType == "party" or instanceType == "raid")
end

function U.GetMapParent()
	return WorldMapButton or WorldMapFrame
end

function U.IsWorldMapMinimized()
	if WORLDMAP_SETTINGS and WORLDMAP_WINDOWED_SIZE and WORLDMAP_SETTINGS.size == WORLDMAP_WINDOWED_SIZE then
		return true
	end
	if WorldMapFrameSizeUpButton and WorldMapFrameSizeUpButton.IsShown and WorldMapFrameSizeUpButton:IsShown() then
		return true
	end
	return false
end

function U.GetElvUIEngine()
	local engine = E
	if not engine and ElvUI then
		local ok, unpacked = pcall(function() return unpack(ElvUI) end)
		if ok then engine = unpacked end
	end
	return engine
end

function U.IsElvUIWorldMapSkinEnabled()
	local engine = U.GetElvUIEngine()
	return engine
		and engine.private
		and engine.private.skins
		and engine.private.skins.blizzard
		and engine.private.skins.blizzard.enable
		and engine.private.skins.blizzard.worldmap
end

function U.SkinDropDownBox(frame, width)
	if not frame or frame.atlasIntegratedEpochElvUISkinned or not U.IsElvUIWorldMapSkinEnabled() then return false end

	local engine = U.GetElvUIEngine()
	local skins = engine and engine.GetModule and engine:GetModule("Skins", true)
	if skins and skins.HandleDropDownBox then
		local ok = pcall(function()
			skins:HandleDropDownBox(frame, width)
		end)
		if ok then
			frame.atlasIntegratedEpochElvUISkinned = true
			return true
		end
	end

	return false
end
