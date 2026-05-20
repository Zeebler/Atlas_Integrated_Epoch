AtlasIntegratedEpoch = AtlasIntegratedEpoch or {}
local EDG = AtlasIntegratedEpoch

EDG.Debug = {}
local D = EDG.Debug

function D.Enabled()
	return AtlasIntegratedEpochDB and AtlasIntegratedEpochDB.debug
end

function D.Print(message)
	if DEFAULT_CHAT_FRAME then
		DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffAtlas Integrated Epoch:|r "..tostring(message))
	end
end

function D.Trace(message)
	if D.Enabled() then
		D.Print(message)
	end
end

function D.Toggle()
	AtlasIntegratedEpochDB.debug = not AtlasIntegratedEpochDB.debug
	D.Print("Debug "..(AtlasIntegratedEpochDB.debug and "enabled" or "disabled")..".")
end
