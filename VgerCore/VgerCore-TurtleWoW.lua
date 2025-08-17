-- VgerCore/VgerCore-TurtleWoW.lua
-- DIESER CODE ERSETZT DIE MODERNE VERSION DETECTION

VgerCore = VgerCore or {}
VgerCore.Version = 1.20

-- Turtle-WoW-specific detection
local function GetWoWVersion()
    local version, build, date, tocversion = GetBuildInfo()
    return tocversion or 11200  -- 11200 = 1.12.0
end

VgerCore.BuildNumber = GetWoWVersion()
VgerCore.IsVanilla = (VgerCore.BuildNumber < 20000)
VgerCore.IsTurtleWoW = (TURTLE_WOW_VERSION ~= nil)

-- Feature flags for Turtle-WoW
VgerCore.Features = {
    RangedSlot = true,              -- Slot 18 exists
    Specializations = false,        -- No specs in Vanilla
    Reforging = false,             -- No reforging
    ItemUpgrade = false,           -- No item upgrades
    Artifacts = false,             -- No artifacts
    GetItemStats = false,          -- API doesn't exist!
    CItemAPI = false,              -- No C_Item namespace
}

-- API Compatibility layer
VgerCore.GetItemInfo = function(itemLink)
    -- Vanilla GetItemInfo has different returns!
    -- name, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice
    local name, link, quality, _, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(itemLink)
    
    -- Vanilla doesn't return itemLevel! Must parse from tooltip
    local itemLevel = 0  -- Will implement in Phase 2
    
    return name, link, quality, itemLevel, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice
end

print("VgerCore Turtle-WoW loaded - Version " .. VgerCore.Version)