-- tests/Phase1TestInit.lua
-- Initialization and test commands for Phase 1

local function Phase1_OnLoad()
    print("|cff8ec3e6=== Pawn Turtle-WoW Phase 1 Test Build ===|r")
    print("|cffffffaaPhase 1 Components Loaded:|r")
    
    -- Check VgerCore
    if VgerCore then
        print("  |cff00ff00✓|r VgerCore: " .. tostring(VgerCore.Version))
        print("    - IsVanilla: " .. tostring(VgerCore.IsVanilla))
        print("    - IsTurtleWoW: " .. tostring(VgerCore.IsTurtleWoW))
    else
        print("  |cffff0000✗|r VgerCore not loaded!")
    end
    
    -- Check API Compat
    if PawnAPICompat then
        print("  |cff00ff00✓|r API Compatibility Layer")
    else
        print("  |cffff0000✗|r API Compatibility not loaded!")
    end
    
    -- Check Event System
    if PawnEventCompat then
        print("  |cff00ff00✓|r Event System")
    else
        print("  |cffff0000✗|r Event System not loaded!")
    end
    
    -- Check Equipment Monitor
    if PawnEquipmentMonitor then
        print("  |cff00ff00✓|r Equipment Monitor")
    else
        print("  |cffff0000✗|r Equipment Monitor not loaded!")
    end
    
    -- Check Debug System
    if PawnDebug then
        print("  |cff00ff00✓|r Debug System")
    else
        print("  |cffff0000✗|r Debug System not loaded!")
    end
    
    -- Check Test Framework
    if PawnTest then
        print("  |cff00ff00✓|r Test Framework")
    else
        print("  |cffff0000✗|r Test Framework not loaded!")
    end
    
    print("|cffffffaaTest Commands Available:|r")
    print("  /p1test all - Run all Phase 1 tests")
    print("  /p1test api - Test API compatibility")
    print("  /p1test timer - Test timer system")
    print("  /p1test event - Test event system")
    print("  /p1test equip - Test equipment monitoring")
    print("  /p1test debug - Test debug system")
    print("  /pawndebug on/off/dump - Debug controls")
end

-- Test Functions
local function TestAPI()
    print("|cff8ec3e6=== Testing API Compatibility ===|r")
    PawnTest:Start("API Tests")
    
    -- Test GetItemInfo wrapper
    local name = VgerCore.GetItemInfo(12345)
    PawnTest:Assert(name == nil or type(name) == "string", "GetItemInfo returns nil or string")
    
    -- Test Container API
    local slots = PawnAPICompat.GetContainerNumSlots(0)
    PawnTest:Assert(type(slots) == "number", "GetContainerNumSlots returns number")
    
    -- Test GetItemStats placeholder
    local stats = PawnAPICompat.GetItemStats("item:12345:0:0:0")
    PawnTest:Assert(type(stats) == "table", "GetItemStats returns table")
    
    PawnTest:End()
end

local function TestTimer()
    print("|cff8ec3e6=== Testing Timer System ===|r")
    
    local testComplete = false
    print("Starting 2 second timer test...")
    
    C_Timer.After(2, function()
        print("|cff00ff00✓|r Timer fired after 2 seconds!")
        testComplete = true
    end)
    
    -- Test ticker
    local tickCount = 0
    local ticker = C_Timer.NewTicker(1, function()
        tickCount = tickCount + 1
        print("  Tick #" .. tickCount)
    end, 3)
    
    print("Timer test started. You should see:")
    print("  - 3 ticks at 1 second intervals")
    print("  - Completion message after 2 seconds")
end

local function TestEventSystem()
    print("|cff8ec3e6=== Testing Event System ===|r")
    
    -- Register a test handler
    local eventFired = false
    PawnEventCompat:Register("UNIT_INVENTORY_CHANGED", function(unit)
        if not eventFired then
            print("|cff00ff00✓|r Event fired for unit: " .. tostring(unit))
            eventFired = true
        end
    end)
    
    print("Event handler registered.")
    print("Now equip or unequip an item to test...")
    print("Due to debouncing, there will be a 0.5s delay.")
end

local function TestEquipmentMonitor()
    print("|cff8ec3e6=== Testing Equipment Monitor ===|r")
    
    -- Initialize monitor
    PawnEquipmentMonitor:Initialize()
    print("Equipment Monitor initialized.")
    
    -- Show current equipment
    print("Current equipment slots with items:")
    for slot = 1, 19 do
        local link = GetInventoryItemLink("player", slot)
        if link then
            local slotName = PawnEquipmentMonitor:GetSlotName(slot)
            print(format("  %s: %s", slotName, link))
        end
    end
    
    print("Now change equipment to see monitoring in action.")
end

local function TestDebugSystem()
    print("|cff8ec3e6=== Testing Debug System ===|r")
    
    -- Enable debug
    PawnDebug.enabled = true
    PawnDebug.logLevel = 5  -- Show all messages
    
    -- Test different log levels
    PawnDebug:Log(1, "TEST", "This is an ERROR message")
    PawnDebug:Log(2, "TEST", "This is a WARNING message")
    PawnDebug:Log(3, "TEST", "This is an INFO message")
    PawnDebug:Log(4, "TEST", "This is a DEBUG message")
    PawnDebug:Log(5, "TEST", "This is a TRACE message")
    
    -- Test timer
    PawnDebug:StartTimer("TestOperation")
    -- Simulate some work
    local sum = 0
    for i = 1, 100000 do
        sum = sum + i
    end
    local elapsed = PawnDebug:EndTimer("TestOperation", "PERFORMANCE")
    
    print(format("Performance test completed in %.2f ms", elapsed or 0))
    print("Use /pawndebug dump to see the full log")
end

local function RunAllTests()
    print("|cff8ec3e6=== Running All Phase 1 Tests ===|r")
    TestAPI()
    TestTimer()
    TestEventSystem()
    TestEquipmentMonitor()
    TestDebugSystem()
    print("|cff8ec3e6=== All Tests Complete ===|r")
end

-- Slash Commands
SLASH_P1TEST1 = "/p1test"
SlashCmdList["P1TEST"] = function(msg)
    if msg == "all" then
        RunAllTests()
    elseif msg == "api" then
        TestAPI()
    elseif msg == "timer" then
        TestTimer()
    elseif msg == "event" then
        TestEventSystem()
    elseif msg == "equip" then
        TestEquipmentMonitor()
    elseif msg == "debug" then
        TestDebugSystem()
    elseif msg == "status" or msg == "info" then
        Phase1_OnLoad()
    else
        print("Usage: /p1test [all|api|timer|event|equip|debug|status]")
        print("  status - Show component load status")
    end
end

-- Auto-run on load
local frame = CreateFrame("Frame", "PawnPhase1TestFrame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function()
    -- In Vanilla, event is a global variable
    if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(2, Phase1_OnLoad)
    elseif event == "ADDON_LOADED" and arg1 == "Pawn" then
        -- Fallback if other events don't fire
        C_Timer.After(3, Phase1_OnLoad)
    end
end)