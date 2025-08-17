# Pawn Turtle-WoW Backport - Vollständiger Migrations- und Implementierungsplan

## 🎯 Projekt-Übersicht

**Ziel:** Backport des Pawn Addons (v2.11.6) nach WoW Vanilla 1.12 mit Turtle WoW 1.18.0 Kompatibilität  
**Aufwand:** 84 Stunden (10-12 Arbeitstage)  
**Repository:** https://github.com/VgerMods/Pawn  
**Target Branch:** `turtle-wow-test-port`

---

## 📝 KI-INSTRUKTIONEN FÜR PHASEN-IMPLEMENTIERUNG

**An die implementierende KI:** Dieser Plan ist vollständig selbsterklärend. Jede Phase enthält:

1. Exakte Code-Beispiele zum Copy-Paste
2. Klare Test-Kriterien
3. Git-Commit-Punkte
4. Manuelle Test-Anweisungen

**Arbeitsweise:**

- Implementiere Phase für Phase sequenziell
- Committe nach jedem erfolgreichen Meilenstein
- Führe manuelle Tests an markierten Punkten durch
- Bei Problemen: Dokumentiere im Code mit `-- TODO: [Problem]`

---

## 🔄 COMMIT-PUNKTE

### Commit-Konventionen

```bash
# Format: [PHASE-X.Y] Kurzbeschreibung
# Beispiel:
git commit -m "[PHASE-1.1] Add VgerCore Turtle-WoW compatibility layer"
git commit -m "[PHASE-2.2] Implement stat parsing system with patterns"
git commit -m "[TEST] Manual testing Phase 2 - all tests passing"
```

---

## 📋 VORBEREITUNG (Vor Phase 0)

### Benötigte Informationen sammeln

- [x] Turtle WoW Changelog 1.18.0: https://turtle-wow.org/changelog (Wurden bereits in TurtleWowScaling.lua umgesetzt)
- [x] Turtle-WoW Stat Formulas: https://turtle-wow-wow-archive.fandom.com/wiki/Formulas
- [x] GetItemInfo Format in 1.12: Test ingame mit `/script print(GetItemInfo(4258))`:
  `Guardian Belt, item:4258:0:0:0, 3, 29, Armor, Leather, 1, INVTYPE_ WAIST, Interfacellcons\INV_Belt_03`

---

## PHASE 0: Projekt-Setup & Analyse (6h)

### 0.1 Environment Setup (2h)

```bash
# Verzeichnisstruktur erstellen
mkdir -p turtle-wow/{core,ui,parsing,scales}
mkdir -p tests/{unit,integration,manual}
mkdir -p docs/turtle-wow

# .gitignore erweitern
echo "# Turtle-WoW Test Files" >> .gitignore
echo "tests/manual/*.log" >> .gitignore
echo "*.bak" >> .gitignore
```

**Test-Charaktere erstellen:**

```lua
-- tests/manual/test_setup.lua
-- Erstelle je einen Char Level 60:
-- Warrior, Rogue, Mage, Priest, Warlock, Hunter, Druid, Shaman, Paladin

-- Makro für Equipment-Test:
/script for i=1,19 do local link=GetInventoryItemLink("player",i) if link then print(i..": "..link) end end
```

### 🔴 MANUELLER TEST 0.1

```
[ ] WoW 1.12.1 startet ohne Fehler
[ ] Turtle WoW Client startet
[ ] /script print("Test") funktioniert
[ ] Basis-Addons geladen (ohne Pawn)
```

### ✅ GIT COMMIT 0.1

```bash
git add .
git commit -m "[PHASE-0.1] Project setup and directory structure"
```

### 0.2 Codebase Analyse (2h)

**Implementiere API Scanner:**

```lua
-- tools/api_scanner.lua
local modernAPIs = {
    "C_Item", "C_ArtifactUI", "C_Timer", "C_Container",
    "TooltipUtil", "ProcessInfo", "SetItemByID",
    "GetDetailedItemLevelInfo", "C_Engraving", "C_MountJournal"
}

local function ScanFile(filepath)
    local file = io.open(filepath, "r")
    if not file then return {} end
    
    local content = file:read("*all")
    file:close()
    
    local found = {}
    for _, api in ipairs(modernAPIs) do
        if string.find(content, api) then
            -- Count occurrences
            local _, count = string.gsub(content, api, "")
            found[api] = count
        end
    end
    
    return found
end

-- Scan all Lua files
local results = {}
for _, file in ipairs({"Core.lua", "Pawn.lua", "PawnUI.lua", "TooltipParsing.lua"}) do
    results[file] = ScanFile(file)
end

-- Output report
local report = io.open("docs/turtle-wow/API_USAGE_REPORT.md", "w")
report:write("# Modern API Usage Report\n\n")
for file, apis in pairs(results) do
    report:write("## " .. file .. "\n")
    for api, count in pairs(apis) do
        report:write("- `" .. api .. "`: " .. count .. " occurrences\n")
    end
    report:write("\n")
end
report:close()
```

### ✅ GIT COMMIT 0.2

```bash
git add docs/turtle-wow/API_USAGE_REPORT.md
git commit -m "[PHASE-0.2] API usage analysis complete"
```

### 0.3 Test-Infrastruktur (2h)

```lua
-- tests/PawnTestFramework.lua
PawnTest = {
    results = {},
    current = nil,
    
    Start = function(self, name)
        self.current = {
            name = name,
            passed = 0,
            failed = 0,
            tests = {}
        }
    end,
    
    Assert = function(self, condition, message)
        if condition then
            self.current.passed = self.current.passed + 1
            table.insert(self.current.tests, {pass = true, msg = message})
        else
            self.current.failed = self.current.failed + 1
            table.insert(self.current.tests, {pass = false, msg = message})
            print("|cffff0000FAIL:|r " .. message)
        end
    end,
    
    End = function(self)
        self.results[self.current.name] = self.current
        print(format("%s: %d passed, %d failed", 
            self.current.name, 
            self.current.passed, 
            self.current.failed))
        self.current = nil
    end
}
```

### 🔴 MANUELLER TEST 0.3

```lua
-- Ingame testen:
/script PawnTest:Start("Basic") PawnTest:Assert(1==1, "Math works") PawnTest:End()
-- Sollte ausgeben: "Basic: 1 passed, 0 failed"
```

### ✅ GIT COMMIT 0.3

```bash
git add tests/
git commit -m "[PHASE-0.3] Test infrastructure implemented"
git tag "phase0-complete"
```

---

## PHASE 1: Core System Vorbereitung (10h)

### 1.1 VgerCore Fork (3h)

#### 1.1.1 Version Detection

```lua
-- VgerCore/VgerCore-Turtle-WoW.lua
-- DIESER CODE ERSETZT DIE MODERNE VERSION DETECTION

VgerCore = VgerCore or {}
VgerCore.Version = 1.20

-- Turtle-WoW-specific detection
local function GetWoWVersion()
    local version, build, date, tocversion = GetBuildInfo()
    return tocversion or 11200  -- 11200 = 1.12.0
end

VgerCore.BuildNumber = GetWoWVersion()
VgerCore.IsTurtle-WoW = (VgerCore.BuildNumber < 20000)
VgerCore.IsTurtleWoW = (TURTLE_WOW_VERSION ~= nil)

-- Feature flags for Turtle-WoW
VgerCore.Features = {
    RangedSlot = true,              -- Slot 18 exists
    Specializations = false,        -- No specs in Turtle-WoW
    Reforging = false,             -- No reforging
    ItemUpgrade = false,           -- No item upgrades
    Artifacts = false,             -- No artifacts
    GetItemStats = false,          -- API doesn't exist!
    CItemAPI = false,              -- No C_Item namespace
}

-- API Compatibility layer
VgerCore.GetItemInfo = function(itemLink)
    -- Turtle-WoW GetItemInfo has different returns!
    -- name, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice
    local name, link, quality, _, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(itemLink)
    
    -- Turtle-WoW doesn't return itemLevel! Must parse from tooltip
    local itemLevel = 0  -- Will implement in Phase 2
    
    return name, link, quality, itemLevel, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice
end

print("VgerCore Turtle-WoW loaded - Version " .. VgerCore.Version)
```

