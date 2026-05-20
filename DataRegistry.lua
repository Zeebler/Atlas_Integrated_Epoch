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

function Registry:GetDungeonForCurrentInstance()
	local candidates = {
		U.GetInstanceName(),
		GetRealZoneText and GetRealZoneText(),
		GetZoneText and GetZoneText(),
		GetSubZoneText and GetSubZoneText(),
	}

	for _, name in ipairs(candidates) do
		local dungeon = self:ResolveDungeon(name)
		if dungeon then return dungeon end
	end
end

function Registry:GetDefaultFloor(dungeon)
	if not dungeon or not dungeon.floors then return nil end
	return dungeon.floors[1]
end
