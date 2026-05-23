AtlasIntegratedEpoch = AtlasIntegratedEpoch or {}
local EDG = AtlasIntegratedEpoch

local U = EDG.Utils

EDG.DataRegistry = {
	dungeons = {},
	dungeonList = {},
	aliases = {},
	lootTables = {},
}

local Registry = EDG.DataRegistry

--[[
Dungeon schema:
AtlasIntegratedEpoch:RegisterDungeon({
	id = "stableUniqueId",
	name = "Dungeon Name",
	instanceKeys = { "normalizedclientname", "optionalalias" },
	floors = {
		{
			id = "floor1",
			name = "Floor Name",
			texture = "Interface\\AddOns\\YourAddon\\Media\\Maps\\DungeonFloor",
			width = 1000,
			height = 1000,
		},
	},
	bosses = {
		{
			id = "bossId",
			name = "Boss Name",
			floor = "floor1",
			x = 0.42,
			y = 0.58,
			loot = { "lootTableId" },
			sharedLoot = { "explicitSharedLootTableId" },
			isTrashLoot = true, -- optional: unnumbered non-boss loot entry shown at the end of the list
		},
	},
})

Coordinates are normalized 0..1 values. Omit x/y when accurate pin data is not available.
Do not register guessed bosses, item IDs, or Project Epoch content.
]]

function Registry:RegisterDungeon(definition, source)
	if type(definition) ~= "table" or not definition.id or not definition.name then
		return nil
	end

	definition.source = source or definition.source or "native"
	definition.floors = definition.floors or {}
	definition.bosses = definition.bosses or {}
	definition.instanceKeys = definition.instanceKeys or {}

	local idKey = U.NameKey(definition.id)
	local nameKey = U.NameKey(definition.name)
	self.dungeons[definition.id] = definition
	self.aliases[idKey] = definition.id
	self.aliases[nameKey] = definition.id

	for _, alias in ipairs(definition.instanceKeys) do
		local key = U.NameKey(alias)
		if key ~= "" then
			self.aliases[key] = definition.id
		end
	end

	local exists = false
	for _, dungeon in ipairs(self.dungeonList) do
		if dungeon.id == definition.id then
			exists = true
			break
		end
	end
	if not exists then
		table.insert(self.dungeonList, definition)
	end

	table.sort(self.dungeonList, function(a, b)
		return (a.name or a.id) < (b.name or b.id)
	end)

	return definition
end

function Registry:RegisterLootTable(id, rows, metadata)
	if not id or type(rows) ~= "table" then return end
	self.lootTables[id] = {
		id = id,
		rows = rows,
		metadata = metadata or {},
	}
end

function Registry:GetLootTable(id)
	return id and self.lootTables[id]
end

function Registry:GetDungeon(id)
	return id and self.dungeons[id]
end

function Registry:ResolveDungeon(key)
	key = U.NameKey(key)
	local id = self.aliases[key]
	return id and self.dungeons[id]
end

function Registry:ResolveDungeonFromText(text)
	local clean = U.CleanMarkup(text or "")
	local lower = string.lower(clean)

	if string.find(lower, "scarlet monastery", 1, true) then
		if string.find(lower, "armory", 1, true) then
			return self:GetDungeon("SMArmory")
		elseif string.find(lower, "cathedral", 1, true) then
			return self:GetDungeon("SMCathedral")
		elseif string.find(lower, "graveyard", 1, true) then
			return self:GetDungeon("SMGraveyard")
		elseif string.find(lower, "library", 1, true) then
			return self:GetDungeon("SMLibrary")
		end
	end

	return self:ResolveDungeon(clean)
end

function Registry:GetCurrentInstanceKey()
	local candidates = {}
	local function AddCandidate(name)
		if name and name ~= "" then
			table.insert(candidates, name)
		end
	end
	AddCandidate(U.GetInstanceName())
	AddCandidate(GetRealZoneText and GetRealZoneText())
	AddCandidate(GetZoneText and GetZoneText())
	AddCandidate(GetMinimapZoneText and GetMinimapZoneText())

	for _, name in ipairs(candidates) do
		local key = U.NameKey(name)
		if key ~= "" then
			return key, name
		end
	end

	return nil, nil
