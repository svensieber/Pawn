# Turtle WoW Scaling Implementation Guide für Pawn

## 🎯 Umsetzungsstrategie

### 1. **Scaling-Modul erstellen**
Erstelle eine neue Datei `TurtleWowScaling.lua` die alle Turtle WoW spezifischen Anpassungen enthält.

### 2. **Klassenspezifische Scaling-Werte**

#### **Struktur für Scaling-Anpassungen:**

```lua
PawnTurtleWowScaling = {
    -- Druid Scaling
    ["DRUID"] = {
        ["Balance"] = {
            -- Spellpower coefficients from patches
            ["SpellDamage"] = 0.855 * 1.2,  -- Base * Turtle modifier
            ["CritRating"] = 1.03,           -- +3% from Moonkin aura
            ["HasteRating"] = 1.05,          -- Nature's Grace improvements
        },
        ["Feral"] = {
            ["Ap"] = 0.5 * 1.12,             -- Swipe 6%, Rake 12% scaling
            ["CritRating"] = 1.1,            -- Primal Fury improvements
            ["Agility"] = 1.15,              -- Blood Frenzy bonus
        },
        ["Restoration"] = {
            ["Healing"] = 0.455 * 1.2,       -- +20% Spirit bonus from Tree
            ["Spirit"] = 1.2,                -- Tree of Life scaling
            ["Mp5"] = 2.8,                   -- Improved regen
        }
    },
    
    -- Hunter Scaling  
    ["HUNTER"] = {
        ["Beast Mastery"] = {
            ["Rap"] = 0.4 * 1.25,            -- Pet 25% AP inheritance
            ["Ap"] = 0.5 * 1.12,             -- Spirit Bond 12% scaling
            ["CritRating"] = 1.06,           -- Bestial Precision 6%
        },
        ["Marksmanship"] = {
            ["Rap"] = 0.4 * 1.055,           -- Trueshot Aura 55 AP + 5%
            ["HitRating"] = 1.08,            -- 8% from talents
        },
        ["Survival"] = {
            ["Agility"] = 1.1,               -- Lightning Reflexes
            ["CritRating"] = 1.06,           -- Savage Strikes
        }
    },
    
    -- Mage Scaling
    ["MAGE"] = {
        ["Arcane"] = {
            ["SpellDamage"] = 0.855 * 1.328, -- Arcane Missiles 32.8%
            ["CritRating"] = 1.06,           -- Arcane Impact 6%
            ["Intellect"] = 1.15,            -- Brilliance Aura
        },
        ["Fire"] = {
            ["FireSpellDamage"] = 0.7 * 1.25, -- Ignite improvements
            ["CritRating"] = 1.1,             -- Critical Mass
        },
        ["Frost"] = {
            ["FrostSpellDamage"] = 0.7 * 1.2, -- Winter's Chill
            ["CritRating"] = 1.05,            -- Shatter combos
        }
    },
    
    -- Paladin Scaling
    ["PALADIN"] = {
        ["Holy"] = {
            ["Healing"] = 0.455 * 1.35,      -- Holy Light 35% coefficient
            ["Intellect"] = 1.2,             -- Divine Intellect
            ["CritRating"] = 1.05,           -- Holy Power
        },
        ["Protection"] = {
            ["BlockRating"] = 1.2,           -- Holy Shield improvements
            ["SpellDamage"] = 0.855 * 0.9,   -- Consecration 90%
        },
        ["Retribution"] = {
            ["Ap"] = 0.5 * 1.2,              -- Crusader Strike scaling
            ["SpellDamage"] = 0.855 * 0.43,  -- Seal of Command 43%
        }
    },
    
    -- Priest Scaling
    ["PRIEST"] = {
        ["Discipline"] = {
            ["Healing"] = 0.455 * 1.35,      -- PW:Shield 35% coefficient
            ["SpellDamage"] = 0.855 * 0.6,   -- Mind Blast 60%
        },
        ["Holy"] = {
            ["Healing"] = 0.455 * 1.3,       -- Spiritual Healing 30%
            ["Spirit"] = 1.25,               -- Spiritual Guidance
        },
        ["Shadow"] = {
            ["ShadowSpellDamage"] = 0.7 * 1.75, -- Mind Flay 75%
            ["SpellDamage"] = 0.855 * 1.15,  -- Shadow Form 15%
        }
    },
    
    -- Rogue Scaling
    ["ROGUE"] = {
        ["Assassination"] = {
            ["Ap"] = 0.5 * 1.35,             -- Envenom/poisons
            ["CritRating"] = 1.05,           -- Improved poisons
        },
        ["Combat"] = {
            ["Ap"] = 0.5 * 1.2,              -- Blade Flurry
            ["HasteRating"] = 1.05,          -- Blade Flurry ICD
        },
        ["Subtlety"] = {
            ["Ap"] = 0.5 * 1.5,              -- Shadow of Death 50-250%
            ["Agility"] = 1.1,              -- Improved stealth
        }
    },
    
    -- Shaman Scaling
    ["SHAMAN"] = {
        ["Elemental"] = {
            ["SpellDamage"] = 0.855 * 1.15,  -- Elemental Fury 15%
            ["NatureSpellDamage"] = 0.7 * 1.25, -- Stormstrike 25%
        },
        ["Enhancement"] = {
            ["Ap"] = 0.5 * 1.1,              -- AP to spell conversions
            ["SpellDamage"] = 0.855 * 0.1,   -- 10% AP to spell
        },
        ["Restoration"] = {
            ["Healing"] = 0.455 * 1.6142,    -- Chain Heal 61.42%
            ["Mp5"] = 3.0,                   -- Water Shield
        }
    },
    
    -- Warlock Scaling
    ["WARLOCK"] = {
        ["Affliction"] = {
            ["SpellDamage"] = 0.855 * 1.2,   -- DoT improvements
            ["ShadowSpellDamage"] = 0.7 * 1.1667, -- Drain Soul 16.67%
        },
        ["Demonology"] = {
            ["SpellDamage"] = 0.855 * 1.6,   -- Pet 60% spell transfer
            ["Stamina"] = 1.35,              -- Fel Stamina 35%
        },
        ["Destruction"] = {
            ["FireSpellDamage"] = 0.7 * 1.25, -- Soul Fire 125%
            ["CritRating"] = 1.02,           -- Firestone 2%
        }
    },
    
    -- Warrior Scaling
    ["WARRIOR"] = {
        ["Arms"] = {
            ["Ap"] = 0.5 * 1.3,              -- Mortal Strike 130%
            ["CritRating"] = 1.05,           -- Master of Arms 5%
        },
        ["Fury"] = {
            ["Ap"] = 0.5 * 1.3,              -- Bloodthirst 30%
            ["HasteRating"] = 1.1,           -- Flurry
        },
        ["Protection"] = {
            ["BlockValue"] = 0.65 * 1.2,     -- Shield Slam
            ["DefenseRating"] = 1.1,         -- Defensive Stance
        }
    }
}
```

