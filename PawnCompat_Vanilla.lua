-- Pawn Compatibility Layer for Vanilla WoW (1.12.1)
-- This file provides compatibility functions for Lua 5.0 and WoW 1.12.1 APIs

-- Lua 5.0 Compatibility Functions
-- =================================

-- In Lua 5.0, we need to handle varargs differently
-- The 'arg' table is automatically created for functions with ...
-- We don't need to change function signatures, just be aware that arg exists

-- Table length function (Lua 5.1 # operator replacement)
if not table.getn then
    -- This shouldn't happen in Lua 5.0, but just in case
    table.getn = function(t)
        local count = 0
        for _ in pairs(t) do count = count + 1 end
        return count
    end
end

-- String functions that don't exist in Lua 5.0
if not string.match then
    -- string.match doesn't exist in Lua 5.0, use string.find instead
    string.match = function(s, pattern)
        local _, _, capture = string.find(s, pattern)
        return capture
    end
end

if not string.gmatch then
    -- Use string.gfind in Lua 5.0
    string.gmatch = string.gfind
end

-- Math functions
if not math.huge then
    math.huge = 1/0  -- Positive infinity
end

-- Table functions
if not table.wipe then
    table.wipe = function(t)
        for k in pairs(t) do
            t[k] = nil
        end
        return t
    end
end

-- WoW API Compatibility Layer
-- =================================

-- C_Item namespace doesn't exist in 1.12.1
if not C_Item then
    C_Item = {}
    
    -- GetItemInfo returns different values in 1.12.1
    -- Modern: name, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice, classID, subclassID, bindType, expacID, setID, isCraftingReagent
    -- 1.12.1: name, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture
    C_Item.GetItemInfo = function(itemID)
        return GetItemInfo(itemID)
    end
    
    -- GetItemInfoInstant doesn't exist in 1.12.1
    C_Item.GetItemInfoInstant = function(itemID)
        local name, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture = GetItemInfo(itemID)
        -- We need to fake classID and subclassID
        -- This is a simplified mapping - may need refinement
        local classID, subclassID = 0, 0
        
        -- Map class names to IDs (simplified)
        if class == "Weapon" then classID = 2
        elseif class == "Armor" then classID = 4
        elseif class == "Container" then classID = 1
        elseif class == "Consumable" then classID = 0
        elseif class == "Trade Goods" then classID = 7
        elseif class == "Recipe" then classID = 9
        elseif class == "Gem" then classID = 3
        elseif class == "Miscellaneous" then classID = 15
        elseif class == "Quest" then classID = 12
        end
        
        return itemID, class, subclass, equipSlot, texture, classID, subclassID
    end
    
    -- GetItemStats doesn't exist in 1.12.1 - must use tooltip parsing
    C_Item.GetItemStats = function(itemLink)
        -- This will be implemented via tooltip parsing
        return nil
    end
    
    -- GetDetailedItemLevelInfo doesn't exist
    C_Item.GetDetailedItemLevelInfo = function(itemLink)
        local _, _, _, iLevel = GetItemInfo(itemLink)
        return iLevel, false, iLevel  -- actualItemLevel, isPvPItem, baseItemLevel
    end
    
    -- GetItemIconByID doesn't exist
    C_Item.GetItemIconByID = function(itemID)
        local _, _, _, _, _, _, _, _, _, texture = GetItemInfo(itemID)
        return texture
    end
    
    -- IsUsableItem exists but different name
    C_Item.IsUsableItem = IsUsableItem
    
    -- GetItemQualityColor exists
    C_Item.GetItemQualityColor = GetItemQualityColor
end

-- C_Timer doesn't exist in 1.12.1
if not C_Timer then
    C_Timer = {}
    
    -- Simple timer implementation using frames
    local timerFrame = CreateFrame("Frame")
    local timers = {}
    local nextID = 1
    
    timerFrame:SetScript("OnUpdate", function()
        local now = GetTime()
        local completed = {}
        
        for id, timer in pairs(timers) do
            if now >= timer.when then
                table.insert(completed, id)
            end
        end
        
        for _, id in ipairs(completed) do
            local timer = timers[id]
            timers[id] = nil
            timer.func()
        end
        
        -- Hide frame if no timers
        if next(timers) == nil then
            timerFrame:Hide()
        end
    end)
    
    C_Timer.After = function(duration, func)
        local id = nextID
        nextID = nextID + 1
        
        timers[id] = {
            when = GetTime() + duration,
            func = func
        }
        
        timerFrame:Show()
        return id
    end
    
    C_Timer.Cancel = function(id)
        timers[id] = nil
        if next(timers) == nil then
            timerFrame:Hide()
        end
    end
end

-- GetClassInfo doesn't exist in 1.12.1
if not GetClassInfo then
    local classInfo = {
        [1] = {"WARRIOR", "Warrior"},
        [2] = {"PALADIN", "Paladin"},
        [3] = {"HUNTER", "Hunter"},
        [4] = {"ROGUE", "Rogue"},
        [5] = {"PRIEST", "Priest"},
        [6] = {"DEATHKNIGHT", "Death Knight"}, -- Won't exist in vanilla
        [7] = {"SHAMAN", "Shaman"},
        [8] = {"MAGE", "Mage"},
        [9] = {"WARLOCK", "Warlock"},
        [10] = {"MONK", "Monk"}, -- Won't exist in vanilla
        [11] = {"DRUID", "Druid"},
        [12] = {"DEMONHUNTER", "Demon Hunter"}, -- Won't exist in vanilla
        [13] = {"EVOKER", "Evoker"}, -- Won't exist in vanilla
    }
    
    GetClassInfo = function(classID)
        local info = classInfo[classID]
        if info then
            return info[2], info[1], classID
        end
        return nil
    end
end

-- GetSpecialization doesn't exist in 1.12.1
if not GetSpecialization then
    GetSpecialization = function()
        -- No specs in vanilla, return nil
        return nil
    end
    
    GetLootSpecialization = function()
        return nil
    end
    
    GetSpecializationInfo = function()
        return nil
    end
end

-- Equipment Manager doesn't exist
if not C_EquipmentSet then
    C_EquipmentSet = {}
    
    C_EquipmentSet.GetEquipmentSetInfo = function()
        return nil
    end
    
    C_EquipmentSet.GetItemIDs = function()
        return nil
    end
end

-- Transmog doesn't exist
if not C_Transmog then
    C_Transmog = {}
    
    C_Transmog.GetItemAppearanceID = function()
        return nil
    end
end

-- GetItemUpgradeInfo doesn't exist
if not GetItemUpgradeInfo then
    GetItemUpgradeInfo = function(itemLink)
        return nil
    end
end

-- GetAverageItemLevel doesn't exist
if not GetAverageItemLevel then
    GetAverageItemLevel = function()
        -- Calculate manually if needed
        return 0, 0
    end
end

-- BreakUpLargeNumbers doesn't exist in 1.12.1
if not BreakUpLargeNumbers then
    BreakUpLargeNumbers = function(number)
        -- Simple thousand separator
        local str = tostring(number)
        local result = ""
        local len = string.len(str)
        
        for i = 1, len do
            if (len - i) % 3 == 0 and i ~= 1 then
                result = result .. ","
            end
            result = result .. string.sub(str, i, i)
        end
        
        return result
    end
end

-- UnitGUID doesn't exist in 1.12.1
if not UnitGUID then
    UnitGUID = function(unit)
        -- Return a fake GUID based on unit name
        local name = UnitName(unit)
        if name then
            return "Player-0-" .. name
        end
        return nil
    end
end

-- GetSocketTypes doesn't exist
if not GetSocketTypes then
    GetSocketTypes = function(itemID)
        -- Sockets don't exist in vanilla
        return nil
    end
end

-- IsUsableSpell might have different behavior
local oldIsUsableSpell = IsUsableSpell
if oldIsUsableSpell then
    IsUsableSpell = function(spell)
        local usable, nomana = oldIsUsableSpell(spell)
        return usable, nomana
    end
end

-- Tooltip compatibility
-- GameTooltip:GetItem() doesn't exist in 1.12.1
if GameTooltip and not GameTooltip.GetItem then
    GameTooltip.GetItem = function(self)
        -- Try to extract from currently shown item
        -- This is a workaround and may not always work
        return nil
    end
end

-- Additional utility functions
-- =================================

-- Safe string length for Lua 5.0
function PawnCompatStrLen(str)
    if not str then return 0 end
    return string.len(str)
end

-- Safe table length for Lua 5.0
function PawnCompatTableLen(tbl)
    if not tbl then return 0 end
    return table.getn(tbl)
end

-- Varargs helper for Lua 5.0
-- In functions with ..., use: local args = PawnCompatVarargs(arg)
function PawnCompatVarargs(arg)
    -- In Lua 5.0, arg is automatically created
    return arg or {}
end

-- Pattern escape helper
function PawnCompatPatternEscape(str)
    -- Escape special pattern characters
    return string.gsub(str, "([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
end

-- Debug output for development
function PawnCompatDebug(msg)
    if PawnCommon and PawnCommon.Debug then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff7fff[PawnCompat]|r " .. tostring(msg))
    end
end

-- Initialize compatibility layer
PawnCompatDebug("Pawn Vanilla Compatibility Layer loaded")