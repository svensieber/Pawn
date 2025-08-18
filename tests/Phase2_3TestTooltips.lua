-- tests/Phase2_3TestTooltips.lua
-- Phase 2.3 Test Suite: Tooltip Hook System

local function TestTooltipHooks()
    print("|cff8ec3e6=== Testing Tooltip Hook System ===|r")
    
    -- Check if hooks are initialized
    if not PawnTooltipHooks then
        print("|cffff0000ERROR: PawnTooltipHooks not found|r")
        return
    end
    
    -- Test hook status
    local hooksWorking = 0
    local totalHooks = 0
    
    for tooltipName, hooked in pairs(PawnTooltipHooks.hooked or {}) do
        totalHooks = totalHooks + 1
        if hooked then
            hooksWorking = hooksWorking + 1
            print(format("  %s: |cff00ff00Hooked|r", tooltipName))
        else
            print(format("  %s: |cffff0000Not hooked|r", tooltipName))
        end
    end
    
    print(format("Hooks active: %d/%d", hooksWorking, totalHooks))
    
    -- Test with an actual item
    print("\n|cff8ec3e6Testing tooltip display:|r")
    print("Hover over an item to see Pawn values in tooltip")
    print("Make sure you have at least one scale enabled")
end

local function TestTooltipPerformance()
    print("|cff8ec3e6=== Testing Tooltip Performance ===|r")
    
    if not PawnTooltipPerformance then
        print("|cffff0000ERROR: PawnTooltipPerformance not found|r")
        return
    end
    
    -- Enable performance monitoring
    PawnTooltipPerformance.enabled = true
    PawnTooltipPerformance:Reset()
    
    -- Simulate tooltip updates
    print("Simulating 100 tooltip updates...")
    
    local testLink = GetInventoryItemLink("player", 1) or "item:6948:0:0:0"
    
    for i = 1, 100 do
        PawnTooltipPerformance:StartTimer("test_" .. i)
        
        -- Simulate tooltip work
        if PawnTooltipHooks and PawnTooltipHooks.GetItemLinkFromTooltip then
            -- This would normally be called during tooltip update
            local link = PawnTooltipHooks:GetItemLinkFromTooltip(
                GameTooltip, "SetHyperlink", testLink)
        end
        
        PawnTooltipPerformance:EndTimer("test_" .. i)
    end
    
    -- Get stats
    local stats = PawnTooltipPerformance:GetStats()
    print(format("Total time: %.2fms", stats.total))
    print(format("Average per update: %.3fms", stats.average))
    print(format("Maximum time: %.2fms", stats.maximum))
    
    if stats.average < 1 then
        print("|cff00ff00Performance: EXCELLENT|r")
    elseif stats.average < 5 then
        print("|cffffff00Performance: GOOD|r")
    else
        print("|cffff0000Performance: NEEDS OPTIMIZATION|r")
    end
    
    -- Disable performance monitoring
    PawnTooltipPerformance.enabled = false
end

local function TestSpecificTooltipMethod(method)
    print("|cff8ec3e6=== Testing " .. method .. " ===|r")
    
    if not PawnTooltipHooks then
        print("|cffff0000ERROR: PawnTooltipHooks not found|r")
        return
    end
    
    local success = false
    
    if method == "SetInventoryItem" then
        -- Test with equipped item
        local hasItem = GetInventoryItemLink("player", 1)
        if hasItem then
            GameTooltip:SetOwner(UIParent, "ANCHOR_NONE")
            GameTooltip:SetInventoryItem("player", 1)
            success = true
            print("Testing with head slot item")
        else
            print("No item in head slot to test")
        end
    elseif method == "SetBagItem" then
        -- Test with bag item
        local foundItem = false
        for bag = 0, 4 do
            for slot = 1, GetContainerNumSlots(bag) do
                if GetContainerItemLink(bag, slot) then
                    GameTooltip:SetOwner(UIParent, "ANCHOR_NONE")
                    GameTooltip:SetBagItem(bag, slot)
                    success = true
                    foundItem = true
                    print(format("Testing with bag %d slot %d", bag, slot))
                    break
                end
            end
            if foundItem then break end
        end
        if not foundItem then
            print("No items in bags to test")
        end
    elseif method == "SetHyperlink" then
        -- Test with Hearthstone
        GameTooltip:SetOwner(UIParent, "ANCHOR_NONE")
        GameTooltip:SetHyperlink("item:6948:0:0:0")
        success = true
        print("Testing with Hearthstone link")
    end
    
    if success then
        -- Check if Pawn info was added
        local hasPawnInfo = false
        for i = 1, GameTooltip:NumLines() do
            local text = getglobal("GameTooltipTextLeft" .. i):GetText()
            if text and string.find(text, "Pawn") then
                hasPawnInfo = true
                break
            end
        end
        
        if hasPawnInfo then
            print("|cff00ff00Pawn info found in tooltip|r")
        else
            print("|cffffff00No Pawn info in tooltip (check if scales are enabled)|r")
        end
        
        GameTooltip:Hide()
    end
