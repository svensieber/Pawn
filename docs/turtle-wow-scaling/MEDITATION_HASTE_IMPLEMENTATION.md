# Turtle WoW: Meditation & Haste Implementation Guide für Pawn

## 🆕 Patch 1.16.0 - Neue Stats

### **Meditation (Mana-Regeneration im Kampf)**

#### Was ist Meditation?
- Erlaubt Mana-Regeneration während des Kampfes
- Basiert auf 5% der out-of-combat Regeneration
- **Skaliert mit Spirit** - macht Spirit wertvoller!
- Stackt mit Priest/Druid Meditation Talenten

#### Beispielwerte:
```
Generic Items: 1-3% Meditation
Special Items: 5% Meditation  
Set Bonuses: 10-30% total
Green Dragon Mail: 5% pro Teil (30% mit 3 Teilen)
```

#### Pawn Implementation:
```lua
-- In ScaleTemplates.lua oder ClassicHawsJon.lua hinzufügen:

-- Neue Stat definieren
["Meditation"] = 2.0,  -- Basis-Wert ähnlich Mp5

-- Spirit-Wert erhöhen wenn Meditation vorhanden
["Spirit"] = 0.87 * 1.3,  -- 30% wertvoller mit Meditation

-- Für Caster-Klassen (Beispiel Priest):
PriestHoly_TurtleWoW = {
    Spirit = 0.73 * 1.3,      -- Original * 1.3 (Meditation Synergie)
    Mp5 = 1.35 * 0.8,         -- Mp5 weniger wichtig mit Meditation
    Meditation = 2.5,         -- Neuer Stat-Wert
}
```

### **Haste (Angriffsgeschwindigkeit)**

#### Was ist Haste?
- Erhöht Melee & Ranged Attack Speed
- **NICHT** Spell Cast Speed (in 1.16.0)
- Stackt mit Diminishing Returns
- 1-2% für normale Items, bis 5% für spezielle

#### Pawn Implementation:
```lua
-- Neue Stat definieren
["HastePercent"] = 1.2,  -- Zwischen Crit und Hit für Melee

-- Für Physical DPS Klassen (Beispiel Warrior):
WarriorFury_TurtleWoW = {
    HasteRating = HasteRatingPer * 0.5,  -- Original Haste Rating
    HastePercent = 1.2,                  -- Neue Haste % Stat
    -- Diminishing Returns bei >10%
}

-- Für Hunter:
HunterBM_TurtleWoW = {
    HastePercent = 1.1,  -- Etwas weniger wertvoll für Ranged
}
```

## 📊 Komplette Integration in ClassicHawsJon.lua

### Schritt 1: Stats definieren (Zeile ~45)
```lua
-- Turtle WoW neue Stats
if VgerCore.IsClassic then
    -- Existing stats...
    
    -- TURTLE WOW 1.16.0 ADDITIONS
    ["Meditation"] = 0,  -- Wird pro Klasse gesetzt
    ["HastePercent"] = 0, -- Wird pro Klasse gesetzt
end
```

### Schritt 2: Klassenspezifische Werte

#### **Heiler (Priest, Druid, Paladin, Shaman)**
```lua
-- Hoher Meditation Wert, Spirit Synergie
Meditation = 2.5,
Spirit = Spirit * 1.3,  -- 30% Bonus
Mp5 = Mp5 * 0.8,        -- 20% weniger wichtig
```

#### **Caster DPS (Mage, Warlock, Priest Shadow)**
```lua
-- Mittlerer Meditation Wert
Meditation = 1.5,
Spirit = Spirit * 1.15,  -- 15% Bonus
Mp5 = Mp5 * 0.9,         -- 10% weniger wichtig
```

#### **Melee DPS (Warrior, Rogue, Enhancement Shaman)**
```lua
-- Hoher Haste Wert
HastePercent = 1.2,
HasteRating = HasteRating * 0.8,  -- Old Haste weniger wichtig
```

#### **Hunter**
```lua
-- Mittlerer Haste Wert
HastePercent = 1.1,
HasteRating = HasteRating * 0.85,
```

#### **Tanks**
```lua
-- Niedriger Haste Wert (für Threat)
HastePercent = 0.6,
```

## 🔧 Vollständiges Beispiel

```lua
-- Druid Restoration mit Meditation
PawnAddPluginScaleFromTemplate(
    ScaleProviderName,
    11, -- Druid
    4, -- Restoration
    { 
        -- Original Werte
        Intellect=1, 
        Mana=0.09, 
        Spirit=0.87 * 1.3,  -- TURTLE: +30% durch Meditation
        Mp5=1.7 * 0.8,      -- TURTLE: -20% weniger wichtig
        Healing=1.21,
        
        -- TURTLE WOW 1.16.0 - Neue Stats
        Meditation=2.5,     -- Sehr wichtig für Heiler
        HastePercent=0,     -- Nicht relevant für Caster
        
        -- Rest der Stats...
    }
)

-- Warrior Fury mit Haste
PawnAddPluginScaleFromTemplate(
    ScaleProviderName,
    1, -- Warrior
    2, -- Fury
    {
        Strength=2.27,
        Agility=1.15,
        
        -- TURTLE WOW 1.16.0 - Neue Stats
        HastePercent=1.2,   -- Sehr wichtig für Fury
        Meditation=0,       -- Nicht relevant für Warrior
        
        -- Angepasste alte Stats
        HasteRating=HasteRatingPer*0.3*0.8,  -- Weniger wichtig
        
        -- Rest der Stats...
    }
)
```

## ⚠️ Wichtige Hinweise

1. **Meditation** macht Spirit ~30% wertvoller für Caster
2. **Haste%** ist ANDERS als HasteRating - es ist eine neue Stat!
3. **Diminishing Returns** bei Haste über 10% beachten
4. **Mp5 wird weniger wichtig** mit Meditation Items
5. Diese Stats sind **Turtle WoW exklusiv** - nicht in Classic Era!

## 📝 Testing Commands

```lua
/script print("Meditation Test")
/run PawnTest("Meditation", 5)  -- Testet 5% Meditation

/script print("Haste Test")  
/run PawnTest("HastePercent", 2)  -- Testet 2% Haste
```