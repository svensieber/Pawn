-- Pawn Vanilla Test File
-- Temporary file for early testing in Turtle WoW

function Pawn_OnLoad()
    DEFAULT_CHAT_FRAME:AddMessage("|cff8ec3e6Pawn Vanilla geladen!|r")
    
    -- Test compatibility layer
    if PawnCompatDebug then
        PawnCompatDebug("Test: Compatibility layer active")
    end
    
    -- Test Lua 5.0 features
    local testTable = {1, 2, 3, 4, 5}
    local tableLen = table.getn(testTable)
    DEFAULT_CHAT_FRAME:AddMessage("|cff8ec3e6Pawn: Table length test = " .. tableLen .. "|r")
    
    -- Test WoW 1.12.1 API
    if GetItemInfo then
        DEFAULT_CHAT_FRAME:AddMessage("|cff8ec3e6Pawn: GetItemInfo exists|r")
    end
    
    if C_Item and C_Item.GetItemInfo then
        DEFAULT_CHAT_FRAME:AddMessage("|cff8ec3e6Pawn: C_Item compatibility layer active|r")
    end
end

function Pawn_OnEvent(event)
    if event == "PLAYER_LOGIN" then
        DEFAULT_CHAT_FRAME:AddMessage("|cff8ec3e6Pawn: Player login erkannt|r")
        Pawn_OnLoad()
    elseif event == "VARIABLES_LOADED" then
        DEFAULT_CHAT_FRAME:AddMessage("|cff8ec3e6Pawn: Variables loaded|r")
    elseif event == "ADDON_LOADED" then
        local addon = arg1  -- In Lua 5.0, arg1 contains the addon name
        if addon == "Pawn" then
            DEFAULT_CHAT_FRAME:AddMessage("|cff8ec3e6Pawn: Addon loaded event fired|r")
        end
    end
end

-- Frame erstellen
local frame = CreateFrame("Frame", "PawnTestFrame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("VARIABLES_LOADED")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", Pawn_OnEvent)

-- Error logging
PawnErrorLog = {}

-- Hook error handler
local oldError = geterrorhandler()
seterrorhandler(function(msg)
    table.insert(PawnErrorLog, {
        time = date("%H:%M:%S"),
        error = msg
    })
    if oldError then oldError(msg) end
end)

-- Debug-Modus aktivieren für Errors
SLASH_PAWNDEBUG1 = "/pawndebug"
SlashCmdList["PAWNDEBUG"] = function()
    -- Force script errors to show
    SetCVar("scriptErrors", 1)
    DEFAULT_CHAT_FRAME:AddMessage("|cff8ec3e6Pawn: Script errors enabled|r")
    
    -- Trigger a test error to see if BugSack catches it
    DEFAULT_CHAT_FRAME:AddMessage("|cff8ec3e6Pawn: Triggering test error...|r")
    local testfunc = function()
        error("Pawn Test Error for BugSack")
    end
    pcall(testfunc)
end

-- Export errors command
SLASH_PAWNERRORS1 = "/pawnerrors"
SlashCmdList["PAWNERRORS"] = function()
    DEFAULT_CHAT_FRAME:AddMessage("|cff8ec3e6=== Pawn Error Log (" .. table.getn(PawnErrorLog) .. " errors) ===|r")
    for i, err in ipairs(PawnErrorLog) do
        DEFAULT_CHAT_FRAME:AddMessage(err.time .. ": " .. err.error)
    end
end

-- Test slash command
SLASH_PAWNTEST1 = "/pawntest"
SlashCmdList["PAWNTEST"] = function(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff8ec3e6Pawn Test: " .. (msg or "no message") .. "|r")
    
    -- Test item info
    local testItemID = 19019  -- Thunderfury
    local name, link = GetItemInfo(testItemID)
    if name then
        DEFAULT_CHAT_FRAME:AddMessage("|cff8ec3e6Item test: " .. name .. "|r")
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cff8ec3e6Item test: Item not in cache|r")
    end
    
    -- Test C_Item compatibility
    if C_Item and C_Item.GetItemInfoInstant then
        local itemID, class, subclass, equipSlot = C_Item.GetItemInfoInstant(testItemID)
        DEFAULT_CHAT_FRAME:AddMessage("|cff8ec3e6C_Item test: " .. tostring(class) .. "/" .. tostring(subclass) .. "|r")
    end
    
    -- Test VgerCore
    if VgerCore then
        DEFAULT_CHAT_FRAME:AddMessage("|cff8ec3e6VgerCore loaded! Version: " .. tostring(VgerCore.Version) .. "|r")
        VgerCore.Message(VgerCore.Color.Green .. "VgerCore color test" .. VgerCore.Color.Reset)
        DEFAULT_CHAT_FRAME:AddMessage("|cff8ec3e6VgerCore.IsClassic = " .. tostring(VgerCore.IsClassic) .. "|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cff8ec3e6VgerCore.IsTurtle = " .. tostring(VgerCore.IsTurtle) .. "|r")
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000VgerCore NOT loaded!|r")
    end
    
    -- Test Core
    if PawnClassic then
        DEFAULT_CHAT_FRAME:AddMessage("|cff8ec3e6PawnClassic = " .. tostring(PawnClassic) .. "|r")
    end
    if PawnGameConstant then
        local testPattern = PawnGameConstant("test %s pattern")
        DEFAULT_CHAT_FRAME:AddMessage("|cff8ec3e6Core function test: " .. testPattern .. "|r")
    end
    
    -- Test if Pawn_Vanilla.lua loaded
    if PawnInitialize then
        DEFAULT_CHAT_FRAME:AddMessage("|cff8ec3e6PawnInitialize function exists|r")
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000PawnInitialize NOT found!|r")
    end
    
    -- Test slash commands
    if SlashCmdList["PAWN"] then
        DEFAULT_CHAT_FRAME:AddMessage("|cff8ec3e6/pawn command is registered|r")
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000/pawn command NOT registered!|r")
    end
end

-- Additional debug command
SLASH_PAWNCHECK1 = "/pawncheck"
SlashCmdList["PAWNCHECK"] = function()
    DEFAULT_CHAT_FRAME:AddMessage("|cff8ec3e6=== Pawn Status Check ===|r")
    DEFAULT_CHAT_FRAME:AddMessage("PawnEventFrame: " .. tostring(PawnEventFrame))
    DEFAULT_CHAT_FRAME:AddMessage("PawnInitialize: " .. tostring(PawnInitialize))
    DEFAULT_CHAT_FRAME:AddMessage("PawnCommand: " .. tostring(PawnCommand))
    DEFAULT_CHAT_FRAME:AddMessage("SLASH_PAWN1: " .. tostring(SLASH_PAWN1))
    DEFAULT_CHAT_FRAME:AddMessage("SlashCmdList.PAWN: " .. tostring(SlashCmdList["PAWN"]))
    
    -- Check if ADDON_LOADED fired
    if PawnCommon then
        DEFAULT_CHAT_FRAME:AddMessage("PawnCommon exists (addon loaded)")
    else
        DEFAULT_CHAT_FRAME:AddMessage("PawnCommon is nil (addon NOT loaded)")
    end
end