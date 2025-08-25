-- Pawn Tooltip Parsing for Vanilla WoW
-- Parses item tooltips to extract stats

-- Initialize pattern table
PawnItemStatPatterns = PawnItemStatPatterns or {}

-- Basic vanilla patterns (these should be added to the patterns from TurtleWowPatterns.lua)
local VanillaPatterns = {
	-- Primary stats
	{pattern = "^%+(%d+) Strength$", stat = "Strength"},
	{pattern = "^%+(%d+) Agility$", stat = "Agility"},
	{pattern = "^%+(%d+) Stamina$", stat = "Stamina"},
	{pattern = "^%+(%d+) Intellect$", stat = "Intellect"},
	{pattern = "^%+(%d+) Spirit$", stat = "Spirit"},
	
	-- All stats
	{pattern = "^%+(%d+) All Stats$", stats = {
		Strength = 1, Agility = 1, Stamina = 1, Intellect = 1, Spirit = 1
	}},
	
	-- Attack power
	{pattern = "^%+(%d+) Attack Power$", stat = "Ap"},
	{pattern = "Equip: %+(%d+) Attack Power%.", stat = "Ap"},
	{pattern = "Increases attack power by (%d+)%.", stat = "Ap"},
	
	-- Ranged Attack Power
	{pattern = "^%+(%d+) ranged Attack Power$", stat = "Rap"},
	{pattern = "Increases ranged attack power by (%d+)%.", stat = "Rap"},
	
	-- Spell damage/healing
	{pattern = "Increases damage and healing done by magical spells and effects by up to (%d+)%.", stat = "SpellDamage"},
	{pattern = "Increases healing done by spells and effects by up to (%d+)%.", stat = "Healing"},
	{pattern = "%+(%d+) Healing Spells", stat = "Healing"},
	{pattern = "%+(%d+) Spell Damage and Healing", stat = "SpellDamage"},
	
	-- School specific spell damage
	{pattern = "Increases damage done by Fire spells and effects by up to (%d+)%.", stat = "FireSpellDamage"},
	{pattern = "Increases damage done by Frost spells and effects by up to (%d+)%.", stat = "FrostSpellDamage"},
	{pattern = "Increases damage done by Shadow spells and effects by up to (%d+)%.", stat = "ShadowSpellDamage"},
	{pattern = "Increases damage done by Nature spells and effects by up to (%d+)%.", stat = "NatureSpellDamage"},
	{pattern = "Increases damage done by Arcane spells and effects by up to (%d+)%.", stat = "ArcaneSpellDamage"},
	{pattern = "Increases damage done by Holy spells and effects by up to (%d+)%.", stat = "HolySpellDamage"},
	
	-- Resistances
	{pattern = "^%+(%d+) Fire Resistance$", stat = "FireResist"},
	{pattern = "^%+(%d+) Frost Resistance$", stat = "FrostResist"},
	{pattern = "^%+(%d+) Shadow Resistance$", stat = "ShadowResist"},
	{pattern = "^%+(%d+) Nature Resistance$", stat = "NatureResist"},
	{pattern = "^%+(%d+) Arcane Resistance$", stat = "ArcaneResist"},
	{pattern = "^%+(%d+) All Resistances$", stats = {
		FireResist = 1, FrostResist = 1, ShadowResist = 1, NatureResist = 1, ArcaneResist = 1
	}},
	
	-- Other stats
	{pattern = "^(%d+) Armor$", stat = "Armor"},
	{pattern = "^%+(%d+) Armor$", stat = "Armor"},
	{pattern = "Reinforced %(%+(%d+) Armor%)", stat = "Armor"},
	{pattern = "^%+(%d+) Health$", stat = "Health"},
	{pattern = "^%+(%d+) Mana$", stat = "Mana"},
}

-- Add vanilla patterns to global table
for _, pattern in ipairs(VanillaPatterns) do
	table.insert(PawnItemStatPatterns, pattern)
end

-- Main parsing function
function PawnGetItemStatsFromTooltip(ItemName, ItemLink)
	local Stats = {}
	
	if not ItemLink then return Stats end
	
	-- Create a private tooltip for parsing
	local TooltipName = "PawnPrivateTooltip"
	local Tooltip = getglobal(TooltipName)
	
	if not Tooltip then
		Tooltip = CreateFrame("GameTooltip", TooltipName, UIParent, "GameTooltipTemplate")
	end
	
	Tooltip:SetOwner(UIParent, "ANCHOR_NONE")
	Tooltip:ClearLines()
	
	-- Set the item
	local _, _, ItemString = string.find(ItemLink, "(item:%d+:%d+:%d+:%d+)")
	if not ItemString then
		_, _, ItemString = string.find(ItemLink, "(item:%d+)")
	end
	
	if ItemString then
		Tooltip:SetHyperlink(ItemString)
	else
		return Stats
	end
	
	-- Parse each line
	local NumLines = Tooltip:NumLines()
	for i = 2, NumLines do  -- Skip line 1 (item name)
		local LeftText = getglobal(TooltipName .. "TextLeft" .. i)
		if LeftText then
			local Text = LeftText:GetText()
			if Text then
				PawnParseStatLine(Text, Stats)
			end
		end
		
		local RightText = getglobal(TooltipName .. "TextRight" .. i)
		if RightText then
			local Text = RightText:GetText()
			if Text then
				PawnParseStatLine(Text, Stats)
			end
		end
	end
	
	Tooltip:Hide()
	
	return Stats
end

-- Parse a single line for stats
function PawnParseStatLine(Text, Stats)
	if not Text or Text == "" then return end
	
	-- Remove color codes
	Text = string.gsub(Text, "|c%x%x%x%x%x%x%x%x", "")
	Text = string.gsub(Text, "|r", "")
	
	-- Try each pattern
	for _, PatternInfo in ipairs(PawnItemStatPatterns) do
		local _, _, Value = string.find(Text, PatternInfo.pattern)
		
		if Value then
			Value = tonumber(Value)
			if Value then
				if PatternInfo.stat then
					-- Single stat
					Stats[PatternInfo.stat] = (Stats[PatternInfo.stat] or 0) + Value
					
					if PawnCommon and PawnCommon.Debug then
						DEFAULT_CHAT_FRAME:AddMessage("Pawn: Found " .. PatternInfo.stat .. " = " .. Value)
					end
				elseif PatternInfo.stats then
					-- Multiple stats
					for Stat, Multiplier in pairs(PatternInfo.stats) do
						Stats[Stat] = (Stats[Stat] or 0) + (Value * Multiplier)
						
						if PawnCommon and PawnCommon.Debug then
							DEFAULT_CHAT_FRAME:AddMessage("Pawn: Found " .. Stat .. " = " .. (Value * Multiplier))
						end
					end
				end
				
				-- Only match one pattern per line
				return
			end
		end
	end
end

-- Hook into Pawn's item evaluation
if PawnGetItemData then
	local OldPawnGetItemData = PawnGetItemData
	PawnGetItemData = function(ItemLink)
		local ItemData = OldPawnGetItemData(ItemLink)
		
		if ItemData and ItemLink then
			-- Parse stats from tooltip if not already present
			if not ItemData.Stats or next(ItemData.Stats) == nil then
				ItemData.Stats = PawnGetItemStatsFromTooltip(ItemData.Name, ItemLink)
			end
		end
		
		return ItemData
	end
end

PawnTooltipParsingInitialized = true

if DEFAULT_CHAT_FRAME then
	DEFAULT_CHAT_FRAME:AddMessage("|cff8ec3e6Pawn: Tooltip parsing initialized with " .. #PawnItemStatPatterns .. " patterns|r")
end