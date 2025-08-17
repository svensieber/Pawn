# Pawn Vanilla Backport - Detaillierte Implementierungsphasen

## 📋 Vorbereitende Informationsbeschaffung

### Benötigte Dokumentation & Ressourcen

1. **Turtle WoW Spezifika**
   - [ ] Turtle WoW 1.18.0 Changelog (Custom Items, neue Stats)
   - [ ] Turtle WoW API Dokumentation (TURTLE_WOW_VERSION Features)
   - [ ] Liste aller Custom Items mit Stats
   - [ ] Neue Tier-Sets (T0.5, Custom Sets)
   - [ ] Class Balance Changes vs Vanilla

2. **Vanilla 1.12 Referenzen**
   - [ ] WoW 1.12.1 API Dokumentation
   - [ ] Vanilla Stat-Formeln (Hit/Crit Caps)
   - [ ] Vanilla ItemString Format
   - [ ] Event-Liste 1.12

3. **Scaling-Daten**
   - [ ] Classic Era Theorycrafting Spreadsheets
   - [ ] Turtle WoW Discord Klassenguides
   - [ ] BiS-Listen für alle Klassen
   - [ ] Stat-Weights aus SimCraft-Vanilla

---

## PHASE 0: Projekt-Setup & Analyse (6h)

### 0.1 Environment Setup (2h)
```bash
# Git Setup
git checkout -b vanilla-backport
git submodule add https://github.com/VgerMods/VgerCore VgerCore-Vanilla

# Verzeichnisstruktur
mkdir -p vanilla/{core,ui,parsing,scales}
mkdir -p tests/vanilla
mkdir -p docs/vanilla
```

**Deliverables:**
- [ ] Git Branch erstellt
- [ ] Vanilla Test-Client installiert
- [ ] Turtle WoW Client Setup
- [ ] DevTools Addons (BugSack, DevTools)

### 0.2 Codebase Analyse (2h)
- [ ] Dependency Graph erstellen
- [ ] Funktions-Aufruf-Hierarchie dokumentieren
- [ ] Modern API Usage Report generieren
```lua
-- Tool: API Usage Scanner
local modernAPIs = {
    "C_Item", "C_ArtifactUI", "C_Timer",
    "TooltipUtil", "ProcessInfo", "SetItemByID"
}
-- Scan all .lua files for usage
```

**Output:** `docs/vanilla/API_USAGE_REPORT.md`

### 0.3 Test-Infrastruktur (2h)
- [ ] Test-Charaktere erstellen (alle Klassen)
- [ ] Test-Item-Set zusammenstellen
- [ ] Makros für Testfälle schreiben
```lua
/script PawnTest_AllSlots()
/script PawnTest_TooltipDisplay()
/script PawnTest_StatParsing("item:12345")
```

---

## PHASE 1: Core System Vorbereitung (10h)

### 1.1 VgerCore Fork (3h)

#### 1.1.1 Version Detection
```lua
-- VgerCore/VgerCore-Vanilla.lua
VgerCore.BuildNumber = select(4, GetBuildInfo())
VgerCore.IsVanilla = (VgerCore.BuildNumber < 6000)
VgerCore.IsTurtleWoW = (TURTLE_WOW_VERSION ~= nil)
VgerCore.TurtleVersion = TURTLE_WOW_VERSION or 0

-- Feature Flags
VgerCore.Features = {
    RangedSlot = true,           -- Slot 18
    Specializations = false,     
    Reforging = false,
    TransmogCollection = false,
    ItemUpgrade = false,
    Artifacts = false,
    Azerite = false,
    Corruptions = false
}
```

#### 1.1.2 API Compatibility Layer
```lua
-- VgerCore/Compat.lua
VgerCore.GetItemInfo = function(itemLink)
    if C_Item and C_Item.GetItemInfo then
        return C_Item.GetItemInfo(itemLink)
    else
        return GetItemInfo(itemLink)
    end
end
```

**Tests:**
- [ ] Version Detection korrekt
- [ ] Feature Flags validiert
- [ ] API Wrapper funktional

### 1.2 Event System Migration (4h)

#### 1.2.1 Event Mapping Table
```lua
PawnEventMap = {
    -- Modern -> Vanilla
    ["PLAYER_EQUIPMENT_CHANGED"] = "UNIT_INVENTORY_CHANGED",
    ["ITEM_UPGRADE_MASTER_UPDATE"] = nil,  -- Doesn't exist
    ["ARTIFACT_UPDATE"] = nil,              -- Remove
    ["AZERITE_EMPOWERED_ITEM_SELECTION_UPDATED"] = nil,
}
```

#### 1.2.2 Event Handler Refactoring
```lua
-- Centralized Event Handler with Debouncing
PawnEventHandler = {
    timers = {},
    
    Register = function(self, event, handler, debounce)
        if PawnEventMap[event] then
            event = PawnEventMap[event]
        end
        
        if not event then return end  -- Event doesn't exist in Vanilla
        
        frame:RegisterEvent(event)
        self[event] = handler
        if debounce then
            self.timers[event] = debounce
        end
    end,
    
    OnEvent = function(self, event, ...)
        local handler = self[event]
        if not handler then return end
        
        local debounce = self.timers[event]
        if debounce then
            -- Implement debouncing
            if self.pending[event] then
                self.pending[event]:Cancel()
            end
            self.pending[event] = C_Timer.NewTimer(debounce, function()
                handler(self, ...)
                self.pending[event] = nil
            end)
        else
            handler(self, ...)
        end
    end
}
```

