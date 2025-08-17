-- turtle-wow/parsing/StatPatterns.lua
PawnStatPatterns = {
    -- PHASE 1: Initialize patterns for current locale
    Initialize = function(self)
        local locale = GetLocale()
        
        -- English patterns (default)
        self.patterns = {
            -- Primary stats (highest priority)
            {pattern = "^%+(%d+) Strength$", stat = "Strength", priority = 1},
            {pattern = "^%+(%d+) Agility$", stat = "Agility", priority = 1},
            {pattern = "^%+(%d+) Stamina$", stat = "Stamina", priority = 1},
            {pattern = "^%+(%d+) Intellect$", stat = "Intellect", priority = 1},
            {pattern = "^%+(%d+) Spirit$", stat = "Spirit", priority = 1},
            
            -- All stats
            {pattern = "^%+(%d+) All Stats$", stats = {
                Strength = 1, Agility = 1, Stamina = 1, Intellect = 1, Spirit = 1
            }, priority = 1},
            
            -- Attack power (multiple formats)
            {pattern = "^%+(%d+) Attack Power$", stat = "AttackPower", priority = 2},
            {pattern = "Increases attack power by (%d+)%.", stat = "AttackPower", priority = 2},
            {pattern = "^%+(%d+) ranged Attack Power$", stat = "RangedAttackPower", priority = 2},
            {pattern = "Increases ranged attack power by (%d+)%.", stat = "RangedAttackPower", priority = 2},
            {pattern = "%+(%d+) Attack Power when fighting Undead", stat = "AttackPowerUndead", priority = 3},
            {pattern = "%+(%d+) Attack Power when fighting Demons", stat = "AttackPowerDemons", priority = 3},
            
            -- Spell power
            {pattern = "Increases damage and healing done by magical spells and effects by up to (%d+)%.", 
             stat = "SpellPower", priority = 2},
            {pattern = "Increases healing done by spells and effects by up to (%d+)%.", 
             stat = "HealingPower", priority = 2},
            {pattern = "Increases damage done by Holy spells and effects by up to (%d+)%.", 
             stat = "HolyPower", priority = 3},
            {pattern = "Increases damage done by Fire spells and effects by up to (%d+)%.", 
             stat = "FirePower", priority = 3},
            {pattern = "Increases damage done by Nature spells and effects by up to (%d+)%.", 
             stat = "NaturePower", priority = 3},
            {pattern = "Increases damage done by Frost spells and effects by up to (%d+)%.", 
             stat = "FrostPower", priority = 3},
            {pattern = "Increases damage done by Shadow spells and effects by up to (%d+)%.", 
             stat = "ShadowPower", priority = 3},
            {pattern = "Increases damage done by Arcane spells and effects by up to (%d+)%.", 
             stat = "ArcanePower", priority = 3},
            
            -- Hit and Crit
            {pattern = "Improves your chance to hit by (%d+)%%%.", stat = "HitPercent", priority = 2},
            {pattern = "Improves your chance to get a critical strike by (%d+)%%%.", stat = "CritPercent", priority = 2},
            {pattern = "Improves your chance to hit with spells by (%d+)%%%.", stat = "SpellHitPercent", priority = 2},
            {pattern = "Improves your chance to get a critical strike with spells by (%d+)%%%.", stat = "SpellCritPercent", priority = 2},
            
            -- Defense
            {pattern = "Increased Defense %+(%d+)%.", stat = "Defense", priority = 2},
            {pattern = "%+(%d+) Defense Rating", stat = "DefenseRating", priority = 2},
            {pattern = "Increases your chance to dodge an attack by (%d+)%%%.", stat = "DodgePercent", priority = 2},
            {pattern = "Increases your chance to parry an attack by (%d+)%%%.", stat = "ParryPercent", priority = 2},
            {pattern = "Increases your chance to block attacks with a shield by (%d+)%%%.", stat = "BlockPercent", priority = 2},
            {pattern = "Increases the block value of your shield by (%d+)%.", stat = "BlockValue", priority = 2},
            
            -- Resistance
            {pattern = "^%+(%d+) Fire Resistance$", stat = "FireResistance", priority = 2},
            {pattern = "^%+(%d+) Nature Resistance$", stat = "NatureResistance", priority = 2},
            {pattern = "^%+(%d+) Frost Resistance$", stat = "FrostResistance", priority = 2},
            {pattern = "^%+(%d+) Shadow Resistance$", stat = "ShadowResistance", priority = 2},
            {pattern = "^%+(%d+) Arcane Resistance$", stat = "ArcaneResistance", priority = 2},
            {pattern = "^%+(%d+) All Resistances$", stats = {
                FireResistance = 1, NatureResistance = 1, FrostResistance = 1,
                ShadowResistance = 1, ArcaneResistance = 1
            }, priority = 2},
            
            -- Regeneration
            {pattern = "Restores (%d+) health per 5 sec%.", stat = "HealthPer5", priority = 3},
            {pattern = "Restores (%d+) health every 5 sec%.", stat = "HealthPer5", priority = 3},
            {pattern = "%+(%d+) Health per 5 sec%.", stat = "HealthPer5", priority = 3},
            {pattern = "Restores (%d+) mana per 5 sec%.", stat = "ManaPer5", priority = 3},
            {pattern = "Restores (%d+) mana every 5 sec%.", stat = "ManaPer5", priority = 3},
            {pattern = "%+(%d+) Mana per 5 sec%.", stat = "ManaPer5", priority = 3},
            {pattern = "%+(%d+) Mana Regen", stat = "ManaPer5", priority = 3},
            
            -- Weapon stats
            {pattern = "^Scope %(%+(%d+) Damage%)$", stat = "ScopeDamage", priority = 3},
            {pattern = "^%+(%d+) Weapon Damage$", stat = "WeaponDamage", priority = 3},
            
            -- Skills
            {pattern = "%+(%d+) Fishing", stat = "Fishing", priority = 4},
            {pattern = "%+(%d+) Herbalism", stat = "Herbalism", priority = 4},
            {pattern = "%+(%d+) Mining", stat = "Mining", priority = 4},
            {pattern = "%+(%d+) Skinning", stat = "Skinning", priority = 4},
            
            -- Mount speed
            {pattern = "Increases speed by (%d+)%%%.", stat = "MountSpeed", priority = 4},
            
            -- Armor
            {pattern = "^(%d+) Armor$", stat = "Armor", priority = 1},
            {pattern = "Reinforced %(%+(%d+) Armor%)", stat = "BonusArmor", priority = 3},
        }
        
        -- Add German patterns if needed
        if locale == "deDE" then
            self:AddGermanPatterns()
        elseif locale == "frFR" then
            self:AddFrenchPatterns()
        end
        
        -- Sort by priority for efficient matching
        table.sort(self.patterns, function(a, b) return a.priority < b.priority end)
    end,
    
    AddGermanPatterns = function(self)
        -- German specific patterns
        local germanPatterns = {
            {pattern = "^%+(%d+) Stärke$", stat = "Strength", priority = 1},
            {pattern = "^%+(%d+) Beweglichkeit$", stat = "Agility", priority = 1},
            {pattern = "^%+(%d+) Ausdauer$", stat = "Stamina", priority = 1},
            {pattern = "^%+(%d+) Intelligenz$", stat = "Intellect", priority = 1},
            {pattern = "^%+(%d+) Willenskraft$", stat = "Spirit", priority = 1},
            -- ... more German patterns
        }
        
        for _, pattern in ipairs(germanPatterns) do
            table.insert(self.patterns, pattern)
        end
    end,
    
    AddFrenchPatterns = function(self)
        -- French specific patterns
        local frenchPatterns = {
            {pattern = "^%+(%d+) Force$", stat = "Strength", priority = 1},
            {pattern = "^%+(%d+) Agilité$", stat = "Agility", priority = 1},
            {pattern = "^%+(%d+) Endurance$", stat = "Stamina", priority = 1},
            -- ... more French patterns
        }
        
        for _, pattern in ipairs(frenchPatterns) do
            table.insert(self.patterns, pattern)
        end
    end
}

-- Initialize on load
PawnStatPatterns:Initialize()