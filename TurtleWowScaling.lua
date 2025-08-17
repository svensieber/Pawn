-- ========================================
-- TURTLE WOW COMPLETE SCALING IMPLEMENTATION
-- ========================================
-- Patches 1.16.1 through 1.18.0 - ALL CHANGES
-- Based on ClassicHawsJon.lua with complete Turtle WoW modifications
-- Last Updated: December 2024
-- UPDATED: Removed Rating system (not in Vanilla), added HastePercent for casters

-- ========================================
-- VANILLA-STYLE DIRECT PERCENTAGES
-- ========================================
-- Note: Rating system didn't exist in Vanilla WoW
-- Turtle WoW uses direct percentage values for combat stats
-- HastePercent affects both attack and casting speed

-- ========================================
-- PATCH 1.18.0 ARMOR FORMULA CHANGES
-- ========================================
-- Physical Damage Reduction no longer capped at 75%
-- Diminishing returns apply beyond 75%
local function CalculateArmorValue(baseDR, class, spec)
    if baseDR <= 0.75 then
        return 1.0  -- Normal value below 75%
    else
        -- Beyond 75%, heavy diminishing returns
        local excess = baseDR - 0.75
        local diminishFactor = 0.4  -- 60% reduction in effectiveness
        
        -- Tank specs get slightly better scaling
        if (class == 1 and spec == 3) or     -- Warrior Protection
           (class == 2 and spec == 2) or     -- Paladin Protection  
           (class == 11 and spec == 3) then  -- Druid Feral Tank
            return 0.7  -- 30% reduction for tanks
        else
            return 0.5  -- 50% reduction for others
        end
    end
end

-- ========================================
-- PATCH 1.17.2 CHANGES
-- ========================================
-- Hit cap reduced from 9% to 8%
-- Weapon skill soft cap at 305 removed, linear scaling
-- Racial weapon skills nerfed from +5 to +3
local WeaponSkillHitPer = 0.2     -- 0.2% hit per point
local WeaponSkillGlancingPer = 2  -- 2% glancing reduction per point

-- ========================================
-- PATCH 1.17.2 RAGE GENERATION FORMULA
-- ========================================
-- 90% gear-dependent + 10% weapon speed predetermined
local function CalculateRageGeneration(weaponSpeed, gearLevel)
    local gearComponent = gearLevel * 0.9
    local speedComponent = weaponSpeed * 0.1
    return gearComponent + speedComponent
end

-- ========================================
-- NEW STATS (PATCH 1.16.0)
-- ========================================
-- Meditation: Mana regeneration in combat (scales with Spirit)
-- HastePercent: Combined attack and casting speed increase

-- ========================================
-- DEFAULT SCALING TEMPLATE
-- ========================================
local DefaultScaling = {
    -- Physical Stats
    Strength = 0,
    Agility = 0.05,
    Stamina = 0.1,
    
    -- Weapon Stats
    Dps = 0,
    MeleeDps = 0,
    RangedDps = 0,
    
    -- Attack Power
    Ap = 0,
    Rap = 0,
    FeralAp = 0,
    
    -- Physical Stats (Direct %)
    HitPercent = 0,
    CritPercent = 0,
    
    -- Caster Stats
    Intellect = 0,
    Spirit = 0,
    Mana = 0,
    Mp5 = 0,
    
    -- Spell Stats
    Healing = 0,
    SpellDamage = 0,
    SpellPower = 0,
    FireSpellDamage = 0,
    FrostSpellDamage = 0,
    ArcaneSpellDamage = 0,
    ShadowSpellDamage = 0,
    NatureSpellDamage = 0,
    HolySpellDamage = 0,
    
    -- Spell Stats (Direct %)
    SpellHitPercent = 0,
    SpellCritPercent = 0,
    SpellPenetration = 0,
    
    -- Defense Stats
    Health = 0.01,
    Hp5 = 1,
    Armor = 0.005,
    DefensePercent = 0.05,
    DodgePercent = 0.05,
    ParryPercent = 0.05,
    BlockPercent = 0,
    BlockValue = 0,
    
    -- Resistances (30% less valuable in Turtle WoW)
    ResilienceRating = 0.14,  -- Reduced from 0.2
    AllResist = 0.14,         -- Reduced from 0.2
    FireResist = 0.028,       -- Reduced from 0.04
    FrostResist = 0.028,      -- Reduced from 0.04
    ArcaneResist = 0.028,     -- Reduced from 0.04
    ShadowResist = 0.028,     -- Reduced from 0.04
    NatureResist = 0.028,     -- Reduced from 0.04
    
    -- Special
    MetaSocketEffect = 36,
    
    -- TURTLE WOW NEW STATS (Patch 1.16.0)
    Meditation = 0,       -- Mana regen in combat
    HastePercent = 0,     -- Combined attack & casting speed
    WeaponSkill = 0,      -- Weapon skill value
}

-- ========================================
-- DRUID SPECIALIZATIONS (ALL PATCHES)
-- ========================================

-- DRUID BALANCE (Moonkin) - Complete with all changes
local DruidBalance_TurtleWoW = {
    -- Base Stats
    Strength = 0,
    Agility = 0.05,
    Intellect = 0.38,
    Spirit = 0.34 * 1.3,  -- +30% due to Meditation synergy
    Stamina = 0.1,
    
    -- Resources
    Mana = 0.032,
    Mp5 = 0.58 * 0.8,  -- -20% due to Meditation
    Health = 0.01,
    Hp5 = 1,
    
    -- Spell Power (Updated with Eclipse changes)
    SpellDamage = 1,
    ArcaneSpellDamage = 0.64 * 1.1,     -- Arcane Rupture
    NatureSpellDamage = 0.43 * 1.25,    -- Eclipse +25%
    
    -- Eclipse Patch 1.18.0: 10% + 60% of crit chance damage bonus
    -- Balance of All Things: Starfire cast -0.5s, Wrath -50% mana
    
    -- Spell Stats
    SpellHitPercent = 1.21,
    SpellCritPercent = 0.62 * 1.03,  -- +3% Moonkin Form
    
    -- Defense
    Armor = 0.005 * 3.6,  -- Moonkin Form 360% armor
    DefensePercent = 0.05,
    DodgePercent = 0.05,
    
    -- Turtle WoW New Stats
    Meditation = 2.0,
    HastePercent = 0.7,  -- Benefits from casting speed portion
    
    -- Coefficients
    -- Hurricane: 9.6% per tick, 30s CD (was 60s)
    -- Wrath: +5% base and coefficient
    -- Moonfire/Insect Swarm: +6s duration (+2/3 ticks)
}