#### 1.2.3 Inventory Change Detection
```lua
-- Equipment Cache System
PawnEquipmentMonitor = {
    cache = {},
    
    Initialize = function(self)
        for slot = 1, 19 do
            self.cache[slot] = GetInventoryItemLink("player", slot)
        end
    end,
    
    CheckChanges = function(self)
        local changes = {}
        for slot = 1, 19 do
            local current = GetInventoryItemLink("player", slot)
            if current ~= self.cache[slot] then
                changes[slot] = {old = self.cache[slot], new = current}
                self.cache[slot] = current
            end
        end
        return changes
    end
}
```

**Tests:**
- [ ] Equipment swap detection
- [ ] Bag update detection  
- [ ] Debounce timing optimal

### 1.3 Logging & Debug System (3h)

#### 1.3.1 Debug Framework
```lua
PawnDebug = {
    enabled = false,
    logLevel = 1,  -- 1=Error, 2=Warning, 3=Info, 4=Debug
    
    Log = function(self, level, category, message)
        if not self.enabled or level > self.logLevel then return end
        
        local timestamp = date("%H:%M:%S")
        local output = format("[%s][%s][%s]: %s", 
            timestamp, 
            self:GetLevelName(level), 
            category, 
            message
        )
        
        -- Output to chat and saved log
        DEFAULT_CHAT_FRAME:AddMessage("|cffFFFF00Pawn:|r " .. output)
        table.insert(PawnDebugLog, output)
    end
}
```

**Categories:**
- API_CALL
- EVENT
- PARSING
- CACHE
- TOOLTIP
- PERFORMANCE

---

## PHASE 2: API Migration Layer (14h)

### 2.1 Item Information APIs (5h)

#### 2.1.1 GetItemInfo Wrapper
```lua
-- vanilla/core/ItemInfo.lua
PawnGetItemInfoVanilla = function(itemLink)
    -- Parse different itemLink formats
    local itemId = PawnParseItemLink(itemLink)
    
    -- Standard GetItemInfo (different returns in Vanilla)
    local name, link, quality, iLevel, reqLevel, class, subclass, 
          maxStack, equipSlot, texture, vendorPrice = GetItemInfo(itemId)
    
    -- Vanilla doesn't have itemLevel in GetItemInfo!
    -- Must parse from tooltip
    if not iLevel then
        iLevel = PawnGetItemLevelFromTooltip(itemLink)
    end
    
    return {
        name = name,
        link = link or itemLink,
        quality = quality,
        itemLevel = iLevel,
        requiredLevel = reqLevel,
        class = class,
        subclass = subclass,
        equipSlot = equipSlot,
        texture = texture,
        vendorPrice = vendorPrice
    }
end
```

#### 2.1.2 ItemLevel Extraction
```lua
function PawnGetItemLevelFromTooltip(itemLink)
    local tooltip = PawnPrivateTooltip
    tooltip:SetOwner(UIParent, "ANCHOR_NONE")
    tooltip:SetHyperlink(itemLink)
    
    -- Scan for "Item Level X"
    for i = 2, tooltip:NumLines() do
        local text = getglobal(tooltip:GetName().."TextLeft"..i):GetText()
        if text then
            local level = string.match(text, "Item Level (%d+)")
            if level then
                tooltip:Hide()
                return tonumber(level)
            end
        end
    end
    
    tooltip:Hide()
    return 0  -- Default if not found
end
```

**Information benötigt:**
- [ ] Vanilla GetItemInfo return format
- [ ] Item Level display in Vanilla tooltips
- [ ] Turtle WoW custom item formats

### 2.2 Stat Extraction System (6h)