end

function Registry:GetSharedInstanceNameForDungeon(dungeonId)
	if not dungeonId or not Atlas_SubZoneAssoc then return nil end
	return Atlas_SubZoneAssoc[dungeonId]
end

function Registry:RememberCurrentInstanceChoice(dungeonId)
	if not U.IsInDungeon() then return end

	local sharedName = self:GetSharedInstanceNameForDungeon(dungeonId)
	if not sharedName then return end

	local currentKey = self:GetCurrentInstanceKey()
	if currentKey ~= U.NameKey(sharedName) then return end

	if AtlasIntegratedEpochDB then
		AtlasIntegratedEpochDB.currentInstanceSelectionKey = currentKey
		AtlasIntegratedEpochDB.currentInstanceSelections = AtlasIntegratedEpochDB.currentInstanceSelections or {}
		AtlasIntegratedEpochDB.currentInstanceSelections[currentKey] = dungeonId
	end
end

function Registry:GetRememberedCurrentInstanceDungeon()
	local currentKey = self:GetCurrentInstanceKey()
	if not currentKey or not U.IsInDungeon() then return nil end

	local dungeonId
	if AtlasIntegratedEpochDB
		and AtlasIntegratedEpochDB.currentInstanceSelectionKey == currentKey
		and AtlasIntegratedEpochDB.currentInstanceSelections then
		dungeonId = AtlasIntegratedEpochDB.currentInstanceSelections[currentKey]
	end

	return dungeonId and self:GetDungeon(dungeonId)
end

function Registry:ClearCurrentInstanceChoice()
	if AtlasIntegratedEpochDB then
		AtlasIntegratedEpochDB.currentInstanceSelectionKey = nil
		AtlasIntegratedEpochDB.currentInstanceSelections = {}
	end
end

local function GetAtlasDefaultMapForCurrentInstance()
	local currentKey = Registry:GetCurrentInstanceKey()
	if not currentKey then return nil end

	if Atlas_AssocDefaults then
		for zoneName, mapId in pairs(Atlas_AssocDefaults) do
			if U.NameKey(zoneName) == currentKey then
				return mapId, zoneName
			end
		end
	end

	if Atlas_AssocDefaults_Loc and Atlas_AssocDefaults then
		for zoneName, localizedZoneName in pairs(Atlas_AssocDefaults_Loc) do
			if U.NameKey(localizedZoneName) == currentKey then
				return Atlas_AssocDefaults[zoneName], localizedZoneName
			end
		end
	end

	return nil, nil
end

function Registry:GetAmbiguousCurrentInstanceOptions()
	if not U.IsInDungeon() then return nil end

	local currentKey, currentName = self:GetCurrentInstanceKey()
	if currentKey == "scarletmonastery" then
		local options = {}
		local smMaps = { "SMGraveyard", "SMLibrary", "SMArmory", "SMCathedral" }
		for _, mapId in ipairs(smMaps) do
			local dungeon = self:GetDungeon(mapId)
			if dungeon then
				table.insert(options, dungeon)
			end
		end
		if table.getn(options) > 0 then
			return options, currentName or "Scarlet Monastery"
		end
	end

	local defaultMapId, instanceName = GetAtlasDefaultMapForCurrentInstance()
	if not defaultMapId or not Atlas_MapSeries or not Atlas_MapSeries[defaultMapId] then
		return nil
	end

	local options = {}
	for _, mapId in ipairs(Atlas_MapSeries[defaultMapId]) do
		if mapId ~= defaultMapId then
			local dungeon = self:GetDungeon(mapId)
			if dungeon then
				table.insert(options, dungeon)
			end
		end
	end

	if table.getn(options) == 0 then return nil end
	return options, instanceName
end