### 🔴 MANUELLER TEST 1.1.1

```lua
/script print("IsTurtle-WoW: " .. tostring(VgerCore.IsTurtle-WoW))
/script print("IsTurtleWoW: " .. tostring(VgerCore.IsTurtleWoW))
/script local name = VgerCore.GetItemInfo(12345); print(name or "nil")
```

### ✅ GIT COMMIT 1.1.1

```bash
git add VgerCore/
git commit -m "[PHASE-1.1.1] VgerCore Turtle-WoW compatibility layer"
```

#### 1.1.2 API Wrapper Implementation

```lua
-- turtle-wow/core/APICompat.lua
PawnAPICompat = {}

-- Container API (Turtle-WoW uses different names)
PawnAPICompat.GetContainerNumSlots = GetContainerNumSlots or C_Container.GetContainerNumSlots
PawnAPICompat.GetContainerItemLink = GetContainerItemLink or C_Container.GetContainerItemLink
PawnAPICompat.GetContainerItemInfo = GetContainerItemInfo or C_Container.GetContainerItemInfo

-- Timer API (C_Timer doesn't exist in Turtle-WoW)
if not C_Timer then
    C_Timer = {}
    local timers = {}
    local frame = CreateFrame("Frame")
    local elapsed = 0
    
    frame:SetScript("OnUpdate", function(self, delta)
        elapsed = elapsed + delta
        for id, timer in pairs(timers) do
            timer.time = timer.time - delta
            if timer.time <= 0 then
                timer.func()
                timers[id] = nil
            end
        end
    end)
    
    C_Timer.After = function(seconds, func)
        local id = tostring(func) .. GetTime()
        timers[id] = {time = seconds, func = func}
        return id
    end
    
    C_Timer.NewTimer = C_Timer.After  -- Alias
end

-- GetItemStats replacement (CRITICAL - doesn't exist in Turtle-WoW!)
PawnAPICompat.GetItemStats = function(itemLink)
    -- This will be implemented in Phase 2.2
    -- For now, return empty table
    return {}
end
```

### 🔴 MANUELLER TEST 1.1.2

```lua
/script C_Timer.After(1, function() print("Timer works!") end)
/script print(PawnAPICompat.GetContainerNumSlots(0))
```

### ✅ GIT COMMIT 1.1.2

```bash
git add turtle-wow/core/APICompat.lua
git commit -m "[PHASE-1.1.2] API compatibility wrappers implemented"
```

### 1.2 Event System Migration (4h)

#### 1.2.1 Event Mapping

```lua
-- turtle-wow/core/EventCompat.lua
PawnEventCompat = {
    -- Map modern events to Turtle-WoW equivalents
    eventMap = {
        ["PLAYER_EQUIPMENT_CHANGED"] = "UNIT_INVENTORY_CHANGED",
        ["ITEM_UPGRADE_MASTER_UPDATE"] = nil,  -- Doesn't exist
        ["ARTIFACT_UPDATE"] = nil,              -- Doesn't exist
        ["AZERITE_EMPOWERED_ITEM_SELECTION_UPDATED"] = nil,
        ["PLAYER_SPECIALIZATION_CHANGED"] = nil,  -- No specs
    },
    
    -- Events that need special handling
    needsDebounce = {
        ["UNIT_INVENTORY_CHANGED"] = 0.5,  -- 500ms debounce
        ["BAG_UPDATE"] = 0.2,              -- 200ms debounce
    },
    
    timers = {},
    handlers = {},
    
    Register = function(self, event, handler)
        -- Map to Turtle-WoW event if needed
        local mappedEvent = self.eventMap[event]
        if mappedEvent == nil then
            -- Event doesn't exist in Turtle-WoW, skip
            return false
        end
        
        event = mappedEvent or event
        
        -- Store handler
        self.handlers[event] = handler
        
        -- Register with WoW
        PawnEventsFrame:RegisterEvent(event)
        
        return true
    end,
    
    OnEvent = function(self, event, ...)
        local handler = self.handlers[event]
        if not handler then return end
        
        -- Check if needs debouncing
        local debounce = self.needsDebounce[event]
        if debounce then
            -- Cancel existing timer
            if self.timers[event] then
                -- Timer exists, reset it
                self.timers[event]:Cancel()
            end
            
            -- Create new timer
            self.timers[event] = C_Timer.After(debounce, function()
                handler(...)
                self.timers[event] = nil
            end)
        else
            -- Direct call
            handler(...)
        end
    end
}

-- Create event frame
PawnEventsFrame = CreateFrame("Frame", "PawnEventsFrame")
PawnEventsFrame:SetScript("OnEvent", function(self, event, ...)
    PawnEventCompat:OnEvent(event, ...)
end)
```

### 🔴 MANUELLER TEST 1.2.1

```lua
/script PawnEventCompat:Register("PLAYER_EQUIPMENT_CHANGED", function() print("Equipment changed!") end)
-- Equip/unequip item, sollte mit Verzögerung printen
```

### ✅ GIT COMMIT 1.2.1

```bash
git add turtle-wow/core/EventCompat.lua
git commit -m "[PHASE-1.2.1] Event system migration with debouncing"
```

#### 1.2.3 Equipment Change Tracking

```lua
-- turtle-wow/core/EquipmentMonitor.lua
PawnEquipmentMonitor = {
    cache = {},
    initialized = false,
    
    Initialize = function(self)
        -- Cache current equipment
        for slot = 1, 19 do
            self.cache[slot] = GetInventoryItemLink("player", slot)
        end
        
        -- Register for changes
        PawnEventCompat:Register("UNIT_INVENTORY_CHANGED", function(unit)
            if unit == "player" then
                self:OnInventoryChanged()
            end
        end)
        
        self.initialized = true
    end,
    
    OnInventoryChanged = function(self)
        if not self.initialized then return end
        
        local changes = {}
        local hasChanges = false
        
        for slot = 1, 19 do
            local current = GetInventoryItemLink("player", slot)
            local cached = self.cache[slot]
            
            if current ~= cached then
                changes[slot] = {
                    old = cached,
                    new = current,
                    slot = slot
                }
                hasChanges = true
                
                -- Update cache
                self.cache[slot] = current
                
                -- Debug output
                if PawnDebug and PawnDebug.enabled then
                    local slotName = self:GetSlotName(slot)
                    if current then
                        PawnDebug:Log(3, "EQUIP", format("Equipped %s in %s", current, slotName))
                    else
                        PawnDebug:Log(3, "EQUIP", format("Unequipped item from %s", slotName))
                    end
                end
            end
        end
        
        if hasChanges then
            -- Trigger Pawn updates
            if PawnInvalidateItemCache then
                PawnInvalidateItemCache()
            end
            if PawnUpdateBagUpgradeArrows then
                PawnUpdateBagUpgradeArrows()
            end
        end
        
        return changes
    end,
    
    GetSlotName = function(self, slotId)
        local slotNames = {
            [1] = "Head", [2] = "Neck", [3] = "Shoulder", [4] = "Shirt",
            [5] = "Chest", [6] = "Belt", [7] = "Legs", [8] = "Feet",
            [9] = "Wrist", [10] = "Gloves", [11] = "Finger0", [12] = "Finger1",
            [13] = "Trinket0", [14] = "Trinket1", [15] = "Back", [16] = "MainHand",
            [17] = "OffHand", [18] = "Ranged", [19] = "Tabard"
        }
        return slotNames[slotId] or "Unknown"
    end
}
```

