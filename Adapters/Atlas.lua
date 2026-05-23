AtlasIntegratedEpoch = AtlasIntegratedEpoch or {}
local EDG = AtlasIntegratedEpoch

local U = EDG.Utils
local Registry = EDG.DataRegistry

EDG.AtlasAdapter = {}
local Adapter = EDG.AtlasAdapter

local aliases = {
	stockade = "TheStockade",
	stockades = "TheStockade",
	thestockade = "TheStockade",
	thestockades = "TheStockade",
	stormwindstockade = "TheStockade",
	stormwindstockades = "TheStockade",
	armory = "SMArmory",
	sarmory = "SMArmory",
	scarletarmory = "SMArmory",
	scarletmonasteryarmory = "SMArmory",
	cathedral = "SMCathedral",
	cath = "SMCathedral",
	scarletcathedral = "SMCathedral",
	scarletmonasterycathedral = "SMCathedral",
	graveyard = "SMGraveyard",
	gy = "SMGraveyard",
	scarletgraveyard = "SMGraveyard",
	scarletmonasterygraveyard = "SMGraveyard",
	library = "SMLibrary",
	lib = "SMLibrary",
	scarletlibrary = "SMLibrary",
	scarletmonasterylibrary = "SMLibrary",
}

local excludedAtlasMapIds

local function BuildExcludedAtlasMapIds()
	if excludedAtlasMapIds then return excludedAtlasMapIds end

	excludedAtlasMapIds = {}

	if ATLAS_PLUGINS and ATLAS_PLUGIN_DATA then
		for index, pluginName in pairs(ATLAS_PLUGINS) do
			local category = Atlas_MapTypes and Atlas_MapTypes[index] or ""
			local key = string.lower(U.StripColors((pluginName or "").." "..(category or "")))
			if string.find(key, "outdoor")
				or string.find(key, "world boss")
				or string.find(key, "worldboss")
				or string.find(key, "dungeonloc")
				or string.find(key, "dungeon loc")
				or string.find(key, "dungeon locations")
				or string.find(key, "battleground")
				or string.find(key, "pvp")
				or string.find(key, "arena")
			then
				for mapId in pairs(ATLAS_PLUGIN_DATA[index] or {}) do
					excludedAtlasMapIds[mapId] = true
				end
			end
		end
	end

	return excludedAtlasMapIds
end

local function TextureExists(owner, path)
	if not owner.probeTexture then
		owner.probeTexture = UIParent:CreateTexture(nil, "BACKGROUND")
	end
	return owner.probeTexture:SetTexture(path)
end

local function GetTexturePath(id)
	local path = "Interface\\AddOns\\Atlas\\Images\\Maps\\"..id
	if TextureExists(Adapter, path) then return path end

	if ATLAS_PLUGINS then
		for _, pluginName in pairs(ATLAS_PLUGINS) do
			path = "Interface\\AddOns\\"..pluginName.."\\Images\\"..id
			if TextureExists(Adapter, path) then return path end
		end
	end
end

local function IsBossLine(text)
	text = U.StripColors(text or "")
	return string.find(text, "^%s*%d+['%.%)]") ~= nil
end

local function IsSubBossLine(line)
	if type(line) ~= "table" or not line[1] then return false end
	if IsBossLine(line[1]) then return false end
	return line[2] == 2 or line[2] == 4
end

local function CleanBossName(text)
	text = U.CleanMarkup(text)
	text = string.gsub(text, "^%s*[%dXx']+[%).]%s*", "")
	text = string.gsub(text, "^%s*[A-Z]%)%s*", "")
	text = string.gsub(text, "%s*%b()", "")
	text = string.gsub(text, "%s*<.->", "")
	return U.Trim(text)
end

local function CleanDisplayName(text)
	text = U.CleanMarkup(text)
	text = string.gsub(text, "^%s*[%dXx']+[%).]%s*", "")
	text = string.gsub(text, "^%s*[A-Z]%)%s*", "")
	text = string.gsub(text, "%s+", " ")
	return U.Trim(text)
end

local function IsDungeonMap(id, zoneName, bosses)
	if not id or not zoneName then return false end
	if BuildExcludedAtlasMapIds()[id] then return false end
	local lowerId = string.lower(id)
	local lowerZone = string.lower(U.StripColors(zoneName))
	if string.find(lowerId, "azuregos")
		or string.find(lowerId, "kazzak")
		or string.find(lowerId, "outdoor")
		or string.find(lowerId, "battleground")
		or string.find(lowerId, "pvp")
		or string.find(lowerId, "arena")
		or lowerZone == "kalimdor"
		or lowerZone == "eastern kingdoms"
	then
		return false
	end
	if string.find(id, "Ent$") then return false end
	if string.find(lowerZone, "%(entrance%)") then return false end
	if not bosses or table.getn(bosses) == 0 then return false end
	return true
end

local function NormalizeBossNumbers(bosses)
	local count = 0
	local currentNumber

	for _, boss in ipairs(bosses or {}) do
		if boss.isChildEncounter then
			boss.displayNumber = nil
			boss.parentDisplayNumber = currentNumber
		else
			count = count + 1
			currentNumber = count..")"
			boss.displayNumber = currentNumber
		end
	end
end

function Adapter:Load()
	if self.loaded then return end
	self.loaded = true

	if not AtlasMaps then
		EDG.Debug.Trace("Atlas data unavailable.")
		return
	end

	for id, data in pairs(AtlasMaps) do
		local zoneName = data.ZoneName and data.ZoneName[1]
		local texture = GetTexturePath(id)
		if zoneName and texture then
			local bosses = {}
			local currentBoss
			for i = 1, table.getn(data) do
				local line = data[i]
				if type(line) == "table" and line[1] and IsBossLine(line[1]) then
					local bossId = id.."_boss_"..i
					currentBoss = {
						id = bossId,
						name = CleanBossName(line[1]),
						displayName = CleanDisplayName(line[1]),
						displayNumber = nil,
						floor = id.."_floor_1",
						loot = {},
						subBosses = {},
						atlasLine = i,
					}
					table.insert(bosses, currentBoss)
				elseif currentBoss and IsSubBossLine(line) then
					local child = {
						id = id.."_boss_"..i,
						name = CleanBossName(line[1]),
						displayName = CleanDisplayName(line[1]),
						parentBossId = currentBoss.id,
						parentName = currentBoss.name,
						parentDisplayNumber = currentBoss.displayNumber,
						isChildEncounter = true,
						floor = id.."_floor_1",
						loot = {},
						atlasLine = i,
					}
					table.insert(currentBoss.subBosses, child)
					table.insert(bosses, child)
				end
			end

			if IsDungeonMap(id, zoneName, bosses) then
				NormalizeBossNumbers(bosses)
				local instanceKeys = { zoneName, id }
				for alias, aliasId in pairs(aliases) do
					if aliasId == id then
						table.insert(instanceKeys, alias)
					end
				end

				Registry:RegisterDungeon({
					id = id,
					name = U.StripColors(zoneName),
					instanceKeys = instanceKeys,
					floors = {
						{
							id = id.."_floor_1",
							name = U.StripColors(zoneName),
							texture = texture,
						},
					},
					bosses = bosses,
					atlasMapId = id,
				}, "Atlas")
			end
		end
	end

	EDG.Debug.Trace("Atlas adapter registered "..table.getn(Registry.dungeonList).." maps.")
end