-- DRUID FERAL DPS - Complete with Blood Frenzy changes
local DruidFeral_TurtleWoW = {
    -- Base Stats
    Strength = 1.48,
    Agility = 1 * 1.1,  -- Blood Frenzy synergies
    Intellect = 0.1,
    Spirit = 0.05,
    Stamina = 0.1,
    
    -- Resources
    Mana = 0.009,
    Mp5 = 0.3,
    Health = 0.01,
    Hp5 = 1,
    
    -- Attack Power (Updated coefficients)
    Ap = 0.59 * 1.09,     -- General improvements
    FeralAp = 0.59 * 1.09,
    
    -- Swipe: 6% AP scaling (was 8%)
    -- Rake: 12% initial, 3% bleed AP scaling
    -- Ferocious Bite: 0.5% per energy
    
    -- Physical Stats
    HitPercent = 0.61,
    CritPercent = 0.59 * 1.1,  -- Primal Fury
    
    -- Defense
    Armor = 0.02,
    DefensePercent = 0.05,
    DodgePercent = 0.05,
    
    -- Turtle WoW New Stats
    Meditation = 0,
    HastePercent = 1.1,  -- Melee attack speed focus
    
    -- Patch 1.18.0: Rip duration scales 10-18s by CP
    -- Tiger Fury: +10 energy every 3 sec
}

-- DRUID FERAL TANK - Updated with threat changes
local DruidFeralTank_TurtleWoW = {
    -- Base Stats
    Strength = 0.2,
    Agility = 0.48,
    Intellect = 0.1,
    Spirit = 0.05,
    Stamina = 1,
    
    -- Resources
    Mana = 0.009,
    Mp5 = 0.3,
    Health = 0.08,
    Hp5 = 2,
    
    -- Attack Power
    Ap = 0.34,
    FeralAp = 0.34,
    
    -- Savage Bite: 225% threat (was 350%, then 175%)
    -- Swipe: 140% threat (was 175%)
    
    -- Physical Stats
    HitPercent = 0.16,
    CritPercent = 0.15,
    
    -- Spell
    Healing = 0.025,
    NatureSpellDamage = 0.025,
    
    -- Defense (Patch 1.18.0 armor changes)
    Armor = 0.1 * 0.7,  -- Reduced due to DR over 75%
    DefensePercent = 0.26,
    DodgePercent = 0.38,
    
    -- Resistances
    AllResist = 0.7,  -- Reduced from 1.0
    FireResist = 0.14,
    FrostResist = 0.14,
    ArcaneResist = 0.14,
    ShadowResist = 0.14,
    NatureResist = 0.14,
    
    -- Turtle WoW New Stats
    Meditation = 0,
    HastePercent = 0.6,
    
    -- Frenzied Regeneration: 10 rage/sec = 6/7/8% stamina healing
}

-- DRUID RESTORATION - Tree of Life improvements
local DruidRestoration_TurtleWoW = {
    -- Base Stats
    Strength = 0,
    Agility = 0.05,
    Intellect = 1,
    Spirit = 0.87 * 1.3,  -- +30% Meditation, +20% Tree of Life to party
    Stamina = 0.1,
    
    -- Resources
    Mana = 0.09,
    Mp5 = 1.7 * 0.8,  -- -20% due to Meditation
    Health = 0.01,
    Hp5 = 1,
    
    -- Healing
    Healing = 1.21 * 1.05,  -- Tree of Life improvements
    
    -- Spell Stats
    SpellCritPercent = 0.35,
    
    -- Defense
    Armor = 0.005 * 1.8,  -- Tree of Life 180% armor
    DefensePercent = 0.05,
    DodgePercent = 0.05,
    
    -- Turtle WoW New Stats
    Meditation = 2.5,
    HastePercent = 0.5,  -- Benefits from casting speed for HoTs
    
    -- Patch 1.18.0: Rejuvenation/Regrowth 3s->2s ticks
    -- Tranquility: 30 min CD, healing per rank varies
}

-- ========================================
-- HUNTER SPECIALIZATIONS (ALL PATCHES)
-- ========================================

-- HUNTER BEAST MASTERY - Complete pet scaling
local HunterBM_TurtleWoW = {
    -- Base Stats
    Strength = 0.05,
    Agility = 1,
    Intellect = 0.8,
    Spirit = 0.05,
    Stamina = 0.1,
    
    -- Resources
    Mana = 0.075,
    Mp5 = 2.4,
    Health = 0.01,
    Hp5 = 1,
    
    -- Weapon Stats
    MeleeDps = 0.75,
    RangedDps = 2.4,
    
    -- Attack Power with Spirit Bond scaling
    Ap = 0.43 * 1.12,      -- General scaling
    Rap = 0.43 * 1.25,     -- Spirit Bond: 25% RAP to pet melee AP
    
    -- Pet Scaling (Patch 1.17.2):
    -- Pet gets 12-25% of hunter's RAP as melee AP
    -- Pet gets 7-15% of hunter's RAP as spell power
    -- Bite: 1 damage per 20 AP
    -- Claw: 1 damage per 42 AP
    -- Lightning Breath: 0.5 spell power coefficient
    
    -- Physical Stats
    HitPercent = 1,
    CritPercent = 0.8,
    
    -- Bestial Precision: +8% physical, +18% spell hit for pet
    SpellHitPercent = 1.18,  -- For pet abilities
    
    -- Defense
    Armor = 0.005,
    DefensePercent = 0.05,
    DodgePercent = 0.05,
    ParryPercent = 0.05,
    
    -- Turtle WoW New Stats
    Meditation = 0,
    HastePercent = 1.1,
    
    -- Patch 1.18.0: Baited Shot 125% weapon damage
    -- Kill Command: +50% crit damage
    -- Avoidance: 80% AoE reduction (was 50%)
}