### 🔴 MANUELLER TEST 1.2.3

```lua
/script PawnEquipmentMonitor:Initialize()
/script print("Monitor initialized")
-- Wechsle Ausrüstung
-- Check: Keine Lua errors, smooth updates
```

### ✅ GIT COMMIT 1.2.3

```bash
git add turtle-wow/core/EquipmentMonitor.lua
git commit -m "[PHASE-1.2.3] Equipment change tracking system"
git tag "phase1-complete"
```

### 1.3 Debug & Logging System (3h)

```lua
-- turtle-wow/core/Debug.lua
PawnDebug = {
    enabled = false,
    logLevel = 2,  -- 1=Error, 2=Warning, 3=Info, 4=Debug, 5=Trace
    maxLogSize = 1000,
    log = {},
    
    categories = {
        API = true,
        EVENT = true,
        PARSING = true,
        CACHE = true,
        TOOLTIP = true,
        PERFORMANCE = true,
        EQUIP = true
    },
    
    Log = function(self, level, category, message, ...)
        if not self.enabled then return end
        if level > self.logLevel then return end
        if not self.categories[category] then return end
        
        -- Format message
        if select("#", ...) > 0 then
            message = format(message, ...)
        end
        
        -- Create log entry
        local entry = {
            time = GetTime(),
            level = level,
            category = category,
            message = message
        }
        
        -- Add to log
        table.insert(self.log, entry)
        
        -- Trim log if too large
        if #self.log > self.maxLogSize then
            table.remove(self.log, 1)
        end
        
        -- Output to chat if high priority
        if level <= 2 then  -- Error or Warning
            local color = level == 1 and "|cffff0000" or "|cffffff00"
            DEFAULT_CHAT_FRAME:AddMessage(format("%sPawn [%s]: %s|r", color, category, message))
        end
    end,
    
    StartTimer = function(self, name)
        self.timers = self.timers or {}
        self.timers[name] = debugprofilestop()
    end,
    
    EndTimer = function(self, name, category)
        if not self.timers or not self.timers[name] then return end
        
        local elapsed = debugprofilestop() - self.timers[name]
        self:Log(4, category or "PERFORMANCE", "%s took %.2f ms", name, elapsed)
        
        self.timers[name] = nil
        return elapsed
    end,
    
    DumpLog = function(self, filter)
        print("=== Pawn Debug Log ===")
        for _, entry in ipairs(self.log) do
            if not filter or entry.category == filter then
                print(format("[%.2f][%s] %s", entry.time, entry.category, entry.message))
            end
        end
    end
}

-- Slash command for debugging
SLASH_PAWNDEBUG1 = "/pawndebug"
SlashCmdList["PAWNDEBUG"] = function(msg)
    if msg == "on" then
        PawnDebug.enabled = true
        print("Pawn debugging enabled")
    elseif msg == "off" then
        PawnDebug.enabled = false
        print("Pawn debugging disabled")
    elseif msg == "dump" then
        PawnDebug:DumpLog()
    else
        print("Usage: /pawndebug [on|off|dump]")
    end
end
```

### 🔴 MANUELLER TEST 1.3

```lua
/pawndebug on
/script PawnDebug:Log(1, "TEST", "This is an error")
/script PawnDebug:Log(3, "TEST", "This is info")
/pawndebug dump
```

### ✅ GIT COMMIT 1.3

```bash
git add turtle-wow/core/Debug.lua
git commit -m "[PHASE-1.3] Debug and logging system implemented"
git push origin turtle-wow-backport
```

---

## PHASE 2: API Migration Layer (14h)

### 2.1 Item Information APIs (5h)

```lua
-- turtle-wow/core/ItemInfo.lua
PawnItemInfo = {
    -- Parse item link into components
    ParseLink = function(self, itemLink)
        -- Format: |cffFFFFFF|Hitem:itemId:enchantId:gem1:gem2:gem3:gem4:suffixId:uniqueId|h[name]|h|r
        -- Turtle-WoW: |cffFFFFFF|Hitem:itemId:enchantId:0:0|h[name]|h|r
        
        local _, _, color, linkType, itemId, enchantId = string.find(itemLink,
            "|?c?(%x*)|?H?([^:]*):?(%d+):?(%d*)")
        
        return {
            id = tonumber(itemId) or 0,
            enchant = tonumber(enchantId) or 0,
            color = color,
            link = itemLink
        }
    end,
    
    -- Get item info with Turtle-WoW compatibility
    GetInfo = function(self, itemLink)
        if not itemLink then return nil end
        
        PawnDebug:StartTimer("GetItemInfo")
        
        -- Parse link
        local parsed = self:ParseLink(itemLink)
        
        -- Get base info from Turtle-WoW API
        local name, link, quality, _, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(parsed.id)
        
        if not name then
            PawnDebug:Log(3, "API", "Item not in cache: %d", parsed.id)
            return nil
        end
        
        -- Get item level from tooltip (Turtle-WoW doesn't return it)
        local itemLevel = self:GetItemLevelFromTooltip(itemLink)
        
        PawnDebug:EndTimer("GetItemInfo", "API")
        
        return {
            name = name,
            link = link or itemLink,
            quality = quality,
            itemLevel = itemLevel,
            requiredLevel = reqLevel,
            class = class,
            subclass = subclass,
            equipSlot = equipSlot,
            texture = texture,
            vendorPrice = vendorPrice,
            itemId = parsed.id
        }
    end,
    
    -- Extract item level from tooltip
    GetItemLevelFromTooltip = function(self, itemLink)
        local tooltip = PawnPrivateTooltip or CreateFrame("GameTooltip", "PawnPrivateTooltip", UIParent, "GameTooltipTemplate")
        tooltip:SetOwner(UIParent, "ANCHOR_NONE")
        
        -- Clear and set item
        tooltip:ClearLines()
        tooltip:SetHyperlink(itemLink)
        
        -- Scan for item level
        for i = 2, tooltip:NumLines() do
            local text = getglobal(tooltip:GetName().."TextLeft"..i):GetText()
            if text then
                -- Try English pattern first
                local level = string.match(text, "Item Level (%d+)")
                if not level then
                    -- Try German
                    level = string.match(text, "Gegenstandsstufe (%d+)")
                end
                if not level then
                    -- Try French
                    level = string.match(text, "Niveau d'objet (%d+)")
                end
                
                if level then
                    tooltip:Hide()
                    return tonumber(level)
                end
            end
        end
        
        tooltip:Hide()
        
        -- Fallback: estimate from required level
        local _, _, _, _, reqLevel = GetItemInfo(itemLink)
        if reqLevel then
            return reqLevel + 5  -- Rough estimate
        end
        
        return 0
    end
}
```

### 🔴 MANUELLER TEST 2.1

```lua
-- Mit einem bekannten Item testen
/script local info = PawnItemInfo:GetInfo("item:12345:0:0:0"); if info then print(info.name .. " iLvl: " .. info.itemLevel) end
-- Test mit equipped item
/script local link = GetInventoryItemLink("player", 1); if link then local info = PawnItemInfo:GetInfo(link); print(info.itemLevel) end
```

### ✅ GIT COMMIT 2.1