#### 2.2.1 Comprehensive Pattern Database
```lua
-- vanilla/parsing/StatPatterns.lua
PawnVanillaStatPatterns = {
    -- Phase 1: Exact Patterns (highest priority)
    exact = {
        -- Primary Stats
        {pattern = "^%+(%d+) Strength$", stat = "Strength"},
        {pattern = "^%+(%d+) Agility$", stat = "Agility"},
        {pattern = "^%+(%d+) Stamina$", stat = "Stamina"},
        {pattern = "^%+(%d+) Intellect$", stat = "Intellect"},
        {pattern = "^%+(%d+) Spirit$", stat = "Spirit"},
        
        -- All Stats
        {pattern = "^%+(%d+) All Stats$", stats = {
            Strength = 1, Agility = 1, Stamina = 1, 
            Intellect = 1, Spirit = 1
        }},
    },
    
    -- Phase 2: Complex Patterns
    complex = {
        -- Attack Power
        {pattern = "^%+(%d+) Attack Power$", stat = "AttackPower"},
        {pattern = "Increases attack power by (%d+)%.", stat = "AttackPower"},
        {pattern = "^%+(%d+) Attack Power when fighting Undead%.", stat = "AttackPowerUndead"},
        
        -- Spell Power (multiple formats)
        {pattern = "Increases damage and healing done by magical spells and effects by up to (%d+)%.", 
         stat = "SpellPower"},
        {pattern = "Increases healing done by spells and effects by up to (%d+)%.", 
         stat = "HealingPower"},
        {pattern = "Increases damage done by Shadow spells and effects by up to (%d+)%.", 
         stat = "ShadowPower"},
        -- ... weitere Schulen
        
        -- Hit & Crit (percentage based)
        {pattern = "Improves your chance to hit by (%d+)%%%.", 
         stat = "HitPercent", converter = function(v) return v * 10 end}, -- 1% = 10 rating
        {pattern = "Improves your chance to get a critical strike by (%d+)%%%.", 
         stat = "CritPercent", converter = function(v) return v * 14 end}, -- 1% = 14 rating
        {pattern = "Improves your chance to get a critical strike with spells by (%d+)%%%.", 
         stat = "SpellCritPercent", converter = function(v) return v * 14 end},
        
        -- Defense & Avoidance
        {pattern = "Increased Defense %+(%d+)%.", stat = "Defense"},
        {pattern = "Increases defense rating by (%d+)%.", stat = "DefenseRating"},
        {pattern = "Increases your chance to dodge an attack by (%d+)%%%.", 
         stat = "DodgePercent", converter = function(v) return v * 12 end},
        {pattern = "Increases your chance to block attacks with a shield by (%d+)%%%.", 
         stat = "BlockPercent"},
        {pattern = "Increases the block value of your shield by (%d+)%.", 
         stat = "BlockValue"},
        
        -- Resistances
        {pattern = "^%+(%d+) Fire Resistance$", stat = "FireResistance"},
        {pattern = "^%+(%d+) Nature Resistance$", stat = "NatureResistance"},
        {pattern = "^%+(%d+) Frost Resistance$", stat = "FrostResistance"},
        {pattern = "^%+(%d+) Shadow Resistance$", stat = "ShadowResistance"},
        {pattern = "^%+(%d+) Arcane Resistance$", stat = "ArcaneResistance"},
        {pattern = "^%+(%d+) All Resistances$", stats = {
            FireResistance = 1, NatureResistance = 1, FrostResistance = 1,
            ShadowResistance = 1, ArcaneResistance = 1
        }},
        
        -- Regeneration
        {pattern = "Restores (%d+) health per 5 sec%.", stat = "HealthPer5"},
        {pattern = "Restores (%d+) mana per 5 sec%.", stat = "ManaPer5"},
        {pattern = "^%+(%d+) Health per 5 sec%.", stat = "HealthPer5"},
        {pattern = "^%+(%d+) Mana per 5 sec%.", stat = "ManaPer5"},
    },
    
    -- Phase 3: Turtle WoW Specific
    turtle = {
        {pattern = "Increases spell penetration by (%d+)%.", stat = "SpellPenetration"},
        {pattern = "Increases armor penetration by (%d+)%.", stat = "ArmorPenetration"},
        {pattern = "Increases movement speed by (%d+)%%%.", stat = "MovementSpeed"},
        -- Weitere Turtle-spezifische Stats
    },
    
    -- Phase 4: Proc Effects (optional parsing)
    procs = {
        {pattern = "Chance on hit: (.+)", stat = "ProcEffect", special = true},
        {pattern = "Equip: Chance to (.+)", stat = "EquipProc", special = true},
        {pattern = "Use: (.+)", stat = "UseEffect", special = true},
    }
}
```

#### 2.2.2 Advanced Parser with Caching
```lua
PawnStatParser = {
    cache = {},
    cacheSize = 0,
    maxCacheSize = 1000,
    
    ParseTooltip = function(self, itemLink)
        -- Check cache first
        local cached = self.cache[itemLink]
        if cached then
            cached.hits = (cached.hits or 0) + 1
            return cached.stats
        end
        
        local stats = {}
        local tooltip = PawnPrivateTooltip
        tooltip:SetOwner(UIParent, "ANCHOR_NONE")
        tooltip:SetHyperlink(itemLink)
        
        -- Parse each line
        for i = 2, tooltip:NumLines() do
            local leftText = getglobal(tooltip:GetName().."TextLeft"..i):GetText()
            if leftText then
                self:ParseLine(leftText, stats)
            end
            
            -- Also check right text (for some items)
            local rightText = getglobal(tooltip:GetName().."TextRight"..i):GetText()
            if rightText then
                self:ParseLine(rightText, stats)
            end
        end
        
        tooltip:Hide()
        
        -- Cache management
        self:AddToCache(itemLink, stats)
        
        return stats
    end,
    
    ParseLine = function(self, text, stats)
        -- Remove color codes
        text = string.gsub(text, "|c%x%x%x%x%x%x%x%x", "")
        text = string.gsub(text, "|r", "")
        
        -- Try each pattern category
        for _, category in ipairs({"exact", "complex", "turtle", "procs"}) do
            for _, pattern in ipairs(PawnVanillaStatPatterns[category]) do
                local match = {string.match(text, pattern.pattern)}
                if match[1] then
                    self:ApplyMatch(pattern, match, stats)
                    break  -- Only one pattern per line
                end
            end
        end
    end,
    
    ApplyMatch = function(self, pattern, match, stats)
        if pattern.stat then
            local value = tonumber(match[1])
            if pattern.converter then
                value = pattern.converter(value)
            end
            stats[pattern.stat] = (stats[pattern.stat] or 0) + value
        elseif pattern.stats then
            -- Multiple stats from one pattern
            local value = tonumber(match[1])
            for stat, multiplier in pairs(pattern.stats) do
                stats[stat] = (stats[stat] or 0) + (value * multiplier)
            end
        elseif pattern.special then
            -- Special handling for procs/use effects
            stats[pattern.stat] = match[1]  -- Store as string
        end
    end
}
```

**Information benötigt:**
- [ ] Komplette Liste Vanilla Stat-Strings (alle Sprachen)
- [ ] Turtle WoW custom stat strings
- [ ] Stat-to-Rating Conversions für Vanilla

### 2.3 Tooltip Hook System (3h)