-- HUNTER MARKSMANSHIP - Lethal Shots emphasis
local HunterMM_TurtleWoW = {
    -- Base Stats
    Strength = 0.05,
    Agility = 1 * 1.2,
    Intellect = 0.9,
    Spirit = 0.05,
    Stamina = 0.1,
    
    -- Resources
    Mana = 0.085,
    Mp5 = 2.4,
    Health = 0.01,
    Hp5 = 1,
    
    -- Weapon Stats
    MeleeDps = 0.75,
    RangedDps = 2.6,
    
    -- Attack Power with Trueshot Aura
    Ap = 0.55 * 1.05,      -- Trueshot 5% AP scaling
    Rap = 0.55 * 1.05,
    
    -- Physical Stats
    HitPercent = 1,
    CritPercent = 0.6 * 1.3,  -- Lethal Shots
    
    -- Improved Stings: +30% Serpent Sting damage
    -- Piercing Shots: 20% bleed over 8 sec
    -- Steady Shot: 5% mana, 1 sec cast
    
    -- Defense
    Armor = 0.005,
    DefensePercent = 0.05,
    DodgePercent = 0.05,
    ParryPercent = 0.05,
    
    -- Turtle WoW New Stats
    Meditation = 0,
    HastePercent = 1.0,
}

-- HUNTER SURVIVAL - Trap and melee focus
local HunterSurvival_TurtleWoW = {
    -- Base Stats
    Strength = 0.05,
    Agility = 1 * 1.1,
    Intellect = 0.8,
    Spirit = 0.05,
    Stamina = 0.1,
    
    -- Resources
    Mana = 0.075,
    Mp5 = 2.4,
    Health = 0.01,
    Hp5 = 1,
    
    -- Weapon Stats
    MeleeDps = 1,
    RangedDps = 2.4,
    
    -- Attack Power
    Ap = 0.55,
    Rap = 0.5,
    
    -- Lightning Reflexes: 100% Agility to melee AP
    -- Carve: 60% weapon damage
    -- Wing Clip: 3s CD, 25-35% weapon damage
    
    -- Physical Stats
    HitPercent = 1,
    CritPercent = 0.65,
    
    -- Trap Scaling:
    -- Immolation: 1 per 10 AP
    -- Explosive initial: 1 per 6.5 AP
    -- Explosive DoT: 1 per 30 AP
    
    -- Defense
    Armor = 0.005,
    DefensePercent = 0.05,
    DodgePercent = 0.05,
    ParryPercent = 0.05,
    
    -- Turtle WoW New Stats
    Meditation = 0,
    HastePercent = 0.9,
    
    -- Patch 1.18.0: Lacerate 35% melee AP + 20% bleed
}

-- ========================================
-- MAGE SPECIALIZATIONS (ALL PATCHES)
-- ========================================

-- MAGE ARCANE - Arcane Missiles and Rupture focus
local MageArcane_TurtleWoW = {
    -- Base Stats
    Strength = 0,
    Agility = 0.05,
    Intellect = 0.46,
    Spirit = 0.59 * 1.15,  -- Meditation synergy
    Stamina = 0.1,
    
    -- Resources
    Mana = 0.038,
    Mp5 = 1.13 * 0.9,
    Health = 0.01,
    Hp5 = 1,
    
    -- Spell Power with updated coefficients
    SpellDamage = 1 * 1.147,  -- Arcane Missiles increase
    FireSpellDamage = 0.064,
    FrostSpellDamage = 0.52,
    ArcaneSpellDamage = 0.88 * 1.328,  -- Major buff
    
    -- Arcane Missiles: 32.8% per missile (was 24%)
    -- Arcane Surge: 65% coefficient, 8 sec CD
    -- Arcane Rupture: 100% coefficient, +20% AM damage
    
    -- Spell Stats
    SpellHitPercent = 0.87,
    SpellCritPercent = 0.6 * 1.06,  -- Arcane Impact
    SpellPenetration = 0.09,
    
    -- Arcane Power: +35% cast speed, -2% max mana/sec
    -- Arcane Potency: 50/100% crit damage (was 18/36/50%)
    -- Temporal Convergence: 15% reset chance
    
    -- Defense
    Armor = 0.005,
    DefensePercent = 0.05,
    DodgePercent = 0.05,
    
    -- Turtle WoW New Stats
    Meditation = 1.5,
    HastePercent = 0.75,  -- High value for casting speed
}

-- MAGE FIRE - Ignite and Critical Mass
local MageFire_TurtleWoW = {
    -- Base Stats
    Strength = 0,
    Agility = 0.05,
    Intellect = 0.44,
    Spirit = 0.066 * 1.15,
    Stamina = 0.1,
    
    -- Resources
    Mana = 0.036,
    Mp5 = 0.9 * 0.9,
    Health = 0.01,
    Hp5 = 1,
    
    -- Spell Power
    SpellDamage = 1 * 1.1,
    FireSpellDamage = 0.94 * 1.15,  -- Fire focus
    FrostSpellDamage = 0.32,
    ArcaneSpellDamage = 0.168,
    
    -- Ignite: 4s duration (was 6s, then back to 4s)
    -- Hot Streak: 50/100% proc for instant Pyroblast
    -- Master of Elements: 15/30/45% mana refund on crit
    
    -- Spell Stats
    SpellHitPercent = 0.93,
    SpellCritPercent = 0.77 * 1.5,  -- Critical Mass
    SpellPenetration = 0.09,
    
    -- Patch 1.18.0: Flamestrike 2.5s cast (was 3s)
    -- Blast Wave: 30s CD (was 45s)
    
    -- Defense
    Armor = 0.005,
    DefensePercent = 0.05,
    DodgePercent = 0.05,
    
    -- Turtle WoW New Stats
    Meditation = 1.5,
    HastePercent = 0.7,  -- Important for cast time reduction
}