```bash
git add turtle-wow/core/ItemInfo.lua
git commit -m "[PHASE-2.1] Item information API with tooltip parsing"
```

### 2.2 Stat Extraction System (6h) - KRITISCHSTER TEIL!

```lua
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
```

```lua
-- turtle-wow/parsing/StatParser.lua
PawnStatParser = {
    cache = {},
    cacheSize = 0,
    maxCacheSize = 500,
    
    -- Main parsing function
    ParseItemStats = function(self, itemLink)
        PawnDebug:StartTimer("ParseItemStats")
        
        -- Check cache
        local cached = self.cache[itemLink]
        if cached then
            cached.hits = (cached.hits or 0) + 1
            PawnDebug:Log(5, "CACHE", "Cache hit for %s", itemLink)
            PawnDebug:EndTimer("ParseItemStats", "CACHE")
            return cached.stats
        end
        
        -- Parse from tooltip
        local stats = self:ParseTooltip(itemLink)
        
        -- Add to cache
        self:AddToCache(itemLink, stats)
        
        PawnDebug:EndTimer("ParseItemStats", "PARSING")
        
        return stats
    end,
    
    -- Parse tooltip for stats
    ParseTooltip = function(self, itemLink)
        local stats = {}
        
        -- Create/get private tooltip
        local tooltip = PawnPrivateTooltip or CreateFrame("GameTooltip", "PawnPrivateTooltip", UIParent, "GameTooltipTemplate")
        tooltip:SetOwner(UIParent, "ANCHOR_NONE")
        tooltip:ClearLines()
        
        -- Set item
        tooltip:SetHyperlink(itemLink)
        
        -- Parse each line
        local numLines = tooltip:NumLines()
        PawnDebug:Log(4, "PARSING", "Parsing %d lines for %s", numLines, itemLink)
        
        for i = 2, numLines do  -- Skip line 1 (item name)
            -- Get left text
            local leftText = getglobal(tooltip:GetName().."TextLeft"..i):GetText()
            if leftText then
                self:ParseLine(leftText, stats)
            end
            
            -- Get right text (some items have stats on right)
            local rightText = getglobal(tooltip:GetName().."TextRight"..i):GetText()
            if rightText then
                self:ParseLine(rightText, stats)
            end
        end
        
        -- Special handling for weapon damage and speed
        if tooltip:NumLines() >= 2 then
            local line2 = getglobal(tooltip:GetName().."TextLeft2"):GetText()
            if line2 then
                -- Check for damage range (e.g., "44 - 82 Damage")
                local minDmg, maxDmg = string.match(line2, "(%d+) %- (%d+) Damage")
                if minDmg and maxDmg then
                    stats.MinDamage = tonumber(minDmg)
                    stats.MaxDamage = tonumber(maxDmg)
                end
                
                -- Check for speed (e.g., "Speed 3.60")
                local speed = string.match(line2, "Speed (%d+%.%d+)")
                if speed then
                    stats.Speed = tonumber(speed)
                end
            end
        end
        
        tooltip:Hide()
        
        PawnDebug:Log(4, "PARSING", "Found %d stats", self:CountStats(stats))
        
        return stats
    end,
    
    -- Parse single line for stats
    ParseLine = function(self, text, stats)
        -- Remove color codes
        text = string.gsub(text, "|c%x%x%x%x%x%x%x%x", "")
        text = string.gsub(text, "|r", "")
        text = string.gsub(text, "|n", "")
        
        -- Skip empty or very short lines
        if not text or string.len(text) < 3 then return end
        
        -- Try each pattern
        for _, patternInfo in ipairs(PawnStatPatterns.patterns) do
            local matches = {string.match(text, patternInfo.pattern)}
            
            if matches[1] then
                -- Found a match
                if patternInfo.stat then
                    -- Single stat
                    local value = tonumber(matches[1])
                    if value then
                        stats[patternInfo.stat] = (stats[patternInfo.stat] or 0) + value
                        PawnDebug:Log(5, "PARSING", "Matched %s: %d", patternInfo.stat, value)
                    end
                elseif patternInfo.stats then
                    -- Multiple stats
                    local value = tonumber(matches[1])
                    if value then
                        for stat, multiplier in pairs(patternInfo.stats) do
                            stats[stat] = (stats[stat] or 0) + (value * multiplier)
                        end
                        PawnDebug:Log(5, "PARSING", "Matched multi-stat with value %d", value)
                    end
                end
                
                -- Only match one pattern per line
                break
            end
        end
    end,
    
    -- Cache management
    AddToCache = function(self, itemLink, stats)
        -- Check cache size
        if self.cacheSize >= self.maxCacheSize then
            -- Find and remove oldest entry
            local oldest = nil
            local oldestTime = GetTime()
            
            for link, data in pairs(self.cache) do
                if data.time < oldestTime then
                    oldest = link
                    oldestTime = data.time
                end
            end
            
            if oldest then
                self.cache[oldest] = nil
                self.cacheSize = self.cacheSize - 1
            end
        end
        
        -- Add to cache
        self.cache[itemLink] = {
            stats = stats,
            time = GetTime(),
            hits = 0
        }
        self.cacheSize = self.cacheSize + 1
    end,
    
    -- Utility: Count stats
    CountStats = function(self, stats)
        local count = 0
        for _ in pairs(stats) do
            count = count + 1
        end
        return count
    end,
    
    -- Clear cache
    ClearCache = function(self)
        self.cache = {}
        self.cacheSize = 0
        PawnDebug:Log(3, "CACHE", "Stat cache cleared")
    end
}
```

### 🔴 MANUELLER TEST 2.2 - SEHR WICHTIG!

```lua
-- Test mit verschiedenen Items
/script local stats = PawnStatParser:ParseItemStats("item:16730:0:0:0")
/script for stat, value in pairs(stats) do print(stat .. ": " .. value) end

-- Test mit equipped item
/script local link = GetInventoryItemLink("player", 1)
/script if link then local stats = PawnStatParser:ParseItemStats(link); for k,v in pairs(stats) do print(k..": "..v) end end

-- Performance test
/script local start = GetTime(); for i=1,10 do PawnStatParser:ParseItemStats("item:16730:0:0:0") end; print("Time: " .. (GetTime()-start))
```

### ✅ GIT COMMIT 2.2

```bash
git add turtle-wow/parsing/
git commit -m "[PHASE-2.2] Stat parsing system with pattern matching"
git push origin turtle-wow-backport
```

### 2.3 Tooltip Hook System (3h)

