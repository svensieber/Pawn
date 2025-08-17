# Turtle WoW Allgemeine System-Änderungen für Pawn Scaling

## 🔧 Systemweite Anpassungen (betreffen ALLE Klassen)

### **Weapon Skill Formula (Patch 1.17.2)**
```
ALT (Classic):
- Hit Cap vs Bosses: 9%
- Soft Cap bei 305 Weapon Skill
- Racial Weapon Skills: +5

NEU (Turtle WoW):
- Hit Cap vs Bosses: 8% (1% weniger!)
- Lineares Scaling: 0.2% Hit + 2% Glancing Reduction pro Punkt
- Racial Weapon Skills: +3 (statt +5)
- Kein Soft Cap mehr bei 305
```

**Pawn Anpassung:**
```lua
-- Classic Era / Original
HitRatingPer = 9.37931  -- für 9% Hit Cap

-- Turtle WoW Anpassung
HitRatingPer = 8.33716  -- für 8% Hit Cap (ca. 11% weniger wertvoll)
```

### **Armor Formula**
```
ALT:
- Hard Cap bei 75% Damage Reduction
- Lineares Scaling bis zum Cap

NEU:
- 75% Hard Cap entfernt
- Diminishing Returns über 75%
```

**Pawn Anpassung:**
```lua
-- Armor wird weniger wertvoll über 75% DR
-- Für Tanks:
Armor = 0.1 * 0.8  -- 20% Wertreduktion für hohe Armor-Werte
```

### **Defense & Avoidance Changes**

#### **Defense Rating**
- Paladin Anticipation: 2/4/6/8/10 → 7/14/20 (massiv gebufft)
- Weniger Defense Rating benötigt für Cap

```lua
-- Original
DefenseRatingPer = 1.5

-- Turtle WoW
DefenseRatingPer = 1.2  -- 20% effizienter
```

#### **Dodge Rating**
- Hunter Improved Aspect of the Monkey: 1-5% → 2/4/6%
- Druid Feral Adrenaline: +15/30/45% on crit
- Shaman Ancestral Guardian: 5% → 6%

```lua
-- Dodge wird wertvoller für bestimmte Klassen
DodgeRatingPer = 9.44 * 1.1  -- 10% wertvoller
```

#### **Parry Rating**
- Warrior Die by the Sword: +20% während Retaliation
- Hunter Deterrence: +2% Parry

```lua
ParryRatingPer = 9.44  -- Bleibt ähnlich
```

#### **Block Rating & Block Value**
- Paladin Holy Shield: 30% → 50% Block Chance
- Paladin Righteous Strikes: 1-5% per Zeal Stack
- Shaman Shield Specialization: 5-25% → 6-30% Block Damage
- Warrior Shield Specialization: 1-5 Rage on Block
- Warrior Shield Slam: AP scaling zu Block Value

```lua
-- Block wird DEUTLICH wertvoller
BlockRatingPer = 6.9 * 1.5  -- 50% wertvoller
BlockValue = 0.65 * 1.3  -- 30% wertvoller (AP scaling)
```

### **Resistance Changes**
- Generell weniger wichtig in Turtle WoW
- Mehr Mechaniken umgehen Resistances

```lua
-- Resistances werden weniger wertvoll
AllResist = 0.2 * 0.7  -- 30% weniger wertvoll
FireResist = 0.04 * 0.7
-- etc.
```

## 📊 Zusammenfassung der Multiplikatoren

### **Für ALLE Klassen anwenden:**

```lua
-- Turtle WoW General System Multipliers
TurtleWoW_SystemMultipliers = {
    -- Hit & Expertise
    HitRating = 0.89,        -- 8% statt 9% Cap
    SpellHitRating = 0.89,   -- Gleiche Anpassung
    ExpertiseRating = 1.0,   -- Bleibt gleich
    
    -- Defense & Avoidance
    DefenseRating = 1.2,     -- Effizienter
    DodgeRating = 1.1,       -- Wertvoller
    ParryRating = 1.0,       -- Gleich
    BlockRating = 1.5,       -- Viel wertvoller
    BlockValue = 1.3,        -- AP scaling
    
    -- Armor
    Armor = 0.8,             -- DR über 75%
    
    -- Resistances
    AllResist = 0.7,         -- Weniger wichtig
    FireResist = 0.7,
    FrostResist = 0.7,
    ArcaneResist = 0.7,
    ShadowResist = 0.7,
    NatureResist = 0.7,
    
    -- Weapon Skills (Racials)
    -- Humans: Swords/Maces +3 statt +5
    -- Orcs: Axes +3 statt +5
    -- etc.
}
```

## 🔨 Implementierung in ClassicHawsJon.lua

### **Schritt 1: Rating Conversions anpassen**
```lua
-- Zeile 24-43 in ClassicHawsJon.lua
if VgerCore.IsClassic then
    -- TURTLE WOW ANPASSUNGEN
    HitRatingPer = 8.33716      -- statt 9.37931
    SpellHitRatingPer = 7.11    -- statt 8
    CritRatingPer = 8.5         -- bleibt
    SpellCritRatingPer = 8      -- bleibt
    HasteRatingPer = 8.03       -- bleibt
    SpellHasteRatingPer = 8.03  -- bleibt
    ExpertiseRatingPer = 2.34483 -- bleibt
    ArmorPenetrationPer = 3.75  -- bleibt
    SpellPenetrationPer = 1     -- bleibt
    DefenseRatingPer = 1.2      -- statt 1.5
    DodgeRatingPer = 8.58       -- statt 9.44
    ParryRatingPer = 9.44       -- bleibt
    BlockRatingPer = 4.6        -- statt 6.9 (wertvoller!)
end
```

### **Schritt 2: Für jede Klasse/Spec anwenden**
```lua
-- Beispiel für Warrior Protection
{ 
    -- Original Werte
    Stamina=1, 
    Armor=0.02,
    DefenseRating=DefenseRatingPer*0.7,
    DodgeRating=DodgeRatingPer*0.7,
    ParryRating=ParryRatingPer*0.6,
    BlockRating=BlockRatingPer*0.6,
    BlockValue=0.15,
    
    -- Mit Turtle WoW Anpassungen:
    Stamina=1,
    Armor=0.02 * 0.8,  -- DR über 75%
    DefenseRating=DefenseRatingPer*0.7 * 1.2,  -- Effizienter
    DodgeRating=DodgeRatingPer*0.7 * 1.1,      -- Wertvoller
    ParryRating=ParryRatingPer*0.6,            -- Gleich
    BlockRating=BlockRatingPer*0.6 * 1.5,      -- Viel wertvoller
    BlockValue=0.15 * 1.3,                     -- AP scaling
}
```

## ⚠️ Wichtige Hinweise

1. **Diese Änderungen betreffen ALLE Klassen**
2. **Müssen VOR den klassenspezifischen Anpassungen angewendet werden**
3. **Hit Cap Reduktion ist besonders wichtig für DPS-Klassen**
4. **Block-Änderungen sind besonders wichtig für Tanks**

Diese allgemeinen Anpassungen bilden die Basis, auf der dann die klassenspezifischen Änderungen aufbauen!