-- MAGE FROST - Shatter and control
local MageFrost_TurtleWoW = {
    -- Base Stats
    Strength = 0,
    Agility = 0.05,
    Intellect = 0.37,
    Spirit = 0.06 * 1.15,
    Stamina = 0.1,
    
    -- Resources
    Mana = 0.032,
    Mp5 = 0.8 * 0.9,
    Health = 0.01,
    Hp5 = 1,
    
    -- Spell Power
    SpellDamage = 1,
    FireSpellDamage = 0.05,
    FrostSpellDamage = 0.95 * 1.2,  -- Winter's Chill
    ArcaneSpellDamage = 0.13,
    
    -- Icicles: 40% spellpower per icicle
    -- Shatter: 7-35% crit (was 10-50%)
    -- Ice Barrier: +15% frost damage while active
    
    -- Spell Stats
    SpellHitPercent = 1.22 * 1.06,  -- Elemental Precision
    SpellCritPercent = 0.58 * 1.33,  -- Shatter
    SpellPenetration = 0.07,
    
    -- Flash Freeze: 50/100% Icicles reset
    -- Improved Blizzard: 20-40% slow (was 30-65%)
    
    -- Defense
    Armor = 0.005,
    DefensePercent = 0.05,
    DodgePercent = 0.05,
    
    -- Turtle WoW New Stats
    Meditation = 1.5,
    HastePercent = 0.65,  -- Moderate value for casting
}

-- ========================================
-- PALADIN SPECIALIZATIONS (ALL PATCHES)
-- ========================================

-- PALADIN HOLY - Healing and support
local PaladinHoly_TurtleWoW = {
    -- Base Stats
    Strength = 0,
    Agility = 0.05,
    Intellect = 1,
    Spirit = 0.28 * 1.3,  -- Meditation synergy
    Stamina = 0.1,
    
    -- Resources
    Mana = 0.009,
    Mp5 = 1.24 * 0.8,
    Health = 0.01,
    Hp5 = 1,
    
    -- Healing
    Healing = 0.54 * 1.1,
    
    -- Holy Shock: 43% coefficient
    -- Daybreak: 348-389 healing, 43% spellpower
    -- Illumination: 60% mana return (was 100%)
    
    -- Spell Stats
    SpellCritPercent = 0.46,
    
    -- Defense
    Armor = 0.005,
    DefensePercent = 0.05,
    DodgePercent = 0.05,
    ParryPercent = 0.05,
    BlockPercent = 0.01,
    
    -- Turtle WoW New Stats
    Meditation = 2.2,
    HastePercent = 0.45,  -- Lower value, less dependent on cast speed
}

-- PALADIN PROTECTION - Tank with spell threat
local PaladinProtection_TurtleWoW = {
    -- Base Stats
    IsOffHand = PawnIgnoreStatValue,
    Strength = 0.2,
    Agility = 0.6,
    Intellect = 0.5,
    Spirit = 0.05,
    Stamina = 1 * 1.2,
    
    -- Resources
    Mana = 0.045,
    Mp5 = 1,
    Health = 0.09,
    Hp5 = 2,
    
    -- Weapon Stats
    MeleeDps = 1.77,
    
    -- Attack Power
    Ap = 0.06,
    
    -- Physical Stats
    HitPercent = 0.16,
    CritPercent = 0.15,
    
    -- Spell (Consecration threat)
    SpellDamage = 0.44 * 0.5,
    HolySpellDamage = 0.44,
    SpellHitPercent = 0.78,
    SpellCritPercent = 0.6,
    SpellPenetration = 0.03,
    
    -- Holy Shield: 50% block (was 30%), 45% threat
    -- Bulwark: 43% spellpower
    -- Ironclad: 1-2% armor as healing power
    
    -- Defense (Patch 1.18.0 armor changes)
    Armor = 0.02 * 0.7,  -- Reduced due to DR
    DefensePercent = 0.7 * 1.8,
    DodgePercent = 0.7,
    ParryPercent = 0.6,
    BlockPercent = 0.6,
    BlockValue = 0.15 * 1.5,
    
    -- Resistances
    AllResist = 0.7,
    FireResist = 0.14,
    FrostResist = 0.14,
    ArcaneResist = 0.14,
    ShadowResist = 0.14,
    NatureResist = 0.14,
    
    -- Turtle WoW New Stats
    Meditation = 0,
    HastePercent = 0.6,
}

-- PALADIN RETRIBUTION - Crusader Strike focus
local PaladinRet_TurtleWoW = {
    -- Base Stats
    Strength = 1 * 1.3,  -- Crusader Strike 130%
    Agility = 0.64,
    Intellect = 0.34,
    Spirit = 0.05,
    Stamina = 0.1,
    
    -- Resources
    Mana = 0.032,
    Mp5 = 1,
    Health = 0.01,
    Hp5 = 1,
    
    -- Weapon Stats
    MeleeDps = 5.4,
    
    -- Attack Power
    Ap = 0.41 * 1.3,
    
    -- Physical Stats
    HitPercent = 0.84,
    CritPercent = 0.66,
    
    -- Spell
    SpellDamage = 0.33 * 1.43,  -- Seal of Command
    HolySpellDamage = 0.33 * 1.43,
    SpellHitPercent = 0.21,
    SpellCritPercent = 0.12,
    SpellPenetration = 0.015,
    
    -- Crusader Strike: 20% spellpower (was 33%)
    -- Seal of Righteousness: 12.5% x weapon speed
    -- Zeal: 3% attack speed per stack (9% max)
    
    -- Defense
    Armor = 0.005,
    DefensePercent = 0.05,
    DodgePercent = 0.05,
    ParryPercent = 0.05,
    
    -- Turtle WoW New Stats
    Meditation = 0,
    HastePercent = 1.1,
}