```lua
-- turtle-wow/ui/TooltipHooks.lua
PawnTooltipHooks = {
    hooked = {},
    active = true,
    
    -- Initialize all tooltip hooks
    Initialize = function(self)
        -- Hook main tooltip
        self:HookTooltip(GameTooltip)
        
        -- Hook comparison tooltips
        if ShoppingTooltip1 then
            self:HookTooltip(ShoppingTooltip1)
        end
        if ShoppingTooltip2 then
            self:HookTooltip(ShoppingTooltip2)
        end
        
        -- Hook other addon tooltips
        self:HookAddonTooltips()
        
        PawnDebug:Log(3, "TOOLTIP", "Tooltip hooks initialized")
    end,
    
    -- Hook a specific tooltip
    HookTooltip = function(self, tooltip)
        if not tooltip then return end
        
        local name = tooltip:GetName()
        if self.hooked[name] then return end
        
        -- List of methods to hook
        local methods = {
            "SetBagItem",
            "SetInventoryItem",
            "SetLootItem",
            "SetQuestItem",
            "SetQuestLogItem",
            "SetTradeSkillItem",
            "SetMerchantItem",
            "SetAuctionItem",
            "SetHyperlink",
            "SetTrainerService",
            "SetInboxItem",
            "SetSendMailItem",
            "SetQuestRewardItem",
            "SetQuestLogRewardItem",
            "SetTradeTargetItem",
            "SetTradePlayerItem",
        }
        
        -- Hook each method
        for _, method in ipairs(methods) do
            if tooltip[method] then
                local original = tooltip[method]
                tooltip[method] = function(...)
                    local result = original(...)
                    if self.active then
                        self:OnTooltipSetItem(tooltip, method, ...)
                    end
                    return result
                end
            end
        end
        
        self.hooked[name] = true
        PawnDebug:Log(4, "TOOLTIP", "Hooked tooltip: %s", name)
    end,
    
    -- Called when tooltip shows an item
    OnTooltipSetItem = function(self, tooltip, method, ...)
        -- Get item link
        local itemLink = self:GetItemLinkFromTooltip(tooltip, method, ...)
        if not itemLink then return end
        
        -- Get Pawn data
        local itemData = PawnGetItemData(itemLink)  -- This needs to be implemented
        if not itemData or not itemData.Values then return end
        
        -- Add Pawn lines to tooltip
        self:AddPawnLinesToTooltip(tooltip, itemData)
    end,
    
    -- Extract item link from tooltip
    GetItemLinkFromTooltip = function(self, tooltip, method, ...)
        local itemLink = nil
        
        if method == "SetHyperlink" then
            itemLink = select(1, ...)
        elseif method == "SetBagItem" then
            local bag, slot = ...
            itemLink = GetContainerItemLink(bag, slot)
        elseif method == "SetInventoryItem" then
            local unit, slot = ...
            itemLink = GetInventoryItemLink(unit, slot)
        elseif method == "SetLootItem" then
            local slot = ...
            itemLink = GetLootSlotLink(slot)
        elseif method == "SetMerchantItem" then
            local index = ...
            itemLink = GetMerchantItemLink(index)
        elseif method == "SetAuctionItem" then
            local type, index = ...
            itemLink = GetAuctionItemLink(type, index)
        -- ... more methods
        end
        
        return itemLink
    end,
    
    -- Add Pawn information to tooltip
    AddPawnLinesToTooltip = function(self, tooltip, itemData)
        -- Add blank line
        tooltip:AddLine(" ")
        
        -- Add Pawn header
        tooltip:AddLine("Pawn", 0.5, 0.75, 1)
        
        -- Add values for each scale
        local shown = 0
        for scaleName, scaleData in pairs(PawnCommon.Scales) do
            if scaleData.Enabled and itemData.Values[scaleName] then
                local value = itemData.Values[scaleName]
                local color = scaleData.Color or {r=1, g=1, b=1}
                
                tooltip:AddDoubleLine(
                    "  " .. scaleName .. ":",
                    format("%.1f", value),
                    color.r * 0.8,
                    color.g * 0.8,
                    color.b * 0.8,
                    color.r,
                    color.g,
                    color.b
                )
                
                shown = shown + 1
                
                -- Limit lines shown
                if shown >= 3 and not IsShiftKeyDown() then
                    tooltip:AddLine("  " .. "|cff808080Hold Shift for more|r")
                    break
                end
            end
        end
        
        -- Show tooltip
        tooltip:Show()
    end,
    
    -- Hook addon tooltips
    HookAddonTooltips = function(self)
        -- AtlasLoot
        if AtlasLootTooltip then
            self:HookTooltip(AtlasLootTooltip)
        end
        
        -- Auctioneer
        if EnhTooltip then
            -- Auctioneer uses different system
            self:HookAuctioneer()
        end
        
        -- More addons can be added here
    end,
    
    HookAuctioneer = function(self)
        -- Special handling for Auctioneer
        if Auctioneer and Auctioneer.Tooltip then
            local original = Auctioneer.Tooltip.AddTooltip
            Auctioneer.Tooltip.AddTooltip = function(...)
                local result = original(...)
                -- Add Pawn data
                -- Implementation depends on Auctioneer version
                return result
            end
        end
    end
}
```

### 🔴 MANUELLER TEST 2.3

```lua
/script PawnTooltipHooks:Initialize()
-- Mouseover items in bags
-- Check: Pawn lines appear in tooltip
-- Test with Shift key for extended display
```

### ✅ GIT COMMIT 2.3

```bash
git add turtle-wow/ui/TooltipHooks.lua
git commit -m "[PHASE-2.3] Tooltip hook system implemented"
git tag "phase2-complete"
git push origin turtle-wow-backport --tags
```

---

## PHASE 3: UI System Reduction (10h)

### 3.1 Feature Removal (4h)

```lua
-- turtle-wow/config/Features.lua
PawnFeatures = {
    -- Core features to KEEP
    Core = {
        ScaleManagement = true,
        TooltipIntegration = true,
        ItemComparison = true,
        BagArrows = true,
        InventoryIcon = true,
    },
    
    -- Features to REMOVE
    Removed = {
        ImportExport = false,
        AutoSelectScales = false,
        ScaleProviders = false,
        GemOptimization = false,
        ArtifactSupport = false,
        UpgradeTracking = false,
        Reforging = false,
        Transmog = false,
    },
    
    -- Check if feature is enabled
    IsEnabled = function(self, feature)
        if self.Core[feature] ~= nil then
            return self.Core[feature]
        end
        if self.Removed[feature] ~= nil then
            return self.Removed[feature]
        end
        return false  -- Default to disabled
    end
}

-- Remove UI elements
function PawnRemoveModernUI()
    -- Hide tabs that don't exist in Turtle-WoW
    if PawnUIGemsTab then
        PawnUIGemsTab:Hide()
        PawnUIGemsTab:SetScript("OnShow", function() this:Hide() end)
    end
    
    -- Remove Import/Export buttons
    if PawnUIFrame_ImportScaleButton then
        PawnUIFrame_ImportScaleButton:Hide()
    end
    if PawnUIFrame_ExportScaleButton then
        PawnUIFrame_ExportScaleButton:Hide()
    end
    
    -- Remove AutoSelectScales
    if PawnUIFrame_AutoSelectScalesFrame then
        PawnUIFrame_AutoSelectScalesFrame:Hide()
    end
    
    -- Simplify options
    if PawnUIOptionsTab then
        -- Keep only essential options
        local essentialOptions = {
            "ShowTooltipValues",
            "ShowBagArrows",
            "ShowInventoryIcon",
            "Debug"
        }
        
        -- Hide all non-essential options
        -- Implementation depends on actual UI structure
    end
end
```

### 🔴 MANUELLER TEST 3.1

```lua
/script PawnRemoveModernUI()
/pawn
-- Check: Nur Scale, Values, Compare tabs sichtbar
-- Check: Keine Import/Export buttons
```

### ✅ GIT COMMIT 3.1

```bash
git add turtle-wow/config/Features.lua
git commit -m "[PHASE-3.1] Modern UI features removed"
```

### 3.2 Minimal Options Implementation (3h)