local function GetAtlasMapIdForSubZone(subZone)
	if not subZone or subZone == "" then return nil end

	if Atlas_SubZoneData and Atlas_SubZoneData[subZone] then
		return Atlas_SubZoneData[subZone]
	end

	if Atlas_SubZoneData and Atlas_SubZoneData_Loc then
		for atlasSubZone, localizedSubZone in pairs(Atlas_SubZoneData_Loc) do
			if localizedSubZone == subZone then
				return Atlas_SubZoneData[atlasSubZone]
			end
		end
	end

	return nil
end

function Registry:GetDungeonForCurrentInstance()
	local subZone = GetSubZoneText and GetSubZoneText()
	local minimapZone = GetMinimapZoneText and GetMinimapZoneText()
	if subZone and subZone ~= "" then
		local atlasMapId = GetAtlasMapIdForSubZone(subZone)
		local dungeon = atlasMapId and self:GetDungeon(atlasMapId)
		if dungeon then return dungeon end
	end
	if minimapZone and minimapZone ~= "" then
		local atlasMapId = GetAtlasMapIdForSubZone(minimapZone)
		local dungeon = atlasMapId and self:GetDungeon(atlasMapId)
		if dungeon then return dungeon end
	end

	local candidates = {}
	local function AddCandidate(name)
		if name and name ~= "" then
			table.insert(candidates, name)
		end
	end
	AddCandidate(U.GetInstanceName())
	AddCandidate(GetRealZoneText and GetRealZoneText())
	AddCandidate(GetZoneText and GetZoneText())
	AddCandidate(subZone)
	AddCandidate(minimapZone)

	for _, name in ipairs(candidates) do
		local dungeon = self:ResolveDungeonFromText(name)
		if dungeon then return dungeon end
	end

	return self:GetRememberedCurrentInstanceDungeon()
end

function Registry:GetCurrentLocationDebugInfo()
	local subZone = GetSubZoneText and GetSubZoneText() or ""
	local minimapZone = GetMinimapZoneText and GetMinimapZoneText() or ""
	local atlasMapId = GetAtlasMapIdForSubZone(subZone)
	if not atlasMapId or atlasMapId == "" then
		atlasMapId = GetAtlasMapIdForSubZone(minimapZone)
	end
	local dungeon = self:GetDungeonForCurrentInstance()
	local remembered = self:GetRememberedCurrentInstanceDungeon()
	local inInstance, instanceType
	if IsInInstance then
		inInstance, instanceType = IsInInstance()
	end
	local instanceName, instanceKind, difficultyId, difficultyName, maxPlayers, dynamicDifficulty, isDynamic, instanceId, instanceGroupSize, lfgDungeonId
	if GetInstanceInfo then
		instanceName, instanceKind, difficultyId, difficultyName, maxPlayers, dynamicDifficulty, isDynamic, instanceId, instanceGroupSize, lfgDungeonId = GetInstanceInfo()
	end

	return {
		instance = U.GetInstanceName() or "",
		instanceInfoName = instanceName or "",
		instanceKind = instanceKind or "",
		difficultyId = difficultyId or "",
		difficultyName = difficultyName or "",
		maxPlayers = maxPlayers or "",
		dynamicDifficulty = dynamicDifficulty or "",
		isDynamic = isDynamic and "yes" or "no",
		instanceId = instanceId or "",
		instanceGroupSize = instanceGroupSize or "",
		lfgDungeonId = lfgDungeonId or "",
		realZone = GetRealZoneText and GetRealZoneText() or "",
		zone = GetZoneText and GetZoneText() or "",
		subZone = subZone,
		minimapZone = minimapZone,
		atlasMapId = atlasMapId or "",
		dungeonId = dungeon and dungeon.id or "",
		dungeonName = dungeon and dungeon.name or "",
		rememberedDungeon = remembered and remembered.name or "",
		inInstance = inInstance and "yes" or "no",
		instanceType = instanceType or "",
	}
end

function Registry:GetDefaultFloor(dungeon)
	if not dungeon or not dungeon.floors then return nil end
	return dungeon.floors[1]
end