-- ========================================
-- PRIEST SPECIALIZATIONS (ALL PATCHES)
-- ========================================

-- PRIEST DISCIPLINE - Shield and mitigation
local PriestDiscipline_TurtleWoW = {
    -- Base Stats
    Strength = 0,
    Agility = 0.05,
    Intellect = 1,
    Spirit = 0.48 * 1.3 * 0.8,
    Stamina = 0.1,
    
    -- Resources
    Mana = 0.09,
    Mp5 = 1.19 * 0.8,
    Health = 0.01,
    Hp5 = 1,
    
    -- Healing
    Healing = 0.72 * 0.95,
    
    -- Power Word: Shield improvements
    -- Pain Suppression: 50% damage reduction
    
    -- Spell Stats
    SpellCritPercent = 0.32,
    
    -- Defense
    Armor = 0.005,
    DefensePercent = 0.05,
    DodgePercent = 0.05,
    
    -- Turtle WoW New Stats
    Meditation = 2.5,
    HastePercent = 0.55,  -- Moderate value for shield spam and healing
}

-- PRIEST HOLY - Pure healing
local PriestHoly_TurtleWoW = {
    -- Base Stats
    Strength = 0,
    Agility = 0.05,
    Intellect = 1 * 0.9,
    Spirit = 0.73 * 1.3 * 1.1,  -- High Spirit focus
    Stamina = 0.1,
    
    -- Resources
    Mana = 0.09,
    Mp5 = 1.35 * 0.8 * 2.0,
    Health = 0.01,
    Hp5 = 1,
    
    -- Healing
    Healing = 0.81 * 1.05,
    
    -- Circle of Healing: Smart heal
    -- Guardian Spirit: Death prevention
    
    -- Spell Stats
    SpellCritPercent = 0.24,
    
    -- Defense
    Armor = 0.005,
    DefensePercent = 0.05,
    DodgePercent = 0.05,
    
    -- Turtle WoW New Stats
    Meditation = 2.5,
    HastePercent = 0.6,  -- Important for faster heals
}

-- PRIEST SHADOW - DoT and burst
local PriestShadow_TurtleWoW = {
    -- Base Stats
    Strength = 0,
    Agility = 0.05,
    Intellect = 0.19,
    Spirit = 0.21 * 1.15,
    Stamina = 0.1,
    
    -- Resources
    Mana = 0.017,
    Mp5 = 1 * 0.9,
    Health = 0.01,
    Hp5 = 1,
    
    -- Spell Power
    SpellDamage = 1 * 1.15,  -- Shadow Form +15%
    ShadowSpellDamage = 1 * 1.667,  -- Mind Flay 66.7% increase
    
    -- Mind Blast: Major crit damage increase
    -- Vampiric Touch: Mana return to party
    
    -- Spell Stats
    SpellHitPercent = 1.12,
    SpellCritPercent = 0.76 * 1.4,  -- Mind Blast crits
    SpellPenetration = 0.08,
    
    -- Defense
    Armor = 0.005,
    DefensePercent = 0.05,
    DodgePercent = 0.05,
    
    -- Turtle WoW New Stats
    Meditation = 1.5,
    HastePercent = 0.65,  -- Important for Mind Flay and DoT ticks
}

-- ========================================
-- ROGUE SPECIALIZATIONS (ALL PATCHES)
-- ========================================

-- ROGUE ASSASSINATION - Poison focus
local RogueAssassination_TurtleWoW = {
    -- Base Stats
    Strength = 0.5,
    Agility = 1 * 1.1,
    Intellect = 0,
    Spirit = 0,
    Stamina = 0.1,
    
    -- Resources
    Health = 0.01,
    Hp5 = 1,
    
    -- Weapon Stats
    MeleeDps = 4.2,
    
    -- Attack Power
    Ap = 0.5,
    
    -- Noxious Assault: 35% AP coefficient
    -- Corrosive Poison: -5% AP scaling
    -- Vigor: +2 energy, no CD
    
    -- Physical Stats
    HitPercent = 0.84,
    CritPercent = 0.7 * 1.2,  -- Improved poisons
    
    -- Defense
    Armor = 0.005,
    DefensePercent = 0.05,
    DodgePercent = 0.05,
    ParryPercent = 0.05,
    
    -- Turtle WoW New Stats
    Meditation = 0,
    HastePercent = 1.0,
}

-- ROGUE COMBAT - Blade Flurry changes
local RogueCombat_TurtleWoW = {
    -- Base Stats
    Strength = 0.5,
    Agility = 1,
    Intellect = 0,
    Spirit = 0,
    Stamina = 0.1,
    
    -- Resources
    Health = 0.01,
    Hp5 = 1,
    
    -- Weapon Stats
    MeleeDps = 4.8,
    
    -- Attack Power
    Ap = 0.45 * 1.2,  -- Blade Flurry improvements
    
    -- Patch 1.18.0: Blade Flurry 4s CD, -30% energy regen, -20% damage
    -- Blade Rush: +2/5% attack speed
    
    -- Physical Stats
    HitPercent = 0.84,
    CritPercent = 0.66,
    
    -- Defense
    Armor = 0.005,
    DefensePercent = 0.05,
    DodgePercent = 0.05,
    ParryPercent = 0.05,
    
    -- Turtle WoW New Stats
    Meditation = 0,
    HastePercent = 1.2,
}