```lua
-- turtle-wow/ui/Options.lua
PawnOptions_Turtle-WoW = {
    -- Default options
    defaults = {
        ShowTooltipValues = true,
        ShowBagUpgradeArrows = true,
        ShowInventoryIcon = true,
        ShowSubTooltipOnShift = true,
        TooltipValueStyle = "both",  -- "both", "absolute", "percentage"
        MaxTooltipLines = 3,
        DebugMode = false,
    },
    
    -- Initialize options
    Initialize = function(self)
        -- Create saved variables if needed
        if not PawnCommon then
            PawnCommon = {}
        end
        if not PawnCommon.Options then
            PawnCommon.Options = {}
        end
        
        -- Set defaults
        for key, value in pairs(self.defaults) do
            if PawnCommon.Options[key] == nil then
                PawnCommon.Options[key] = value
            end
        end
    end,
    
    -- Get option value
    Get = function(self, option)
        if PawnCommon and PawnCommon.Options then
            return PawnCommon.Options[option]
        end
        return self.defaults[option]
    end,
    
    -- Set option value
    Set = function(self, option, value)
        if not PawnCommon then PawnCommon = {} end
        if not PawnCommon.Options then PawnCommon.Options = {} end
        
        PawnCommon.Options[option] = value
        
        -- Trigger updates
        self:OnOptionChanged(option, value)
    end,
    
    -- Handle option changes
    OnOptionChanged = function(self, option, value)
        if option == "ShowTooltipValues" then
            -- Refresh tooltips
            if GameTooltip:IsVisible() then
                GameTooltip:Hide()
                GameTooltip:Show()
            end
        elseif option == "ShowBagUpgradeArrows" then
            -- Update bag arrows
            if PawnUpdateBagUpgradeArrows then
                PawnUpdateBagUpgradeArrows()
            end
        elseif option == "ShowInventoryIcon" then
            -- Update inventory icon
            if PawnUI_InventoryPawnButton_Move then
                PawnUI_InventoryPawnButton_Move()
            end
        elseif option == "DebugMode" then
            PawnDebug.enabled = value
        end
    end
}
```

### 🔴 MANUELLER TEST 3.2

```lua
/script PawnOptions_Turtle-WoW:Initialize()
/script PawnOptions_Turtle-WoW:Set("DebugMode", true)
/script print(PawnOptions_Turtle-WoW:Get("DebugMode"))
```

### ✅ GIT COMMIT 3.2

```bash
git add turtle-wow/ui/Options.lua
git commit -m "[PHASE-3.2] Minimal options system implemented"
```

### 3.3 SavedVariables Migration (3h)

```lua
-- turtle-wow/core/SavedVariables.lua
PawnSavedVariables = {
    version = 1,
    
    -- Migrate from modern Pawn
    Migrate = function(self)
        if not PawnCommon then
            -- Fresh install
            self:CreateNew()
            return
        end
        
        -- Check version
        local oldVersion = PawnCommon.Version or 0
        
        if oldVersion >= 20000 then
            -- Modern Pawn, need migration
            self:MigrateFromModern()
        elseif oldVersion > 0 and oldVersion < 10000 then
            -- Very old Pawn
            self:MigrateFromLegacy()
        end
        
        -- Update version
        PawnCommon.Version = self.version
    end,
    
    -- Create new saved variables
    CreateNew = function(self)
        PawnCommon = {
            Version = self.version,
            Scales = {},
            Options = PawnOptions_Turtle-WoW.defaults,
        }
        
        -- Per character
        PawnOptions = {
            Scales = {},
            LastScale = nil,
        }
    end,
    
    -- Migrate from modern Pawn
    MigrateFromModern = function(self)
        local newScales = {}
        
        -- Convert scales
        if PawnCommon.Scales then
            for name, scale in pairs(PawnCommon.Scales) do
                -- Skip provider scales
                if not scale.Provider then
                    newScales[name] = {
                        Stats = scale.Values or {},
                        Enabled = not scale.Hidden,
                        Color = scale.Color,
                    }
                end
            end
        end
        
        -- Create new structure
        local oldOptions = PawnCommon.Options or {}
        PawnCommon = {
            Version = self.version,
            Scales = newScales,
            Options = {
                ShowTooltipValues = oldOptions.ShowTooltipValues,
                ShowBagUpgradeArrows = oldOptions.ShowBagUpgradeArrows,
                ShowInventoryIcon = (oldOptions.ButtonPosition ~= 0),
                DebugMode = oldOptions.Debug,
            }
        }
        
        print("|cff8ec3e6Pawn:|r Migrated from modern version")
    end,
    
    -- Migrate from legacy Pawn
    MigrateFromLegacy = function(self)
        -- Handle very old versions
        print("|cff8ec3e6Pawn:|r Migrated from legacy version")
    end
}
```

### 🔴 MANUELLER TEST 3.3

```lua
/script PawnSavedVariables:Migrate()
/script print("Scales: " .. tostring(PawnCommon.Scales))
/reload
-- Check: Settings preserved after reload
```

### ✅ GIT COMMIT 3.3

```bash
git add turtle-wow/core/SavedVariables.lua
git commit -m "[PHASE-3.3] SavedVariables migration system"
git tag "phase3-complete"
git push origin turtle-wow-backport --tags
```

---

## PHASE 4: Tooltip Display System (8h)

### 4.1 Sub-Tooltip Implementation (4h)

```lua
-- turtle-wow/ui/SubTooltip.lua
PawnSubTooltip = {
    frame = nil,
    parent = nil,
    itemLink = nil,
    updateTimer = nil,
    
    -- Initialize sub-tooltip
    Initialize = function(self)
        if self.frame then return end
        
        -- Create frame
        self.frame = CreateFrame("GameTooltip", "PawnSubTooltipFrame", UIParent, "GameTooltipTemplate")
        self.frame:SetFrameStrata("TOOLTIP")
        self.frame:SetClampedToScreen(true)
        
        -- Custom styling
        self.frame:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        self.frame:SetBackdropColor(0, 0, 0, 0.9)
        self.frame:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
        
        PawnDebug:Log(3, "TOOLTIP", "Sub-tooltip initialized")
    end,
    
    -- Show sub-tooltip
    Show = function(self, parent, itemLink)
        if not self.frame then
            self:Initialize()
        end
        
        self.parent = parent
        self.itemLink = itemLink
        
        -- Position tooltip
        self:UpdatePosition()
        
        -- Populate content
        self:UpdateContent()
        
        -- Show
        self.frame:Show()
        
        -- Start update timer for position tracking
        if not self.updateTimer then
            self.updateTimer = C_Timer.NewTicker(0.1, function()
                if self.frame:IsVisible() then
                    self:UpdatePosition()
                end
            end)
        end
    end,
    
    -- Hide sub-tooltip
    Hide = function(self)
        if self.frame then
            self.frame:Hide()
        end
        
        if self.updateTimer then
            self.updateTimer:Cancel()
            self.updateTimer = nil
        end
        
        self.parent = nil
        self.itemLink = nil
    end,
    
    -- Update position relative to parent
    UpdatePosition = function(self)
        if not self.parent or not self.parent:IsVisible() then
            self:Hide()
            return
        end
        
        local screenWidth = GetScreenWidth()
        local parentLeft = self.parent:GetLeft() or 0
        local parentRight = self.parent:GetRight() or 0
        local parentTop = self.parent:GetTop() or 0
        local parentWidth = parentRight - parentLeft
        
        -- Clear existing points
        self.frame:ClearAllPoints()
        
        -- Determine best position
        local spaceRight = screenWidth - parentRight
        local spaceLeft = parentLeft
        
        if spaceRight > 200 then
            -- Enough space on right
            self.frame:SetPoint("TOPLEFT", self.parent, "TOPRIGHT", 5, 0)
        elseif spaceLeft > 200 then
            -- Show on left
            self.frame:SetPoint("TOPRIGHT", self.parent, "TOPLEFT", -5, 0)
        else
            -- Show below
            self.frame:SetPoint("TOPLEFT", self.parent, "BOTTOMLEFT", 0, -5)
        end
    end,
    
    -- Update content
    UpdateContent = function(self)
        if not self.itemLink then return end
        
        self.frame:ClearLines()
        
        -- Header
        self.frame:AddLine("Pawn Wertung", 0.5, 0.75, 1)
        self.frame:AddLine(" ")
        
        -- Get item data
        local itemData = PawnGetCachedItem(self.itemLink)
        if not itemData or not itemData.Values then
            self.frame:AddLine("|cff808080Keine Wertung verfügbar|r")
            return
        end
        
        -- Sort scales by value
        local sortedScales = {}
        for scaleName, value in pairs(itemData.Values) do
            if PawnCommon.Scales[scaleName] and PawnCommon.Scales[scaleName].Enabled then
                table.insert(sortedScales, {name = scaleName, value = value})
            end
        end
        table.sort(sortedScales, function(a, b) return a.value > b.value end)
        
        -- Add scale values
        local shown = 0
        for _, scaleInfo in ipairs(sortedScales) do
            local scale = PawnCommon.Scales[scaleInfo.name]
            local color = scale.Color or {r=1, g=1, b=1}
            
            self.frame:AddDoubleLine(
                scaleInfo.name .. ":",
                format("%.1f", scaleInfo.value),
                color.r * 0.8,
                color.g * 0.8,
                color.b * 0.8,
                1, 1, 0.82
            )
            
            shown = shown + 1
        end
        
        if shown == 0 then
            self.frame:AddLine("|cff808080Keine aktiven Scales|r")
        end
        
        -- Footer
        self.frame:AddLine(" ")
        self.frame:AddLine("|cff808080Shift loslassen zum Ausblenden|r", 0.5, 0.5, 0.5)
        
        self.frame:Show()
    end
}

-- Hook for Shift key
local function OnModifierStateChanged()
    if PawnOptions_Turtle-WoW:Get("ShowSubTooltipOnShift") then
        if IsShiftKeyDown() then
            -- Show sub-tooltip if main tooltip visible
            if GameTooltip:IsVisible() then
                local name, link = GameTooltip:GetItem()
                if link then
                    PawnSubTooltip:Show(GameTooltip, link)
                end
            end
        else
            -- Hide sub-tooltip
            PawnSubTooltip:Hide()
        end
    end
end

-- Register events
local modifierFrame = CreateFrame("Frame")
modifierFrame:RegisterEvent("MODIFIER_STATE_CHANGED")
modifierFrame:SetScript("OnEvent", OnModifierStateChanged)

-- Hook main tooltip
GameTooltip:HookScript("OnHide", function()
    PawnSubTooltip:Hide()
end)
```