#### 2.3.1 Universal Tooltip Hooking
```lua
PawnTooltipHooks = {
    hooked = {},
    
    HookTooltip = function(self, tooltipName)
        local tooltip = getglobal(tooltipName)
        if not tooltip or self.hooked[tooltipName] then return end
        
        -- Hook all relevant methods
        local methods = {
            "SetBagItem", "SetInventoryItem", "SetLootItem",
            "SetQuestItem", "SetQuestLogItem", "SetTradeSkillItem",
            "SetMerchantItem", "SetAuctionItem", "SetHyperlink"
        }
        
        for _, method in ipairs(methods) do
            if tooltip[method] then
                self:HookMethod(tooltip, method, tooltipName)
            end
        end
        
        self.hooked[tooltipName] = true
    end,
    
    HookMethod = function(self, tooltip, method, tooltipName)
        local original = tooltip[method]
        tooltip[method] = function(...)
            original(...)
            self:OnTooltipUpdate(tooltip, method, tooltipName, ...)
        end
    end
}
```

---

## PHASE 3: UI System Reduction (10h)

### 3.1 UI Component Removal (4h)

#### 3.1.1 Feature Removal Checklist
```lua
-- config/FeatureFlags.lua
PawnFeatureFlags = {
    -- Core Features (KEEP)
    ScaleManagement = true,
    TooltipIntegration = true,
    ItemComparison = true,
    BagArrows = true,
    
    -- Remove These
    ImportExport = false,
    AutoSelectScales = false,
    ScaleProviders = false,
    GemOptimization = false,
    ArtifactSupport = false,
    UpgradeTracking = false,
    
    -- Simplified
    OptionsUI = "minimal",
    DebugMode = true  -- For development
}
```

#### 3.1.2 UI File Modifications
```lua
-- PawnUI.lua modifications
-- Remove functions:
-- PawnUIImportScale*
-- PawnUIExportScale*
-- PawnUIFrame_AutoSelectScales*
-- PawnUI_SetGemQualityLevel*
-- PawnUIFrame_GemList*

-- Simplify tab structure:
PawnUITabs = {
    {name = "Scales", frame = "PawnUIScalesTab"},
    {name = "Values", frame = "PawnUIValuesTab"},
    {name = "Compare", frame = "PawnUICompareTab"},
    -- {name = "Options", frame = "PawnUIOptionsTab"}, -- REMOVED
    -- {name = "Gems", frame = "PawnUIGemsTab"},       -- REMOVED
}
```

### 3.2 Minimal Options Implementation (3h)

#### 3.2.1 Simplified Options
```lua
PawnVanillaOptions = {
    -- Essential Options Only
    ShowTooltipValues = true,
    ShowBagUpgradeArrows = true,
    ShowItemLevelInTooltip = false,  -- Not reliable in Vanilla
    ShowSubTooltipOnShift = true,    -- New for space management
    DebugMode = false,
    
    -- Per-character
    ActiveScales = {},  -- Scale name -> enabled
}
```

#### 3.2.2 Minimal Options UI
```xml
<!-- Simplified Options Panel -->
<Frame name="PawnVanillaOptionsFrame">
    <CheckButton name="$parentShowTooltips">
        <Scripts>
            <OnClick>PawnVanillaOptions.ShowTooltipValues = self:GetChecked()</OnClick>
        </Scripts>
    </CheckButton>
    
    <CheckButton name="$parentShowBagArrows">
        <Scripts>
            <OnClick>PawnVanillaOptions.ShowBagUpgradeArrows = self:GetChecked()</OnClick>
        </Scripts>
    </CheckButton>
    
    <CheckButton name="$parentSubTooltip">
        <Scripts>
            <OnClick>PawnVanillaOptions.ShowSubTooltipOnShift = self:GetChecked()</OnClick>
        </Scripts>
    </CheckButton>
</Frame>
```

### 3.3 SavedVariables Migration (3h)

#### 3.3.1 Data Structure Simplification
```lua
-- SavedVariables structure
PawnVanillaSaved = {
    Version = 1,
    
    -- Global
    Options = {
        ShowTooltipValues = true,
        ShowBagArrows = true,
    },
    
    -- Per Character
    Characters = {
        ["ServerName-CharacterName"] = {
            Scales = {
                ["ScaleName"] = {
                    Stats = {Strength = 1.5, Agility = 1.0},
                    Enabled = true,
                    Color = {r = 1, g = 0.5, b = 0}
                }
            },
            ActiveScales = {"ScaleName1", "ScaleName2"}
        }
    }
}
```

---

## PHASE 4: Tooltip Display System (8h)

### 4.1 Sub-Tooltip Implementation (4h)

