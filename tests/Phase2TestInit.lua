-- tests/Phase2TestInit.lua
-- Phase 2 Test Suite: Item Info and Stat Parsing

local function TestItemInfo()
    print("|cff8ec3e6=== Testing Item Info System ===|r")
    PawnTest:Start("ItemInfo")
    
    -- Test with Hearthstone (always available)
    local info = PawnItemInfo:GetInfo("item:6948:0:0:0")
    PawnTest:Assert(info ~= nil, "GetInfo returns data for Hearthstone")
    if info then
        PawnTest:Assert(info.name == "Hearthstone", "Hearthstone name correct")
        PawnTest:Assert(info.itemId == 6948, "Item ID correct")
    end
    
    -- Test with equipped item
    local equippedLink = GetInventoryItemLink("player", 1)  -- Head slot
    if equippedLink then
        local equippedInfo = PawnItemInfo:GetInfo(equippedLink)
        PawnTest:Assert(equippedInfo ~= nil, "GetInfo works for equipped items")
        if equippedInfo then
            PawnTest:Assert(equippedInfo.itemLevel ~= nil, "Item level extracted")
            print("  Item Level: " .. tostring(equippedInfo.itemLevel))
        end
    end
    
    PawnTest:End()
end

local function TestStatParsing()
    print("|cff8ec3e6=== Testing Stat Parsing System ===|r")
    
    -- Test with a known item (if you have specific item IDs)
    -- For now, test with equipped items
    local testCount = 0
    local successCount = 0
    
    for slot = 1, 19 do
        local link = GetInventoryItemLink("player", slot)
        if link then
            testCount = testCount + 1
            local stats = PawnStatParser:ParseItemStats(link)
            
            if stats and PawnStatParser:CountStats(stats) > 0 then
                successCount = successCount + 1
                local slotName = PawnEquipmentMonitor:GetSlotName(slot)
                print(format("  %s: %d stats found", slotName, PawnStatParser:CountStats(stats)))
                
                -- Show first 3 stats
                local shown = 0
                for stat, value in pairs(stats) do
                    if shown < 3 then
                        print(format("    - %s: %d", stat, value))
                        shown = shown + 1
                    end
                end
            end
        end
    end
    
    print(format("|cff00ff00Parsed %d/%d items successfully|r", successCount, testCount))
end

local function TestSpecificItem()
    print("|cff8ec3e6=== Test Specific Item Stats ===|r")
    print("Shift+Click an item link in chat, then type: /p2test item")
    print("Or equip an item and type: /p2test equipped <slot>")
end

local function TestEquippedItem(slotId)
    local slot = tonumber(slotId) or 1
    local link = GetInventoryItemLink("player", slot)
    
    if not link then
        print("|cffff0000No item in slot " .. slot .. "|r")
        return
    end
    
    print("|cff8ec3e6=== Testing Equipped Item ===|r")
    print("Item: " .. link)
    
    -- Get item info
    local info = PawnItemInfo:GetInfo(link)
    if info then
        print("Name: " .. tostring(info.name))
        print("Item Level: " .. tostring(info.itemLevel))
        print("Required Level: " .. tostring(info.requiredLevel))
        print("Type: " .. tostring(info.class) .. " - " .. tostring(info.subclass))
    end
    
    -- Parse stats
    print("|cffffffaaParsed Stats:|r")
    local stats = PawnStatParser:ParseItemStats(link)
    if stats then
        for stat, value in pairs(stats) do
            print(format("  %s: %d", stat, value))
        end
        print(format("Total: %d stats", PawnStatParser:CountStats(stats)))
    else
        print("  No stats found")
    end
end

local function TestPerformance()
    print("|cff8ec3e6=== Testing Parser Performance ===|r")
    
    -- Find an item to test with
    local testLink = GetInventoryItemLink("player", 5) or "item:6948:0:0:0"
    
    -- Clear cache first
    PawnStatParser:ClearCache()
    
    -- Test uncached performance
    local startTime = GetTime()
    for i = 1, 10 do
        PawnStatParser:ParseItemStats(testLink)
    end
    local uncachedTime = (GetTime() - startTime) * 1000
    
    -- Test cached performance
    startTime = GetTime()
    for i = 1, 100 do
        PawnStatParser:ParseItemStats(testLink)
    end
    local cachedTime = (GetTime() - startTime) * 1000
    
    print(format("Uncached: 10 parses in %.2f ms (%.2f ms/parse)", uncachedTime, uncachedTime/10))
    print(format("Cached: 100 parses in %.2f ms (%.2f ms/parse)", cachedTime, cachedTime/100))
    print(format("Cache speedup: %.1fx faster", (uncachedTime/10) / (cachedTime/100)))
end

local function RunPhase2Tests()
    print("|cff8ec3e6=== Running All Phase 2 Tests ===|r")
    TestItemInfo()
    TestStatParsing()
    TestPerformance()
    print("|cff8ec3e6=== Phase 2 Tests Complete ===|r")
end

-- Slash Commands for Phase 2
SLASH_P2TEST1 = "/p2test"
SlashCmdList["P2TEST"] = function(msg)
    local cmd, arg = strsplit(" ", msg, 2)
    
    if cmd == "all" then
        RunPhase2Tests()
    elseif cmd == "info" then
        TestItemInfo()
    elseif cmd == "stats" then
        TestStatParsing()
    elseif cmd == "perf" or cmd == "performance" then
        TestPerformance()
    elseif cmd == "equipped" then
        TestEquippedItem(arg)
    elseif cmd == "item" then
        print("Please link an item in chat first, then use this command")
    else
        print("|cff8ec3e6Phase 2 Test Commands:|r")
        print("  /p2test all - Run all Phase 2 tests")
        print("  /p2test info - Test item info extraction")
        print("  /p2test stats - Test stat parsing")
        print("  /p2test perf - Test performance")
        print("  /p2test equipped [slot] - Test specific equipped item (default: 1=head)")
        print("  Slots: 1=Head, 5=Chest, 10=Hands, 16=MainHand, etc.")
    end
end

-- Show Phase 2 status on load
local frame2 = CreateFrame("Frame", "PawnPhase2TestFrame")
frame2:RegisterEvent("PLAYER_LOGIN")
local hasShownPhase2 = false
frame2:SetScript("OnEvent", function()
    if hasShownPhase2 then return end
    if event == "PLAYER_LOGIN" then
        hasShownPhase2 = true
        C_Timer.After(4, function()
            print("|cff8ec3e6=== Phase 2 Loaded: Stat Parsing System ===|r")
            print("New commands: /p2test all")
        end)
    end
end)