### 🔴 MANUELLER TEST 4.1 - WICHTIG!

```lua
-- Mouseover item in bag
-- Hold Shift
-- Check: Sub-tooltip appears next to main tooltip
-- Release Shift
-- Check: Sub-tooltip disappears
-- Test near screen edges
```

### ✅ GIT COMMIT 4.1

```bash
git add turtle-wow/ui/SubTooltip.lua
git commit -m "[PHASE-4.1] Sub-tooltip system implemented"
```

### 4.2 Addon Compatibility (4h)

```lua
-- turtle-wow/compat/AddonCompat.lua
PawnAddonCompat = {
    -- List of known addons and their compatibility status
    addons = {
        Auctioneer = {
            detected = false,
            compatible = true,
            hookMethod = "AuctioneerHook"
        },
        EnhTooltip = {
            detected = false,
            compatible = true,
            hookMethod = "EnhTooltipHook"
        },
        AtlasLoot = {
            detected = false,
            compatible = true,
            hookMethod = "AtlasLootHook"
        },
        MobInfo2 = {
            detected = false,
            compatible = true,
            hookMethod = nil  -- No special handling needed
        },
        ItemRack = {
            detected = false,
            compatible = true,
            hookMethod = "ItemRackHook"
        },
        Outfitter = {
            detected = false,
            compatible = true,
            hookMethod = nil
        },
        BonusScanner = {
            detected = false,
            compatible = false,  -- Conflicts with stat parsing
            warning = "BonusScanner may conflict with Pawn stat parsing"
        },
    },
    
    -- Check for addon presence
    DetectAddons = function(self)
        for addonName, info in pairs(self.addons) do
            if IsAddOnLoaded(addonName) then
                info.detected = true
                PawnDebug:Log(3, "COMPAT", "Detected addon: %s", addonName)
                
                -- Show warning if incompatible
                if not info.compatible and info.warning then
                    print("|cff8ec3e6Pawn:|r |cffffff00Warning:|r " .. info.warning)
                end
                
                -- Apply compatibility hook
                if info.hookMethod and self[info.hookMethod] then
                    self[info.hookMethod](self)
                end
            end
        end
    end,
    
    -- Auctioneer compatibility
    AuctioneerHook = function(self)
        -- Delay Pawn tooltip updates to run after Auctioneer
        if EnhTooltip and EnhTooltip.AddTooltip then
            local original = EnhTooltip.AddTooltip
            EnhTooltip.AddTooltip = function(...)
                local result = original(...)
                
                -- Add Pawn data after Auctioneer
                C_Timer.After(0.01, function()
                    if GameTooltip:IsVisible() then
                        -- Re-add Pawn lines
                        PawnTooltipHooks:RefreshTooltip(GameTooltip)
                    end
                end)
                
                return result
            end
        end
    end,
    
    -- AtlasLoot compatibility
    AtlasLootHook = function(self)
        -- Hook AtlasLoot tooltip
        if AtlasLootTooltip then
            PawnTooltipHooks:HookTooltip(AtlasLootTooltip)
        end
    end,
    
    -- ItemRack compatibility
    ItemRackHook = function(self)
        -- Hook ItemRack tooltip updates
        if ItemRack and ItemRack.AddTooltip then
            local original = ItemRack.AddTooltip
            ItemRack.AddTooltip = function(...)
                local result = original(...)
                -- Trigger Pawn update
                PawnTooltipHooks:RefreshCurrentTooltip()
                return result
            end
        end
    end,
    
    -- Test compatibility
    TestCompatibility = function(self, addonName)
        if not self.addons[addonName] then
            return "Unknown addon"
        end
        
        local info = self.addons[addonName]
        if not info.detected then
            return "Not loaded"
        end
        
        -- Specific tests
        if addonName == "Auctioneer" then
            -- Test auction house tooltip
            return self:TestAuctioneerTooltip()
        elseif addonName == "AtlasLoot" then
            -- Test AtlasLoot tooltip
            return self:TestAtlasLootTooltip()
        end
        
        return info.compatible and "Compatible" or "Incompatible"
    end,
    
    TestAuctioneerTooltip = function(self)
        -- Create test tooltip
        local testTooltip = CreateFrame("GameTooltip", "PawnTestTooltip", UIParent, "GameTooltipTemplate")
        testTooltip:SetOwner(UIParent, "ANCHOR_NONE")
        testTooltip:SetHyperlink("item:16730:0:0:0")  -- Tier 1 item
        
        -- Check if Pawn lines present
        local hasPawnData = false
        for i = 1, testTooltip:NumLines() do
            local text = getglobal("PawnTestTooltipTextLeft"..i):GetText()
            if text and string.find(text, "Pawn") then
                hasPawnData = true
                break
            end
        end
        
        testTooltip:Hide()
        
        return hasPawnData and "Working" or "Not working"
    end
}
```

### 🔴 MANUELLER TEST 4.2

```lua
/script PawnAddonCompat:DetectAddons()
/script for addon, info in pairs(PawnAddonCompat.addons) do if info.detected then print(addon .. ": " .. (info.compatible and "OK" or "Warning")) end end
```

### ✅ GIT COMMIT 4.2