#### 4.1.1 Sub-Tooltip Creation
```lua
-- ui/SubTooltip.lua
PawnSubTooltip = {
    frame = nil,
    parentTooltip = nil,
    
    Initialize = function(self)
        self.frame = CreateFrame("GameTooltip", "PawnSubTooltip", UIParent, "GameTooltipTemplate")
        self.frame:SetFrameStrata("TOOLTIP")
        self.frame:SetClampedToScreen(true)
        
        -- Custom styling
        self.frame:SetBackdropColor(0, 0, 0, 0.9)
        self.frame:SetBackdropBorderColor(0.5, 0.5, 0, 1)
    end,
    
    Show = function(self, parent, itemLink)
        if not self.frame then self:Initialize() end
        
        -- Position logic
        local x, y = self:CalculatePosition(parent)
        self.frame:SetOwner(parent, "ANCHOR_NONE")
        self.frame:SetPoint("TOPLEFT", parent, "TOPRIGHT", x, y)
        
        -- Content
        self:PopulateContent(itemLink)
        
        self.frame:Show()
        self.parentTooltip = parent
    end,
    
    CalculatePosition = function(self, parent)
        -- Smart positioning to avoid screen edges
        local screenWidth = GetScreenWidth()
        local parentRight = parent:GetRight()
        local spaceRight = screenWidth - parentRight
        
        if spaceRight < 200 then
            -- Not enough space on right, show on left
            return -parent:GetWidth() - 10, 0
        else
            return 10, 0
        end
    end,
    
    PopulateContent = function(self, itemLink)
        self.frame:ClearLines()
        
        -- Header
        self.frame:AddLine("Pawn Wertung", 1, 0.82, 0)
        self.frame:AddLine(" ")
        
        -- Get item data
        local item = PawnGetItemData(itemLink)
        if not item or not item.Values then
            self.frame:AddLine("Keine Wertung verfügbar", 0.5, 0.5, 0.5)
            return
        end
        
        -- Add values for each scale
        local hasValues = false
        for scaleName, enabled in pairs(PawnVanillaOptions.ActiveScales) do
            if enabled and item.Values[scaleName] then
                local value = item.Values[scaleName]
                local color = PawnGetScaleColor(scaleName)
                
                self.frame:AddDoubleLine(
                    scaleName .. ":",
                    format("%.1f", value),
                    color.r, color.g, color.b,
                    1, 1, 1
                )
                hasValues = true
            end
        end
        
        if not hasValues then
            self.frame:AddLine("Keine aktiven Scales", 0.5, 0.5, 0.5)
        end
        
        -- Footer hint
        self.frame:AddLine(" ")
        self.frame:AddLine("Shift loslassen zum Ausblenden", 0.5, 0.5, 0.5)
    end
}
```

#### 4.1.2 Integration with Main Tooltip
```lua
-- Modify tooltip hooks
GameTooltip:HookScript("OnTooltipSetItem", function(self)
    if IsShiftKeyDown() and PawnVanillaOptions.ShowSubTooltipOnShift then
        local _, itemLink = self:GetItem()
        if itemLink then
            PawnSubTooltip:Show(self, itemLink)
        end
    end
end)

GameTooltip:HookScript("OnHide", function()
    if PawnSubTooltip.frame then
        PawnSubTooltip.frame:Hide()
    end
end)

-- Update on modifier key change
local function OnModifierStateChanged()
    if GameTooltip:IsVisible() then
        if IsShiftKeyDown() and PawnVanillaOptions.ShowSubTooltipOnShift then
            local _, itemLink = GameTooltip:GetItem()
            if itemLink then
                PawnSubTooltip:Show(GameTooltip, itemLink)
            end
        else
            if PawnSubTooltip.frame then
                PawnSubTooltip.frame:Hide()
            end
        end
    end
end
```

### 4.2 Compatibility Testing (4h)

#### 4.2.1 Addon Compatibility Matrix
```lua
PawnCompatibilityTests = {
    -- Test with common Vanilla addons
    addons = {
        "Auctioneer",
        "EnhTooltip", 
        "MobInfo2",
        "AtlasLoot",
        "ItemRack",
        "Outfitter",
        "SuperInspect",
        "BonusScanner",
        "TheoryCraft"
    },
    
    RunTests = function(self)
        local results = {}
        for _, addon in ipairs(self.addons) do
            results[addon] = self:TestAddon(addon)
        end
        return results
    end,
    
    TestAddon = function(self, addonName)
        if not IsAddOnLoaded(addonName) then
            return "Not Loaded"
        end
        
        -- Specific tests per addon
        local tests = {
            ["Auctioneer"] = function()
                -- Test auction house tooltip
                return self:TestAuctionTooltip()
            end,
            ["AtlasLoot"] = function()
                -- Test AtlasLoot item tooltips
                return self:TestAtlasLootTooltip()
            end,
        }
        
        local test = tests[addonName]
        if test then
            return test()
        else
            return "No specific test"
        end
    end
}
```

---

## PHASE 5: Item Parsing & Caching (12h)

### 5.1 Advanced Pattern System (6h)

#### 5.1.1 Multi-Language Support Preparation
```lua
-- parsing/Localization.lua
PawnParsingLocales = {
    enUS = {
        -- English patterns (primary)
        PATTERN_STRENGTH = "%+(%d+) Strength",
        PATTERN_ATTACK_POWER = "Increases attack power by (%d+)%.",
        -- ...
    },
    
    deDE = {
        -- German patterns
        PATTERN_STRENGTH = "%+(%d+) Stärke",
        PATTERN_ATTACK_POWER = "Erhöht Angriffskraft um (%d+)%.",
        -- ...
    },
    
    frFR = {
        -- French patterns
        PATTERN_STRENGTH = "%+(%d+) Force",
        -- ...
    }
}

-- Auto-detect client locale
local locale = GetLocale()
PawnCurrentPatterns = PawnParsingLocales[locale] or PawnParsingLocales.enUS
```

**Information benötigt:**
- [ ] Deutsche Stat-Strings aus Vanilla Client
- [ ] Französische Stat-Strings
- [ ] Weitere Sprachen nach Bedarf