-- ROGUE SUBTLETY - Stealth and control
local RogueSubtlety_TurtleWoW = {
    -- Base Stats
    Strength = 0.5,
    Agility = 1 * 1.2,
    Intellect = 0,
    Spirit = 0,
    Stamina = 0.1,
    
    -- Resources
    Health = 0.01,
    Hp5 = 1,
    
    -- Weapon Stats
    MeleeDps = 4.0,
    
    -- Attack Power
    Ap = 0.4,
    
    -- Shadow of Death: 50-250% AP by CP
    -- Hemorrhage: 40 energy (was 45)
    -- Preparation: 7 min CD (was 10)
    
    -- Physical Stats
    HitPercent = 0.84,
    CritPercent = 0.75 * 0.9,
    
    -- Defense
    Armor = 0.005,
    DefensePercent = 0.05,
    DodgePercent = 0.05,
    ParryPercent = 0.05,
    
    -- Turtle WoW New Stats
    Meditation = 0,
    HastePercent = 0.8,
}

-- ========================================
-- SHAMAN SPECIALIZATIONS (ALL PATCHES)
-- ========================================

-- SHAMAN ELEMENTAL - Lightning and nature
local ShamanElemental_TurtleWoW = {
    -- Base Stats
    Strength = 0,
    Agility = 0.05,
    Intellect = 0.31,
    Spirit = 0.08 * 1.15,
    Stamina = 0.1,
    
    -- Resources
    Mana = 0.027,
    Mp5 = 1 * 0.9,
    Health = 0.01,
    Hp5 = 1,
    
    -- Spell Power
    SpellDamage = 1,
    NatureSpellDamage = 0.95 * 1.1,  -- Lightning Overload
    
    -- Chain Heal: 61.42% coefficient
    -- Earthquake: 60% coefficient
    -- Elemental Focus: 60% mana reduction (was 40%)
    
    -- Spell Stats
    SpellHitPercent = 1.21,
    SpellCritPercent = 0.59,
    SpellPenetration = 0.21,
    
    -- Defense
    Armor = 0.005,
    DefensePercent = 0.05,
    DodgePercent = 0.05,
    ParryPercent = 0.05,
    BlockPercent = 0.01,
    
    -- Turtle WoW New Stats
    Meditation = 1.5,
    HastePercent = 0.6,  -- Benefits from faster casting
}

-- SHAMAN ENHANCEMENT - Melee with spell support
local ShamanEnhance_TurtleWoW = {
    -- Base Stats
    Strength = 1,
    Agility = 0.87,
    Intellect = 0.34,
    Spirit = 0.05,
    Stamina = 0.1,
    
    -- Resources
    Mana = 0.032,
    Mp5 = 1,
    Health = 0.01,
    Hp5 = 1,
    
    -- Weapon Stats
    MeleeDps = 3.8,
    
    -- Attack Power with conversions
    Ap = 0.5 * 1.1,  -- 10% AP to spell
    
    -- Shield Conversions:
    -- Lightning: 4 AP = 1 damage
    -- Water: 20 AP = 1 mana
    -- Earth: 15 AP = 1 health
    
    -- Physical Stats
    HitPercent = 0.84,
    CritPercent = 0.65,
    
    -- Spell
    SpellDamage = 0.3 * 1.1,
    NatureSpellDamage = 0.3 * 1.25,  -- Stormstrike +25%
    SpellHitPercent = 0.34,
    SpellCritPercent = 0.17,
    
    -- Windfury: 20% proc (was 15%, then back to 20%)
    -- Stormstrike: 8s CD (was 20s, then 12s)
    -- Bloodlust: 15% self, 5% party
    
    -- Defense
    Armor = 0.005,
    DefensePercent = 0.05,
    DodgePercent = 0.05,
    ParryPercent = 0.05,
    BlockPercent = 0.01,
    
    -- Turtle WoW New Stats
    Meditation = 0,
    HastePercent = 1.1,
}

-- SHAMAN RESTORATION - Healing with shields
local ShamanRestoration_TurtleWoW = {
    -- Base Stats
    Strength = 0,
    Agility = 0.05,
    Intellect = 1,
    Spirit = 0.73 * 1.3,
    Stamina = 0.1,
    
    -- Resources
    Mana = 0.09,
    Mp5 = 1.55 * 0.8 * 2.5,  -- Water Shield value
    Health = 0.01,
    Hp5 = 1,
    
    -- Healing
    Healing = 0.9 * 0.95,
    
    -- Chain Heal: 3s cast (was 2.5s)
    -- Spirit Link: 35y range, 20s duration, 10 min CD
    -- Tidal Surge: 30% mana gain for 15% base
    
    -- Spell Stats
    SpellCritPercent = 0.24,
    
    -- Defense
    Armor = 0.005,
    DefensePercent = 0.05,
    DodgePercent = 0.05,
    ParryPercent = 0.05,
    BlockPercent = 0.01,
    
    -- Turtle WoW New Stats
    Meditation = 2.5,
    HastePercent = 0.5,  -- Moderate value for healing casts
}

-- ========================================
-- WARLOCK SPECIALIZATIONS (ALL PATCHES)
-- ========================================

-- WARLOCK AFFLICTION - DoT mastery
local WarlockAffliction_TurtleWoW = {
    -- Base Stats
    Strength = 0,
    Agility = 0.05,
    Intellect = 0.28,
    Spirit = 0.1 * 1.15,
    Stamina = 0.1,
    
    -- Resources
    Mana = 0.025,
    Mp5 = 0.8 * 0.9,
    Health = 0.01,
    Hp5 = 1,
    
    -- Spell Power
    SpellDamage = 1 * 1.2,  -- Dark Harvest
    ShadowSpellDamage = 1.02 * 1.167,  -- Drain Soul buff
    
    -- Drain Soul: 16.67% per tick coefficient
    -- Dark Harvest: 20% DoT acceleration
    -- Corruption: 1.5s cast (was 2s)
    -- Soul Siphon: +2-4% per Affliction effect
    
    -- Spell Stats
    SpellHitPercent = 1.21,
    SpellCritPercent = 0.36,
    SpellPenetration = 0.05,
    
    -- Defense
    Armor = 0.005,
    DefensePercent = 0.05,
    DodgePercent = 0.05,
    
    -- Turtle WoW New Stats
    Meditation = 1.5,
    HastePercent = 0.7,  -- Important for DoT efficiency and casting
}

