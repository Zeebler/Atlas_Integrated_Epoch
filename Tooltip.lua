AtlasIntegratedEpoch = AtlasIntegratedEpoch or {}
local EDG = AtlasIntegratedEpoch

EDG.Tooltip = {}
local Tooltip = EDG.Tooltip

function Tooltip.ShowLootRow(row)
	if not row or not row.item then return end
	local item = row.item
	GameTooltip:SetOwner(row, "ANCHOR_NONE")
	GameTooltip:ClearAllPoints()
	GameTooltip:SetPoint("RIGHT", row, "LEFT", -8, 0)
	GameTooltip:ClearLines()

	if item.spellID and GameTooltip.SetSpellByID then
		GameTooltip:SetSpellByID(item.spellID)
	elseif item.itemID then
		if GameTooltip.SetHyperlink then
			GameTooltip:SetHyperlink("item:"..item.itemID..":0:0:0")
		else
			GameTooltip:SetText(item.name or "Item unavailable")
			GameTooltip:AddLine("ItemID: "..item.itemID, 0.45, 0.75, 1)
		end
	else
		GameTooltip:SetText(item.name or "Item unavailable")
	end

	GameTooltip:Show()
end

function Tooltip.Hide()
	if GameTooltip then
		GameTooltip:Hide()
	end
end