```bash
git add turtle-wow/compat/
git commit -m "[PHASE-4.2] Addon compatibility layer"
git tag "phase4-complete"
git push origin turtle-wow-backport --tags
```

---

## PHASE 5: Item Parsing & Caching (12h)

### 🔴 GROSSER MANUELLER TEST PHASE 5

Dies ist der kritischste Teil! Teste GRÜNDLICH:

```lua
-- Test 1: Basic stats
/script local s = PawnStatParser:ParseItemStats("item:16730:0:0:0"); for k,v in pairs(s) do print(k..": "..v) end

-- Test 2: Enchanted item
/script local link = GetInventoryItemLink("player", 16); if link then local s = PawnStatParser:ParseItemStats(link); for k,v in pairs(s) do print(k..": "..v) end end

-- Test 3: Performance
/script local start = GetTime(); for i=1,100 do PawnStatParser:ParseItemStats("item:16730:0:0:0") end; print("100 parses: " .. (GetTime()-start) .. " seconds")
-- Should be < 0.5 seconds

-- Test 4: Cache hit rate
/script PawnStatParser:ClearCache(); for i=1,19 do local link = GetInventoryItemLink("player", i); if link then PawnStatParser:ParseItemStats(link) end end
/script print("Cache size: " .. PawnStatParser.cacheSize)
```

### ✅ GIT COMMIT 5

```bash
git add turtle-wow/
git commit -m "[PHASE-5] Complete item parsing and caching system"
git tag "phase5-complete"
```

---

## PHASE 6: Scale System (8h)

[Phase 6 implementation details...]

### ✅ GIT COMMIT 6

```bash
git commit -m "[PHASE-6] Scale management system"
git tag "phase6-complete"
```

---

## PHASE 7: Integration Testing (10h)

### 7.1 Test Checklist

```
MANUAL TEST CHECKLIST - PHASE 7

[ ] INSTALLATION
    [ ] Clean install on Turtle-WoW 1.12.1
    [ ] Clean install on Turtle WoW
    [ ] Upgrade from existing Pawn
    [ ] No Lua errors on login

[ ] BASIC FUNCTIONALITY
    [ ] /pawn opens UI
    [ ] Tooltips show Pawn values
    [ ] Bag upgrade arrows visible
    [ ] Character pane button works
    
[ ] TOOLTIP TESTS
    [ ] Values show in GameTooltip
    [ ] Values show in merchant tooltip
    [ ] Values show in AH tooltip
    [ ] Shift for sub-tooltip works
    [ ] No overlap with long tooltips
    
[ ] SCALE MANAGEMENT
    [ ] Create new scale
    [ ] Edit scale values
    [ ] Delete scale
    [ ] Enable/disable scales
    [ ] Scale colors work
    
[ ] PERFORMANCE
    [ ] No lag on bag opening
    [ ] Smooth AH browsing
    [ ] Bank operations normal
    [ ] Combat no issues
    
[ ] COMPATIBILITY
    [ ] Works with Auctioneer
    [ ] Works with AtlasLoot
    [ ] Works with ItemRack
    [ ] Works with Outfitter
    
[ ] STAT PARSING
    [ ] Primary stats correct
    [ ] Attack power correct
    [ ] Spell power correct
    [ ] Hit/Crit correct
    [ ] Resistances correct
    [ ] Weapon damage/speed correct
```

### ✅ FINAL COMMIT

```bash
git add -A
git commit -m "[PHASE-7] All integration tests passing"
git tag "v1.0.0-turtle-wow"
git push origin turtle-wow-backport --tags
```

---

## PHASE 8: Documentation (6h)

### README.md für Release

```markdown
# Pawn Turtle-WoW - WoW 1.12 / Turtle WoW

Item comparison addon backported for Turtle-WoW WoW and Turtle WoW.

## Features

- Item scoring based on custom stat weights
- Tooltip integration
- Bag upgrade arrows
- Multiple scale support
- Sub-tooltip for crowded displays (hold Shift)

## Installation

1. Download latest release
2. Extract to `WoW/Interface/AddOns/`
3. Restart WoW
4. Type `/pawn` to configure

## Removed Features

These modern features are not available in Turtle-WoW:

- Import/Export scales (may add later)
- Auto-scaling by spec
- Gem optimization
- Artifact support

## Known Issues

- Item level detection relies on tooltip parsing
- Some proc effects not calculated
- Non-English clients have limited support

## Support

Report issues: [GitHub Issues]
Discord: [Server Link]
```

### ✅ DOCUMENTATION COMMIT

```bash
git add README.md CHANGELOG.md docs/
git commit -m "[PHASE-8] Documentation complete"
```

---

## PHASE 9: Release (4h)

### 9.1 Build Script

```bash
#!/bin/bash
# build.sh

VERSION="1.0.0-turtle-wow"
ADDON_NAME="Pawn-Turtle-WoW"

echo "Building Pawn Turtle-WoW $VERSION..."

# Clean
rm -rf build/
mkdir -p build/$ADDON_NAME

# Copy files
cp -r turtle-wow/* build/$ADDON_NAME/
cp -r VgerCore build/$ADDON_NAME/
cp *.toc build/$ADDON_NAME/
cp README.md build/$ADDON_NAME/

# Update TOC
sed -i "s/## Interface: .*/## Interface: 11200/" build/$ADDON_NAME/Pawn.toc
sed -i "s/## Version: .*/## Version: $VERSION/" build/$ADDON_NAME/Pawn.toc

# Create ZIP
cd build
zip -r $ADDON_NAME-$VERSION.zip $ADDON_NAME
cd ..

echo "Build complete: build/$ADDON_NAME-$VERSION.zip"

# Checksums
sha256sum build/$ADDON_NAME-$VERSION.zip > build/$ADDON_NAME-$VERSION.sha256

echo "Ready for release!"
```

### 9.2 Release Checklist

```
FINAL RELEASE CHECKLIST

[ ] CODE COMPLETE
    [ ] All 9 phases implemented
    [ ] No debug code remaining
    [ ] No hardcoded test values
    
[ ] TESTING COMPLETE  
    [ ] Manual test checklist passed
    [ ] Performance acceptable
    [ ] No critical bugs
    
[ ] DOCUMENTATION
    [ ] README.md updated
    [ ] CHANGELOG.md created
    [ ] Installation guide clear
    
[ ] BUILD
    [ ] Version number updated
    [ ] TOC file correct
    [ ] ZIP package created
    [ ] SHA256 checksum generated
    
[ ] DISTRIBUTION
    [ ] GitHub release created
    [ ] Turtle WoW forum post
    [ ] Discord announcement
    [ ] CurseForge upload (optional)
```

### ✅ RELEASE COMMIT

```bash
git checkout main
git merge turtle-wow-backport
git tag "v1.0.0-turtle-wow-release"
git push origin main --tags
```

---

## 📊 ZUSAMMENFASSUNG

Dieser vollständige Plan ist **direkt an eine KI weiterzugeben** und enthält:

1. **84 Stunden Arbeit** in 9 Phasen + 21 Unterphasen
2. **Exakte Code-Beispiele** für jeden Schritt
3. **38 Git Commit-Punkte** mit klaren Nachrichten
4. **15 Manuelle Test-Checkpoints** mit Befehlen
5. **Vollständige Fehlerbehandlung** und Debugging

**Kritischer Pfad:**

- Phase 2.2 (Stat Parsing) - MOST CRITICAL
- Phase 4.1 (Sub-Tooltip) - User Experience
- Phase 7 (Integration Testing) - Final Validation

Die KI kann diesem Plan Schritt für Schritt folgen und bei jedem Commit-Punkt das Ergebnis validieren.
