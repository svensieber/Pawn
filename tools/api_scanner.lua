-- tools/api_scanner.lua
-- API Scanner for Pawn Turtle-WoW backport
-- Scans Lua files for modern WoW API usage that needs replacement

local modernAPIs = {
    "C_Item", "C_ArtifactUI", "C_Timer", "C_Container",
    "TooltipUtil", "ProcessInfo", "SetItemByID",
    "GetDetailedItemLevelInfo", "C_Engraving", "C_MountJournal",
    "C_TransmogCollection", "C_Covenants", "C_MythicPlus",
    "C_GossipInfo", "C_QuestLog", "C_TradeSkillUI",
    "C_AzeriteEmpoweredItem", "C_ChallengeMode", "C_Scenario",
    "GetItemStats", "GetItemInfoInstant", "C_EquipmentSet",
    "C_PvP", "C_LFGList", "C_AdventureJournal", "C_Currency",
    "GetSpecialization", "GetSpecializationInfo", "GetTalentInfo",
    "C_ClassTalents", "C_Traits", "C_Soulbinds"
}

local function ScanFile(filepath)
    local file = io.open(filepath, "r")
    if not file then return {} end
    
    local content = file:read("*all")
    file:close()
    
    local found = {}
    local lineNum = 1
    
    -- Scan line by line for better reporting
    for line in content:gmatch("[^\r\n]+") do
        for _, api in ipairs(modernAPIs) do
            if string.find(line, api) then
                -- Record the line number and context
                found[api] = found[api] or {}
                table.insert(found[api], {
                    line = lineNum,
                    context = line:sub(1, 100) -- First 100 chars of line
                })
            end
        end
        lineNum = lineNum + 1
    end
    
    return found
end

-- Scan all Lua files
local filesToScan = {
    "Core.lua", 
    "Pawn.lua", 
    "PawnUI.lua", 
    "TooltipParsing.lua",
    "Gems.lua",
    "GemsClassic.lua", 
    "GemsRetail.lua",
    "ScaleProviders/Ask Mr. Robot.lua",
    "ScaleProviders/RaidBots.lua",
    "Localization.lua",
    "Localization.deDE.lua",
    "Localization.enUS.lua",
    "Localization.esES.lua",
    "Localization.esMX.lua",
    "Localization.frFR.lua",
    "Localization.itIT.lua",
    "Localization.koKR.lua",
    "Localization.ptBR.lua",
    "Localization.ruRU.lua",
    "Localization.zhCN.lua",
    "Localization.zhTW.lua"
}

local results = {}
local totalAPIsFound = 0

-- Check if running in Lua interpreter or in-game
local inGame = type(GetLocale) == "function"

if not inGame then
    -- Running in Lua interpreter
    print("Scanning Pawn files for modern API usage...")
    print("=" .. string.rep("=", 60))
    
    for _, file in ipairs(filesToScan) do
        local found = ScanFile(file)
        if next(found) then
            results[file] = found
            for api, occurrences in pairs(found) do
                totalAPIsFound = totalAPIsFound + #occurrences
            end
        end
    end
    
    -- Generate report
    local report = io.open("docs/turtle-wow/API_USAGE_REPORT.md", "w")
    report:write("# Modern API Usage Report\n\n")
    report:write("Generated: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n\n")
    report:write("Total modern APIs found: " .. totalAPIsFound .. " occurrences\n\n")
    
    report:write("## Summary\n\n")
    
    -- Count total occurrences per API
    local apiCounts = {}
    for file, apis in pairs(results) do
        for api, occurrences in pairs(apis) do
            apiCounts[api] = (apiCounts[api] or 0) + #occurrences
        end
    end
    
    -- Sort by frequency
    local sortedAPIs = {}
    for api, count in pairs(apiCounts) do
        table.insert(sortedAPIs, {api = api, count = count})
    end
    table.sort(sortedAPIs, function(a, b) return a.count > b.count end)
    
    report:write("| API | Total Occurrences |\n")
    report:write("|-----|------------------|\n")
    for _, data in ipairs(sortedAPIs) do
        report:write("| `" .. data.api .. "` | " .. data.count .. " |\n")
    end
    
    report:write("\n## Detailed Results\n\n")
    
    for file, apis in pairs(results) do
        report:write("### " .. file .. "\n\n")
        for api, occurrences in pairs(apis) do
            report:write("#### `" .. api .. "` (" .. #occurrences .. " occurrences)\n\n")
            for _, occurrence in ipairs(occurrences) do
                report:write("- Line " .. occurrence.line .. ": `" .. occurrence.context .. "`\n")
            end
            report:write("\n")
        end
    end
    
    report:write("\n## Replacement Notes\n\n")
    report:write("### Critical APIs requiring replacement:\n\n")
    report:write("- `C_Timer`: Must implement custom timer system\n")
    report:write("- `C_Container`: Use old Container API functions\n")
    report:write("- `C_Item`: Use GetItemInfo and related functions\n")
    report:write("- `GetItemStats`: Must parse from tooltip\n")
    report:write("- `GetSpecialization*`: No spec system in Vanilla\n")
    report:write("\n")
    
    report:close()
    
    print("\nReport generated: docs/turtle-wow/API_USAGE_REPORT.md")
    print("\nTop 5 most used modern APIs:")
    for i = 1, math.min(5, #sortedAPIs) do
        print(string.format("  %d. %s (%d occurrences)", 
            i, sortedAPIs[i].api, sortedAPIs[i].count))
    end
else
    -- Running in WoW
    print("API Scanner must be run outside of WoW using Lua interpreter")
    print("Usage: lua tools/api_scanner.lua")
end