end

local function TestCompatibility()
    print("|cff8ec3e6=== Testing Addon Compatibility ===|r")
    
    local addons = {
        "AtlasLoot",
        "Auctioneer", 
        "EnhTooltip",
        "ItemRack",
        "Outfitter"
    }
    
    for _, addon in ipairs(addons) do
        if IsAddOnLoaded(addon) then
            print(format("  %s: |cff00ff00Loaded|r", addon))
            
            -- Check for known tooltip conflicts (only if PawnTooltipHooks exists)
            if addon == "AtlasLoot" and AtlasLootTooltip and PawnTooltipHooks then
                if PawnTooltipHooks.hooked and PawnTooltipHooks.hooked["AtlasLootTooltip"] then
                    print("    AtlasLootTooltip: |cff00ff00Hooked|r")
                else
                    print("    AtlasLootTooltip: |cffffff00Not hooked|r")
                end
            end
        else
            print(format("  %s: Not loaded", addon))
        end
    end
end

local function RunPhase2_3Tests()
    print("|cff8ec3e6=== Running Phase 2.3 Tests ===|r")
    TestTooltipHooks()
    TestTooltipPerformance()
    TestCompatibility()
    print("|cff8ec3e6=== Phase 2.3 Tests Complete ===|r")
end

-- Slash Commands for Phase 2.3
SLASH_P23TEST1 = "/p23test"
SlashCmdList["P23TEST"] = function(msg)
    local cmd, arg = msg, nil
    local spacePos = string.find(msg, " ")
    if spacePos then
        cmd = string.sub(msg, 1, spacePos - 1)
        arg = string.sub(msg, spacePos + 1)
    end
    
    if cmd == "all" then
        RunPhase2_3Tests()
    elseif cmd == "hooks" then
        TestTooltipHooks()
    elseif cmd == "perf" then
        TestTooltipPerformance()
    elseif cmd == "method" then
        if arg then
            TestSpecificTooltipMethod(arg)
        else
            print("Usage: /p23test method <SetInventoryItem|SetBagItem|SetHyperlink>")
        end
    elseif cmd == "compat" then
        TestCompatibility()
    elseif cmd == "manual" then
        print("|cff8ec3e6Manual Test Instructions:|r")
        print("1. Make sure you have at least one Pawn scale enabled")
        print("2. Hover over items in your bags")
        print("3. Check if Pawn values appear in tooltips")
        print("4. Try different tooltip sources:")
        print("   - Inventory items")
        print("   - Bag items")
        print("   - Merchant items")
        print("   - Auction house items")
        print("   - Linked items in chat")
    else
        print("|cff8ec3e6Phase 2.3 Tooltip Test Commands:|r")
        print("  /p23test all - Run all tests")
        print("  /p23test hooks - Test hook status")
        print("  /p23test perf - Test performance")
        print("  /p23test method <name> - Test specific method")
        print("  /p23test compat - Test addon compatibility")
        print("  /p23test manual - Show manual test instructions")
    end
end

-- Auto-load message
local frame23 = CreateFrame("Frame", "PawnPhase23TestFrame")
frame23:RegisterEvent("PLAYER_LOGIN")
local hasShownPhase23 = false
local loginTime = 0

frame23:SetScript("OnEvent", function()
    if hasShownPhase23 then return end
    if event == "PLAYER_LOGIN" then
        loginTime = GetTime()
        -- Create a temporary frame for delayed message
        local delayFrame = CreateFrame("Frame")
        delayFrame:SetScript("OnUpdate", function()
            if GetTime() - loginTime > 5 then
                if not hasShownPhase23 then
                    hasShownPhase23 = true
                    print("|cff8ec3e6=== Phase 2.3 Loaded: Tooltip Hook System ===|r")
                    print("Commands: /p23test all")
                end
                delayFrame:SetScript("OnUpdate", nil)
            end
        end)
    end
end)