-- WARLOCK DEMONOLOGY - Pet focus
local WarlockDemonology_TurtleWoW = {
    -- Base Stats
    Strength = 0,
    Agility = 0.05,
    Intellect = 0.3,
    Spirit = 0.1 * 1.15,
    Stamina = 0.2,  -- Pet tanking
    
    -- Resources
    Mana = 0.027,
    Mp5 = 0.8 * 0.9,
    Health = 0.01,
    Hp5 = 1,
    
    -- Spell Power
    SpellDamage = 1 * 1.05,  -- Master Demonologist
    FireSpellDamage = 0.80 * 1.3,  -- Felguard
    ShadowSpellDamage = 0.8 * 1.3,
    
    -- Demonic Sacrifice:
    -- Imp: +6% Fire damage
    -- Voidwalker: 3% Health/4 sec
    -- Succubus: +6% Shadow damage
    -- Felhunter: 2% Mana/4 sec
    
    -- Fel Intellect: 35% Int transfer, 75% regen while casting
    -- Fel Stamina: 35% Stamina transfer, -5% crit chance
    
    -- Spell Stats
    SpellHitPercent = 1.21,
    SpellCritPercent = 0.66 * 1.05,
    SpellPenetration = 0.06,
    
    -- Inferno: 10 min CD (was 20, then 1 hour)
    -- Avoidance: 80% AoE reduction (was 50%)
    
    -- Defense
    Armor = 0.005,
    DefensePercent = 0.05,
    DodgePercent = 0.05,
    
    -- Turtle WoW New Stats
    Meditation = 1.5,
    HastePercent = 0.6,  -- Moderate value for shadowbolts
}

-- WARLOCK DESTRUCTION - Fire and shadow burst
local WarlockDestruction_TurtleWoW = {
    -- Base Stats
    Strength = 0,
    Agility = 0.05,
    Intellect = 0.32,
    Spirit = 0.06 * 1.15,
    Stamina = 0.1,
    
    -- Resources
    Mana = 0.028,
    Mp5 = 0.9 * 0.9,
    Health = 0.01,
    Hp5 = 1,
    
    -- Spell Power
    SpellDamage = 1,
    FireSpellDamage = 0.23 * 1.6,  -- Conflagrate 60%
    ShadowSpellDamage = 0.95 * 1.2,  -- Shadowburn
    
    -- Soul Fire: 114% coefficient (was 125%), 30s CD (was 1 min)
    -- Searing Pain: Threat removed
    -- Firestone: +2% fire crit, 40% proc chance
    
    -- Spell Stats
    SpellHitPercent = 1.21,
    SpellCritPercent = 0.87,
    SpellPenetration = 0.04,
    
    -- Defense
    Armor = 0.005,
    DefensePercent = 0.05,
    DodgePercent = 0.05,
    
    -- Turtle WoW New Stats
    Meditation = 1.5,
    HastePercent = 0.75,  -- High value for faster casts
}

-- ========================================
-- WARRIOR SPECIALIZATIONS (ALL PATCHES)
-- ========================================

-- WARRIOR ARMS - Mortal Strike and control
local WarriorArms_TurtleWoW = {
    -- Base Stats
    Strength = 2.35 * 1.3,  -- Mortal Strike 130%
    Agility = 1.13,
    Intellect = 0,
    Spirit = 0,
    Stamina = 0.1,
    
    -- Resources
    Health = 0.01,
    Hp5 = 1,
    
    -- Weapon Stats
    MeleeDps = 6.8,
    
    -- Attack Power
    Ap = 1 * 1.3,
    
    -- Patch 1.18.0: Mortal Strike 115-130% weapon damage
    -- Master Strike: 35% weapon damage, 30s CD
    -- Slam: 65-100% weapon damage
    
    -- Physical Stats
    HitPercent = 1,
    CritPercent = 0.89 * 1.05,  -- Master of Arms
    
    -- Defense
    Armor = 0.005,
    DefensePercent = 0.05,
    DodgePercent = 0.05,
    ParryPercent = 0.05,
    
    -- Turtle WoW New Stats
    Meditation = 0,
    HastePercent = 1.1,
    
    -- Rend: 5% AP per tick scaling
}

-- WARRIOR FURY - Dual wield and rage
local WarriorFury_TurtleWoW = {
    -- Base Stats
    Strength = 2.27 * 1.8,
    Agility = 1.15,
    Intellect = 0,
    Spirit = 0,
    Stamina = 0.1,
    
    -- Resources
    Health = 0.01,
    Hp5 = 1,
    
    -- Weapon Stats
    MeleeDps = 5.9,
    
    -- Attack Power
    Ap = 0.45,  -- Bloodthirst 30% coefficient
    
    -- Patch 1.18.0: Execute CD removed
    -- Blood Drinker: 1-2% heal on all attacks
    -- Bloodthirst: 10% movement (was 5%)
    
    -- Physical Stats
    HitPercent = 1,
    CritPercent = 0.84 * 1.25,  -- Flurry
    
    -- Defense
    Armor = 0.005,
    DefensePercent = 0.05,
    DodgePercent = 0.05,
    ParryPercent = 0.05,
    
    -- Turtle WoW New Stats
    Meditation = 0,
    HastePercent = 1.2,
    
    -- Enrage: 15% damage (was 25%)
}

