-- tests/manual/test_setup.lua
-- Test setup script for Turtle-WoW Pawn backport
-- Erstelle je einen Char Level 60:
-- Warrior, Rogue, Mage, Priest, Warlock, Hunter, Druid, Shaman, Paladin

-- Makro für Equipment-Test:
-- /script for i=1,19 do local link=GetInventoryItemLink("player",i) if link then print(i..": "..link) end end

-- Test Macros for different scenarios:

-- Basic functionality test
-- /script print("Test Pawn Turtle-WoW")

-- Get item info test 
-- /script print(GetItemInfo(4258))

-- Check Turtle-WoW version
-- /script if TURTLE_WOW_VERSION then print("Turtle WoW detected: " .. tostring(TURTLE_WOW_VERSION)) else print("Standard 1.12 client") end

-- Equipment slot test
-- /script for i=1,19 do local link=GetInventoryItemLink("player",i) if link then print(i..": "..link) end end

-- Container API test
-- /script print("Bags: " .. GetContainerNumSlots(0))

-- Test tooltip creation
-- /script local t = CreateFrame("GameTooltip", "TestTooltip", UIParent, "GameTooltipTemplate"); t:SetOwner(UIParent, "ANCHOR_NONE"); t:SetHyperlink("item:12345:0:0:0"); print("Tooltip test complete")