### 3. **Integration in Pawn**

#### **In Core.lua oder neuer TurtleWowScaling.lua:**

```lua
function PawnApplyTurtleWowScaling(ScaleValues, ClassID, SpecID)
    local className = select(2, GetClassInfo(ClassID))
    local specName = GetSpecializationNameForSpecID(SpecID)
    
    if not PawnTurtleWowScaling[className] then return ScaleValues end
    if not PawnTurtleWowScaling[className][specName] then return ScaleValues end
    
    local scaling = PawnTurtleWowScaling[className][specName]
    
    for stat, multiplier in pairs(scaling) do
        if ScaleValues[stat] then
            ScaleValues[stat] = ScaleValues[stat] * multiplier
        else
            ScaleValues[stat] = multiplier
        end
    end
    
    return ScaleValues
end
```

### 4. **Patch-basierte Anpassungen**

```lua
-- Patch progression tracking
PawnTurtleWowPatchLevel = "1.18.0"  -- Current patch

function GetPatchScaling(patch)
    local scalingModifiers = {
        ["1.16.1"] = 1.0,
        ["1.17.0"] = 1.05,
        ["1.17.2"] = 1.1,
        ["1.18.0"] = 1.15
    }
    return scalingModifiers[patch] or 1.0
end
```

### 5. **UI Integration**

In PawnUI.lua eine Option hinzufügen:

```lua
-- Turtle WoW Scaling Toggle
PawnOptions.UseTurtleWowScaling = true

function PawnUI_ToggleTurtleScaling()
    PawnOptions.UseTurtleWowScaling = not PawnOptions.UseTurtleWowScaling
    PawnRecalculateScaleValues()
end
```

### 6. **Verwendung der YAML-Daten**

Die YAML-Dateien können als Referenz verwendet werden:

1. **Manuelle Übertragung**: Werte aus YAML in Lua-Tables übertragen
2. **Automatisiertes Script**: Python/Node.js Script zur Konvertierung YAML → Lua
3. **Ingame-Kommandos**: `/pawn turtlescale update` zum Neuladen

### 7. **Testing & Validierung**

```lua
-- Test function for scaling values
function PawnTestTurtleScaling()
    local testClasses = {
        {class = "DRUID", spec = "Balance"},
        {class = "HUNTER", spec = "Beast Mastery"},
        -- etc.
    }
    
    for _, test in pairs(testClasses) do
        print("Testing:", test.class, test.spec)
        -- Apply scaling and verify values
    end
end
```

## 📋 Implementierungs-Checkliste

- [ ] TurtleWowScaling.lua erstellen
- [ ] Scaling-Werte aus YAML übertragen
- [ ] Integration in ScaleTemplates.lua
- [ ] UI-Option für Turtle WoW Mode
- [ ] Test-Suite für alle Klassen
- [ ] Dokumentation aktualisieren
- [ ] Version für Turtle WoW Client anpassen

## 🔧 Nächste Schritte

1. **Basis-Modul erstellen** mit grundlegenden Scaling-Werten
2. **Klassenweise implementieren** (eine Klasse nach der anderen)
3. **Ingame testen** mit verschiedenen Items
4. **Community-Feedback** einholen und anpassen

Diese Struktur ermöglicht es, die Turtle WoW Anpassungen modular und wartbar zu implementieren.