#### 5.1.2 Special Case Handling
```lua
-- Edge cases and special items
PawnSpecialCases = {
    -- Thunderfury proc
    [19019] = function(stats)
        stats.ProcDamage = 300  -- Nature damage proc
    end,
    
    -- Hand of Ragnaros
    [17182] = function(stats)
        stats.ProcDamage = 200  -- Fire damage proc
    end,
    
    -- Set bonuses (need special parsing)
    SetBonuses = {
        ["Tier 0.5"] = {
            [2] = {Stamina = 10},
            [4] = {AttackPower = 20},
            -- ...
        }
    }
}
```

### 5.2 Performance Optimization (4h)

#### 5.2.1 Intelligent Caching System
```lua
PawnCacheManager = {
    -- Multi-tier cache
    L1_Cache = {},  -- Hot cache (last 50 items)
    L2_Cache = {},  -- Warm cache (last 200 items)
    L3_Cache = {},  -- Cold cache (SavedVariables)
    
    Get = function(self, itemLink)
        -- Check L1 (fastest)
        local item = self.L1_Cache[itemLink]
        if item then
            item.hits = (item.hits or 0) + 1
            return item
        end
        
        -- Check L2
        item = self.L2_Cache[itemLink]
        if item then
            -- Promote to L1
            self:PromoteToL1(itemLink, item)
            return item
        end
        
        -- Check L3 (SavedVariables)
        item = self.L3_Cache[itemLink]
        if item then
            -- Validate item still current
            if self:ValidateCache(item) then
                self:PromoteToL1(itemLink, item)
                return item
            end
        end
        
        return nil
    end,
    
    PromoteToL1 = function(self, itemLink, item)
        -- LRU implementation
        if self:GetCacheSize(self.L1_Cache) >= 50 then
            -- Demote least recently used
            local lru = self:FindLRU(self.L1_Cache)
            self.L2_Cache[lru.link] = lru.item
            self.L1_Cache[lru.link] = nil
        end
        
        self.L1_Cache[itemLink] = item
        item.lastAccess = time()
    end
}
```

#### 5.2.2 Batch Processing
```lua
-- Process multiple items efficiently
PawnBatchProcessor = {
    queue = {},
    processing = false,
    
    AddToQueue = function(self, itemLink, callback)
        table.insert(self.queue, {link = itemLink, callback = callback})
        if not self.processing then
            self:ProcessQueue()
        end
    end,
    
    ProcessQueue = function(self)
        self.processing = true
        
        -- Process in chunks to avoid freezing
        local chunkSize = 5
        local processed = 0
        
        while #self.queue > 0 and processed < chunkSize do
            local item = table.remove(self.queue, 1)
            local data = PawnGetItemData(item.link)
            if item.callback then
                item.callback(data)
            end
            processed = processed + 1
        end
        
        if #self.queue > 0 then
            -- Continue next frame
            C_Timer.After(0.01, function() self:ProcessQueue() end)
        else
            self.processing = false
        end
    end
}
```

### 5.3 Validation & Testing (2h)

#### 5.3.1 Stat Parsing Validation
```lua
-- Test suite for stat parsing
PawnParsingTests = {
    testCases = {
        {
            name = "Tier 1 Warrior Chest",
            itemLink = "item:16730:0:0:0",
            expectedStats = {
                Stamina = 30,
                Strength = 20,
                FireResistance = 10
            }
        },
        {
            name = "Thunderfury",
            itemLink = "item:19019:0:0:0",
            expectedStats = {
                Agility = 5,
                AttackSpeed = 0.15,  -- 15% speed
                NatureResistance = 8
            }
        },
        -- More test cases...
    },
    
    RunAll = function(self)
        local results = {}
        for _, test in ipairs(self.testCases) do
            results[test.name] = self:RunTest(test)
        end
        return results
    end
}
```

---

## PHASE 6: Scale System & Default Values (8h)

### 6.1 Vanilla/Turtle Scale Templates (4h)

**Information benötigt:**
- [ ] Turtle WoW Klassenguides (Discord/Forum)
- [ ] Classic Theorycrafting Spreadsheets
- [ ] BiS Listen für alle Phasen
- [ ] Stat Weights aus privaten Servern

#### 6.1.1 Class-Specific Scales
```lua
-- scales/DefaultScales.lua
PawnDefaultScalesVanilla = {
    -- Warrior
    ["Warrior-Fury-DPS"] = {
        Strength = 2.0,
        Agility = 1.0,
        AttackPower = 1.0,
        CritPercent = 20,  -- High value
        HitPercent = 30,   -- Cap at 9%
        Stamina = 0.1,
        
        -- Weapon specific
        WeaponDPS = 10,
        WeaponSpeed = -5,  -- Slower is better for Fury
    },
    
    ["Warrior-Tank"] = {
        Stamina = 1.5,
        Defense = 2.0,
        DodgePercent = 15,
        ParryPercent = 15,
        BlockPercent = 10,
        BlockValue = 0.5,
        Strength = 1.0,
        Agility = 0.8,
    },
    
    -- Rogue
    ["Rogue-Combat"] = {
        Agility = 2.0,
        AttackPower = 1.0,
        Strength = 0.5,
        CritPercent = 20,
        HitPercent = 25,  -- Cap at 8%
        
        -- Weapon specific
        WeaponDPS = 8,
        WeaponSpeed = 5,  -- Faster for poison procs
    },
    
    -- Mage
    ["Mage-Frost"] = {
        SpellPower = 2.0,
        FrostPower = 2.5,  -- Frost specific
        Intellect = 1.0,
        SpellCritPercent = 15,
        SpellHitPercent = 16,  -- Cap at 16%
        Stamina = 0.1,
        ManaPer5 = 3.0,
    },
    
    -- Priest
    ["Priest-Shadow"] = {
        SpellPower = 2.0,
        ShadowPower = 2.5,
        SpellHitPercent = 16,
        Intellect = 1.0,
        Stamina = 0.2,
        ManaPer5 = 2.0,
    },
    
    ["Priest-Holy"] = {
        HealingPower = 2.5,
        Intellect = 1.5,
        Spirit = 1.8,
        ManaPer5 = 4.0,
        SpellCritPercent = 10,
    },
    
    -- ... weitere Klassen
}

-- Turtle WoW specific adjustments
PawnTurtleAdjustments = {
    -- New stats in Turtle
    SpellPenetration = {
        ["Mage-Frost"] = 0.5,
        ["Warlock-Affliction"] = 0.8,
    },
    
    ArmorPenetration = {
        ["Warrior-Fury-DPS"] = 1.5,
        ["Rogue-Combat"] = 1.2,
    },
    
    -- Adjusted caps
    HitCaps = {
        Melee = 9,   -- vs 63
        Spell = 16,  -- vs 63
        MeleeYellow = 8,  -- Special attacks
    }
}
```