-- WARRIOR PROTECTION - Tank with threat
local WarriorProtection_TurtleWoW = {
    -- Base Stats
    IsOffHand = PawnIgnoreStatValue,
    Strength = 0.33 * 0.5,
    Agility = 0.59,
    Intellect = 0,
    Spirit = 0,
    Stamina = 1 * 1.5,
    
    -- Resources
    Health = 0.1,
    Hp5 = 2,
    
    -- Weapon Stats
    MeleeDps = 2,
    
    -- Attack Power
    Ap = 0.06,
    
    -- Physical Stats
    HitPercent = 0.16,
    CritPercent = 0.15,
    
    -- Defense (Patch 1.18.0 armor changes)
    Armor = 0.02 * 0.7,  -- Reduced due to 75% DR removal
    DefensePercent = 0.86 * 2.0,
    DodgePercent = 0.7 * 1.5,
    ParryPercent = 0.67 * 1.5,
    BlockPercent = 0.65 * 2.0,
    BlockValue = 0.35 * 1.75,  -- Shield Slam
    
    -- Resistances
    AllResist = 0.7,
    FireResist = 0.14,
    FrostResist = 0.14,
    ArcaneResist = 0.14,
    ShadowResist = 0.14,
    NatureResist = 0.14,
    
    -- Turtle WoW New Stats
    Meditation = 0,
    HastePercent = 0.6,
    
    -- Sunder Armor: 10 rage (was 15)
    -- Defensive Tactics: 55-165% threat
    -- Concussion Blow: +10 rage generation
}

-- ========================================
-- HELPER FUNCTIONS
-- ========================================

local function MergeScaling(base, override)
    local result = {}
    
    -- Copy base values
    for stat, value in pairs(base) do
        result[stat] = value
    end
    
    -- Apply overrides
    if override then
        for stat, value in pairs(override) do
            result[stat] = value
        end
    end
    
    return result
end

-- ========================================
-- MAIN IMPLEMENTATION FUNCTION
-- ========================================

function ApplyTurtleWowScaling(class, spec)
    local scalingMap = {
        [11] = {  -- Druid
            [1] = DruidBalance_TurtleWoW,
            [2] = DruidFeral_TurtleWoW,
            [3] = DruidFeralTank_TurtleWoW,
            [4] = DruidRestoration_TurtleWoW,
        },
        [3] = {  -- Hunter
            [1] = HunterBM_TurtleWoW,
            [2] = HunterMM_TurtleWoW,
            [3] = HunterSurvival_TurtleWoW,
        },
        [8] = {  -- Mage
            [1] = MageArcane_TurtleWoW,
            [2] = MageFire_TurtleWoW,
            [3] = MageFrost_TurtleWoW,
        },
        [2] = {  -- Paladin
            [1] = PaladinHoly_TurtleWoW,
            [2] = PaladinProtection_TurtleWoW,
            [3] = PaladinRet_TurtleWoW,
        },
        [5] = {  -- Priest
            [1] = PriestDiscipline_TurtleWoW,
            [2] = PriestHoly_TurtleWoW,
            [3] = PriestShadow_TurtleWoW,
        },
        [4] = {  -- Rogue
            [1] = RogueAssassination_TurtleWoW,
            [2] = RogueCombat_TurtleWoW,
            [3] = RogueSubtlety_TurtleWoW,
        },
        [7] = {  -- Shaman
            [1] = ShamanElemental_TurtleWoW,
            [2] = ShamanEnhance_TurtleWoW,
            [3] = ShamanRestoration_TurtleWoW,
        },
        [9] = {  -- Warlock
            [1] = WarlockAffliction_TurtleWoW,
            [2] = WarlockDemonology_TurtleWoW,
            [3] = WarlockDestruction_TurtleWoW,
        },
        [1] = {  -- Warrior
            [1] = WarriorArms_TurtleWoW,
            [2] = WarriorFury_TurtleWoW,
            [3] = WarriorProtection_TurtleWoW,
        },
    }
    
    -- Get base scaling
    local baseScaling = MergeScaling(DefaultScaling, {})
    
    -- Apply class/spec specific scaling
    if scalingMap[class] and scalingMap[class][spec] then
        return MergeScaling(baseScaling, scalingMap[class][spec])
    end
    
    return baseScaling
end

-- ========================================
-- INTEGRATION WITH PAWN ADDON
-- ========================================

function IntegrateTurtleWowScaling()
    if PawnAddPluginScaleFromTemplate then
        local oldFunc = PawnAddPluginScaleFromTemplate
        PawnAddPluginScaleFromTemplate = function(provider, class, spec, values)
            -- Get complete Turtle WoW scaling
            local turtleValues = ApplyTurtleWowScaling(class, spec)
            
            if turtleValues then
                -- Replace with Turtle WoW values
                values = turtleValues
            end
            
            -- Call original function
            return oldFunc(provider, class, spec, values)
        end
    end
end

-- Auto-integrate when loaded
if PawnVersion then
    IntegrateTurtleWowScaling()
end

-- ========================================
-- PATCH NOTES SUMMARY
-- ========================================
--[[
PATCH 1.16.0-1.16.1:
- New stats: Meditation (mana regen in combat) and HastePercent
- Initial class balance changes

PATCH 1.17.0:
- Major talent reworks
- Spell coefficient updates

PATCH 1.17.2:
- Hit cap reduced from 9% to 8%
- Weapon skill soft cap removed
- Rage generation formula: 90% gear + 10% weapon speed
- Defense/dodge/block ratings more efficient
- Racial weapon skills nerfed from +5 to +3

PATCH 1.17.2 Updates (October/November 2024):
- Multiple balance adjustments
- DoT duration changes
- Threat modifier updates

PATCH 1.18.0:
- ARMOR CAP REMOVED (was 75%)
- Diminishing returns beyond 75% DR
- Execute cooldown removed
- Major ability updates for all classes
- Pet scaling improvements

CHANGES IN THIS VERSION:
- Removed all Rating system values (didn't exist in Vanilla)
- Added HastePercent values for all caster specs
- Converted all ratings to direct percentage values
--]]