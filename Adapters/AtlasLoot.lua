AtlasIntegratedEpoch = AtlasIntegratedEpoch or {}
local EDG = AtlasIntegratedEpoch
local T = EDG.Locale.Get

local U = EDG.Utils
local Registry = EDG.DataRegistry

EDG.AtlasLootAdapter = {}
local Adapter = EDG.AtlasLootAdapter

local function EnsureLoaded()
	if LoadAddOn then
		if not AtlasLoot_Data then LoadAddOn("AtlasLoot") end
		if not AtlasLoot_Data or not AtlasLoot_TableNames then LoadAddOn("AtlasLoot_OriginalWoW") end
	end
end

local function GetLootPage(mapId, lineIndex)
	local sources = { AtlasLootBossButtons, AtlasLootWBBossButtons }
	for _, source in ipairs(sources) do
		if source and source[mapId] and source[mapId][lineIndex] and source[mapId][lineIndex] ~= "" then
			return source[mapId][lineIndex]
		end
	end
end

local function IsTrashLootPage(page)
	if not page or page == "" then return false end

	local pageKey = string.lower(tostring(page))
	if string.find(pageKey, "trash") then return true end

	local metadata = AtlasLoot_TableNames and AtlasLoot_TableNames[page]
	local title = type(metadata) == "table" and metadata[1] or metadata
	if title and U then
		local titleKey = string.lower(U.StripColors(U.CleanMarkup(tostring(title))))
		if string.find(titleKey, "trash mobs", 1, true) or string.find(titleKey, "trash", 1, true) then
			return true
		end
	end

	return false
end

local function AddUniquePage(pages, seen, page)
	if not page or page == "" or seen[page] then return end
	if not AtlasLoot_Data or not AtlasLoot_Data[page] then return end
	seen[page] = true
	table.insert(pages, page)
end

local function GetTrashLootPages(mapId)
	local pages = {}
	local seen = {}
	local sources = { AtlasLootBossButtons, AtlasLootWBBossButtons }

	for _, source in ipairs(sources) do
		local mapPages = source and source[mapId]
		if mapPages then
			for _, page in pairs(mapPages) do
				if IsTrashLootPage(page) then
					AddUniquePage(pages, seen, page)
				end
			end
		end
	end

	return pages
end

local function AddTrashLootEntry(dungeon, pages)
	if not dungeon or not dungeon.bosses or not pages or table.getn(pages) == 0 then return end

	local lootPages = {}
	for _, page in ipairs(pages) do
		table.insert(lootPages, page)
	end
	if table.getn(lootPages) == 0 then return end

	for _, boss in ipairs(dungeon.bosses) do
		if boss.isTrashLoot then
			boss.loot = lootPages
			return
		end
	end

	local floor = Registry:GetDefaultFloor(dungeon)
	table.insert(dungeon.bosses, {
		id = dungeon.id.."_trash",
		name = T("TRASH"),
		displayName = T("TRASH"),
		floor = floor and floor.id,
		loot = lootPages,
		isTrashLoot = true,
	})
end

function Adapter:Load()
	if self.loaded then return end
	self.loaded = true
	EnsureLoaded()

	if not AtlasLoot_Data then
		EDG.Debug.Trace("AtlasLoot data unavailable.")
		return
	end

	for _, dungeon in ipairs(Registry.dungeonList or {}) do
		local mapId = dungeon.atlasMapId
		if mapId and dungeon.bosses then
			for _, boss in ipairs(dungeon.bosses) do
				local page = GetLootPage(mapId, boss.atlasLine)
				if page and AtlasLoot_Data[page] then
					Registry:RegisterLootTable(page, AtlasLoot_Data[page], AtlasLoot_TableNames and AtlasLoot_TableNames[page])
					if IsTrashLootPage(page) then
						boss.loot = {}
					else
						boss.loot = { page }
					end
				end
			end

			local trashPages = GetTrashLootPages(mapId)
			for _, page in ipairs(trashPages) do
				Registry:RegisterLootTable(page, AtlasLoot_Data[page], AtlasLoot_TableNames and AtlasLoot_TableNames[page])
			end
			AddTrashLootEntry(dungeon, trashPages)
		end
	end

	EDG.Debug.Trace("AtlasLoot adapter linked loot tables.")
end
