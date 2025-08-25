-- Turtle WoW Tooltip Parsing Patterns
-- Adds patterns for Turtle WoW specific stats

-- Ensure tables exist
if not PawnStatPatterns then PawnStatPatterns = {} end

-- Turtle WoW specific patterns
local TurtleWowPatterns = {
	-- Meditation (Mana regeneration while casting)
	{pattern = "Allows (%d+)%% of your mana regeneration to continue while casting%.", stat = "Meditation"},
	{pattern = "Allows (%d+)%% of your Mana regeneration to continue while casting%.", stat = "Meditation"},
	{pattern = "%+(%d+)%% Meditation", stat = "Meditation"},
	{pattern = "Meditation %+(%d+)%%", stat = "Meditation"},
	
	-- Haste (Attack and Casting speed)
	{pattern = "Increases attack speed by (%d+)%%%.", stat = "HastePercent"},
	{pattern = "Increases casting speed by (%d+)%%%.", stat = "HastePercent"},
	{pattern = "%+(%d+)%% Haste", stat = "HastePercent"},
	{pattern = "Haste %+(%d+)%%", stat = "HastePercent"},
	{pattern = "Equip: Increases your attack speed by (%d+)%%%.", stat = "HastePercent"},
	{pattern = "Equip: Increases your casting speed by (%d+)%%%.", stat = "HastePercent"},
	
	-- Weapon Skill
	{pattern = "%+(%d+) Weapon Skill", stat = "WeaponSkill"},
	{pattern = "Weapon Skill %+(%d+)", stat = "WeaponSkill"},
	{pattern = "%+(%d+) Daggers", stat = "DaggerSkill"},
	{pattern = "%+(%d+) Swords", stat = "SwordSkill"},
	{pattern = "%+(%d+) Two%-Handed Swords", stat = "TwoHandedSwordSkill"},
	{pattern = "%+(%d+) Axes", stat = "AxeSkill"},
	{pattern = "%+(%d+) Two%-Handed Axes", stat = "TwoHandedAxeSkill"},
	{pattern = "%+(%d+) Maces", stat = "MaceSkill"},
	{pattern = "%+(%d+) Two%-Handed Maces", stat = "TwoHandedMaceSkill"},
	{pattern = "%+(%d+) Polearms", stat = "PolearmSkill"},
	{pattern = "%+(%d+) Staves", stat = "StaffSkill"},
	{pattern = "%+(%d+) Fist Weapons", stat = "FistWeaponSkill"},
	{pattern = "%+(%d+) Unarmed", stat = "UnarmedSkill"},
	{pattern = "%+(%d+) Bows", stat = "BowSkill"},
	{pattern = "%+(%d+) Guns", stat = "GunSkill"},
	{pattern = "%+(%d+) Crossbows", stat = "CrossbowSkill"},
	{pattern = "%+(%d+) Wands", stat = "WandSkill"},
	{pattern = "%+(%d+) Thrown", stat = "ThrownSkill"},
	
	-- Hit/Crit as direct percentages (Vanilla style)
	{pattern = "Improves your chance to hit by (%d+)%%%.", stat = "HitPercent"},
	{pattern = "%+(%d+)%% Hit", stat = "HitPercent"},
	{pattern = "Hit %+(%d+)%%", stat = "HitPercent"},
	{pattern = "%+(%d+)%% to Hit", stat = "HitPercent"},
	
	{pattern = "Improves your chance to get a critical strike by (%d+)%%%.", stat = "CritPercent"},
	{pattern = "%+(%d+)%% Critical Strike", stat = "CritPercent"},
	{pattern = "Critical Strike %+(%d+)%%", stat = "CritPercent"},
	{pattern = "%+(%d+)%% Crit", stat = "CritPercent"},
	
	{pattern = "Improves your chance to hit with spells by (%d+)%%%.", stat = "SpellHitPercent"},
	{pattern = "%+(%d+)%% Spell Hit", stat = "SpellHitPercent"},
	{pattern = "Spell Hit %+(%d+)%%", stat = "SpellHitPercent"},
	
	{pattern = "Improves your chance to get a critical strike with spells by (%d+)%%%.", stat = "SpellCritPercent"},
	{pattern = "%+(%d+)%% Spell Critical Strike", stat = "SpellCritPercent"},
	{pattern = "Spell Critical Strike %+(%d+)%%", stat = "SpellCritPercent"},
	{pattern = "%+(%d+)%% Spell Crit", stat = "SpellCritPercent"},
	
	-- Defense stats as percentages/values
	{pattern = "Increases your chance to dodge an attack by (%d+)%%%.", stat = "DodgePercent"},
	{pattern = "%+(%d+)%% Dodge", stat = "DodgePercent"},
	{pattern = "Dodge %+(%d+)%%", stat = "DodgePercent"},
	
	{pattern = "Increases your chance to parry an attack by (%d+)%%%.", stat = "ParryPercent"},
	{pattern = "%+(%d+)%% Parry", stat = "ParryPercent"},
	{pattern = "Parry %+(%d+)%%", stat = "ParryPercent"},
	
	{pattern = "Increases your chance to block attacks with a shield by (%d+)%%%.", stat = "BlockPercent"},
	{pattern = "%+(%d+)%% Block", stat = "BlockPercent"},
	{pattern = "Block Chance %+(%d+)%%", stat = "BlockPercent"},
	
	{pattern = "Increases the block value of your shield by (%d+)%.", stat = "BlockValue"},
	{pattern = "%+(%d+) Block Value", stat = "BlockValue"},
	
	{pattern = "Increased Defense %+(%d+)%.", stat = "DefensePercent"},
	{pattern = "%+(%d+) Defense", stat = "DefensePercent"},
	{pattern = "Defense %+(%d+)", stat = "DefensePercent"},
	
	-- Mana and Health regeneration
	{pattern = "Restores (%d+) mana per 5 sec%.", stat = "Mp5"},
	{pattern = "%+(%d+) Mana per 5 seconds", stat = "Mp5"},
	{pattern = "%+(%d+) Mana every 5 sec%.", stat = "Mp5"},
	{pattern = "Mana Regen %+(%d+) per 5 sec%.", stat = "Mp5"},
	
	{pattern = "Restores (%d+) health per 5 sec%.", stat = "Hp5"},
	{pattern = "%+(%d+) Health per 5 seconds", stat = "Hp5"},
	{pattern = "%+(%d+) Health every 5 sec%.", stat = "Hp5"},
	{pattern = "Health Regen %+(%d+) per 5 sec%.", stat = "Hp5"},
	
	-- Armor Penetration (if it exists in Turtle WoW)
	{pattern = "Your attacks ignore (%d+) of your opponent's armor%.", stat = "ArmorPenetration"},
	{pattern = "%+(%d+) Armor Penetration", stat = "ArmorPenetration"},
	
	-- Spell Penetration
	{pattern = "Decreases the magical resistances of your spell targets by (%d+)%.", stat = "SpellPenetration"},
	{pattern = "%+(%d+) Spell Penetration", stat = "SpellPenetration"},
}

-- Function to add Turtle WoW patterns to Pawn
function AddTurtleWowPatterns()
	-- Initialize pattern table if it doesn't exist
	if not PawnItemStatPatterns then
		PawnItemStatPatterns = {}
	end
	
	-- Add each Turtle WoW pattern
	for _, pattern in ipairs(TurtleWowPatterns) do
		table.insert(PawnItemStatPatterns, pattern)
	end
	
	-- Debug output
	if DEFAULT_CHAT_FRAME then
		DEFAULT_CHAT_FRAME:AddMessage("|cff8ec3e6Pawn: Turtle WoW patterns loaded (" .. #TurtleWowPatterns .. " patterns)|r")
	end
end

-- Make function globally available
_G.AddTurtleWowPatterns = AddTurtleWowPatterns

-- Auto-add patterns when loaded
AddTurtleWowPatterns()