### 6.2 Scale Management System (4h)

#### 6.2.1 Scale CRUD Operations
```lua
PawnScaleManager = {
    -- Create
    CreateScale = function(self, name, stats)
        if PawnVanillaSaved.Characters[self:GetCharID()].Scales[name] then
            return false, "Scale exists"
        end
        
        PawnVanillaSaved.Characters[self:GetCharID()].Scales[name] = {
            Stats = stats or {},
            Enabled = true,
            Color = self:GenerateColor(name),
            Created = time(),
            Modified = time()
        }
        
        return true
    end,
    
    -- Read
    GetScale = function(self, name)
        return PawnVanillaSaved.Characters[self:GetCharID()].Scales[name]
    end,
    
    -- Update
    UpdateScale = function(self, name, stats)
        local scale = self:GetScale(name)
        if not scale then return false end
        
        scale.Stats = stats
        scale.Modified = time()
        
        -- Invalidate cache for this scale
        PawnCacheManager:InvalidateScale(name)
        
        return true
    end,
    
    -- Delete
    DeleteScale = function(self, name)
        PawnVanillaSaved.Characters[self:GetCharID()].Scales[name] = nil
        return true
    end,
    
    -- Import predefined
    ImportPredefined = function(self, templateName)
        local template = PawnDefaultScalesVanilla[templateName]
        if not template then return false end
        
        local scaleName = templateName .. "-Imported"
        return self:CreateScale(scaleName, template)
    end
}
```

---

## PHASE 7: Integration Testing (10h)

### 7.1 Comprehensive Test Suite (5h)

#### 7.1.1 Automated Testing Framework
```lua
PawnTestSuite = {
    tests = {},
    results = {},
    
    RegisterTest = function(self, name, testFunc)
        self.tests[name] = testFunc
    end,
    
    RunAllTests = function(self)
        self.results = {}
        local passed = 0
        local failed = 0
        
        for name, test in pairs(self.tests) do
            local success, result = pcall(test)
            if success and result then
                self.results[name] = "PASSED"
                passed = passed + 1
            else
                self.results[name] = "FAILED: " .. (result or "unknown")
                failed = failed + 1
            end
        end
        
        return passed, failed, self.results
    end
}

-- Register core tests
PawnTestSuite:RegisterTest("ItemParsing", function()
    local stats = PawnStatParser:ParseTooltip("item:16730")
    assert(stats.Stamina == 30, "Stamina parsing failed")
    assert(stats.Strength == 20, "Strength parsing failed")
    return true
end)

PawnTestSuite:RegisterTest("TooltipHooks", function()
    -- Test tooltip modification
    GameTooltip:SetHyperlink("item:16730")
    local found = false
    for i = 1, GameTooltip:NumLines() do
        local text = getglobal("GameTooltipTextLeft"..i):GetText()
        if string.find(text, "Pawn") then
            found = true
            break
        end
    end
    GameTooltip:Hide()
    return found
end)
```

### 7.2 Performance Testing (3h)

#### 7.2.1 Benchmarking
```lua
PawnBenchmark = {
    Run = function(self, testName, func, iterations)
        iterations = iterations or 1000
        
        local startTime = debugprofilestop()
        local startMem = gcinfo()
        
        for i = 1, iterations do
            func()
        end
        
        local endTime = debugprofilestop()
        local endMem = gcinfo()
        
        return {
            name = testName,
            iterations = iterations,
            totalTime = (endTime - startTime) / 1000,  -- Convert to seconds
            avgTime = (endTime - startTime) / iterations,  -- ms per iteration
            memoryUsed = endMem - startMem  -- KB
        }
    end,
    
    RunSuite = function(self)
        local results = {}
        
        -- Test stat parsing performance
        results.parsing = self:Run("StatParsing", function()
            PawnStatParser:ParseTooltip("item:16730")
        end, 100)
        
        -- Test cache performance
        results.cache = self:Run("CacheAccess", function()
            PawnCacheManager:Get("item:16730")
        end, 1000)
        
        -- Test tooltip update
        results.tooltip = self:Run("TooltipUpdate", function()
            PawnUpdateTooltip("GameTooltip", "SetHyperlink", "item:16730")
        end, 100)
        
        return results
    end
}
```

### 7.3 User Acceptance Testing (2h)

