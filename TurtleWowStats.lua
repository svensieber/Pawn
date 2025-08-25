-- Turtle WoW Stat Definitions
-- Adds support for Turtle WoW specific stats

-- Ensure PawnLocal exists
if not PawnLocal then PawnLocal = {} end
if not PawnLocal.Stats then PawnLocal.Stats = {} end

-- Add Turtle WoW specific stat names
local TurtleStats = {
	["Meditation"] = "Meditation",
	["MeditationInfo"] = "Mana regeneration while casting. Allows a percentage of your mana regeneration to continue while casting.",
	["HastePercent"] = "Haste %",
	["HastePercentInfo"] = "Increases attack speed and casting speed by a percentage. This is a direct percentage increase, not a rating.",
	["WeaponSkill"] = "Weapon Skill",
	["WeaponSkillInfo"] = "Increases your skill with weapons. Each point reduces chance to miss and glancing blow penalty.",
	
	-- Also ensure these Vanilla stats are defined
	["HitPercent"] = "Hit %",
	["HitPercentInfo"] = "Increases your chance to hit with physical attacks. Cap is 8% for raid bosses in Turtle WoW (reduced from 9%).",
	["CritPercent"] = "Critical Strike %",
	["CritPercentInfo"] = "Increases your chance to critically strike with physical attacks.",
	["SpellHitPercent"] = "Spell Hit %",
	["SpellHitPercentInfo"] = "Increases your chance to hit with spells. Cap varies by level difference.",
	["SpellCritPercent"] = "Spell Critical %",
	["SpellCritPercentInfo"] = "Increases your chance to critically strike with spells.",
	["DodgePercent"] = "Dodge %",
	["DodgePercentInfo"] = "Increases your chance to dodge attacks.",
	["ParryPercent"] = "Parry %", 
	["ParryPercentInfo"] = "Increases your chance to parry attacks.",
	["BlockPercent"] = "Block %",
	["BlockPercentInfo"] = "Increases your chance to block attacks with a shield.",
	["DefensePercent"] = "Defense",
	["DefensePercentInfo"] = "Increases defense skill, reducing chance to be critically hit.",
}

-- Merge with existing PawnLocal.Stats
for key, value in pairs(TurtleStats) do
	PawnLocal.Stats[key] = value
end

-- Define stat categories for UI display
PawnStatCategories = {
	["Attributes"] = {
		"Strength",
		"Agility", 
		"Stamina",
		"Intellect",
		"Spirit",
	},
	["Weapon Stats"] = {
		"Dps",
		"MeleeDps",
		"RangedDps",
		"WeaponSkill",
	},
	["Physical"] = {
		"Ap",
		"Rap",
		"FeralAp",
		"HitPercent",
		"CritPercent",
		"HastePercent",
		"ArmorPenetration",
	},
	["Spell"] = {
		"SpellDamage",
		"SpellPower",
		"Healing",
		"SpellHitPercent", 
		"SpellCritPercent",
		"SpellPenetration",
		"FireSpellDamage",
		"FrostSpellDamage",
		"ArcaneSpellDamage",
		"ShadowSpellDamage",
		"NatureSpellDamage",
		"HolySpellDamage",
	},
	["Defense"] = {
		"Armor",
		"DefensePercent",
		"DodgePercent",
		"ParryPercent",
		"BlockPercent",
		"BlockValue",
		"Health",
		"Hp5",
	},
	["Resources"] = {
		"Mana",
		"Mp5",
		"Meditation",
	},
	["Resistances"] = {
		"AllResist",
		"FireResist",
		"FrostResist", 
		"ArcaneResist",
		"ShadowResist",
		"NatureResist",
	},
}

-- Export for use by other modules
_G.PawnStatCategories = PawnStatCategories