#### 7.3.1 Test Scenarios
```
UAT Checklist:

[ ] Installation
    [ ] Clean install on Vanilla client
    [ ] Clean install on Turtle WoW client
    [ ] Upgrade from existing Pawn installation
    
[ ] Basic Functionality
    [ ] Tooltips show values
    [ ] Bag upgrade arrows work
    [ ] Item comparison works
    [ ] Sub-tooltip appears on Shift
    
[ ] Scale Management
    [ ] Create new scale
    [ ] Edit existing scale
    [ ] Delete scale
    [ ] Enable/disable scales
    
[ ] Performance
    [ ] No lag when mousing over items
    [ ] Auction house browsing smooth
    [ ] Bank operations normal
    
[ ] Compatibility
    [ ] Works with Auctioneer
    [ ] Works with AtlasLoot
    [ ] Works with ItemRack
    [ ] Works with Outfitter
```

---

## PHASE 8: Localization & Documentation (6h)

### 8.1 Localization Framework (3h)

**Information benötigt:**
- [ ] Übersetzer für DE/FR/ES/RU/CN
- [ ] Vanilla Client in verschiedenen Sprachen
- [ ] Glossar wichtiger Begriffe

#### 8.1.1 Localization Structure
```lua
-- localization/Base.lua
PawnLocale = {}

-- localization/enUS.lua
if GetLocale() == "enUS" then
    PawnLocale.TooltipHeader = "Pawn Score"
    PawnLocale.UpgradeArrow = "Upgrade"
    -- ...
end

-- localization/deDE.lua
if GetLocale() == "deDE" then
    PawnLocale.TooltipHeader = "Pawn Wertung"
    PawnLocale.UpgradeArrow = "Verbesserung"
    -- ...
end
```

### 8.2 Documentation (3h)

#### 8.2.1 User Documentation
```markdown
# Pawn Vanilla - Benutzerhandbuch

## Installation
1. Entpacke Pawn in WoW/Interface/AddOns/
2. Stelle sicher, dass VgerCore vorhanden ist
3. Starte WoW neu

## Erste Schritte
1. Öffne Pawn mit /pawn
2. Wähle eine vordefinierte Scale für deine Klasse
3. Aktiviere die Scale
4. Mouseover Items zeigen nun Wertungen

## FAQ
Q: Warum zeigt Pawn keine Werte?
A: Stelle sicher, dass mindestens eine Scale aktiviert ist

Q: Tooltips sind abgeschnitten?
A: Halte Shift für den Sub-Tooltip
```

---

## PHASE 9: Deployment & Release (4h)

### 9.1 Build Process (2h)

#### 9.1.1 Build Script
```bash
#!/bin/bash
# build.sh

VERSION="1.0.0-vanilla"
ADDON_NAME="Pawn-Vanilla"

# Clean build directory
rm -rf build/
mkdir -p build/$ADDON_NAME

# Copy core files
cp -r vanilla/* build/$ADDON_NAME/
cp -r VgerCore-Vanilla build/$ADDON_NAME/VgerCore
cp *.toc build/$ADDON_NAME/

# Update TOC file
sed -i "s/## Interface: .*/## Interface: 11200/" build/$ADDON_NAME/Pawn.toc
sed -i "s/## Version: .*/## Version: $VERSION/" build/$ADDON_NAME/Pawn.toc

# Create zip
cd build
zip -r $ADDON_NAME-$VERSION.zip $ADDON_NAME

echo "Build complete: $ADDON_NAME-$VERSION.zip"
```

### 9.2 Release Checklist (2h)

```
Release Checklist:

[ ] Code
    [ ] All phases complete
    [ ] Tests passing
    [ ] No debug code remaining
    
[ ] Documentation
    [ ] README updated
    [ ] CHANGELOG written
    [ ] Installation guide
    
[ ] Testing
    [ ] Tested on Vanilla 1.12.1
    [ ] Tested on Turtle WoW 1.18.0
    [ ] Compatibility tests complete
    
[ ] Distribution
    [ ] Version number updated
    [ ] ZIP package created
    [ ] Upload to GitHub
    [ ] Upload to Turtle WoW forums
    [ ] Announce in Discord
```

---

## Risiko-Management & Contingency

### Kritische Risiken

1. **String-Parsing Fehler**
   - Mitigation: Extensive pattern testing
   - Fallback: Manual stat entry UI
   
2. **Performance-Probleme**
   - Mitigation: Aggressive caching
   - Fallback: Reduce parsing frequency
   
3. **Addon-Konflikte**
   - Mitigation: Compatibility layer
   - Fallback: Disable conflicting features

### Go/No-Go Entscheidungspunkte

- **Phase 2 Ende:** Wenn Stat-Parsing < 80% Genauigkeit → Projekt überdenken
- **Phase 4 Ende:** Wenn Tooltip-Performance problematisch → Alternative UI
- **Phase 7 Ende:** Wenn > 5 kritische Bugs → Release verschieben

---

## Zusammenfassung

Diese detaillierte Phasenplanung bietet:

1. **Klare Meilensteine** mit messbaren Deliverables
2. **Code-Beispiele** für kritische Komponenten
3. **Test-Strategien** für jede Phase
4. **Risiko-Mitigation** an kritischen Punkten
5. **Informations-Checklisten** für externe Daten

**Geschätzter Gesamtaufwand:** 84 Stunden (mit Buffer)
**Kritischer Pfad:** Phase 2 (API Migration) → Phase 5 (Parsing) → Phase 7 (Testing)

Die Implementierung sollte iterativ erfolgen, mit funktionsfähigen Builds nach Phase 2, 4, und 6.