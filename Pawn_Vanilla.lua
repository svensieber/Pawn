-- Pawn by Vger-Azjol-Nerub
-- www.vgermods.com
-- © 2006-2025 Travis Spomer.  This mod is released under the Creative Commons Attribution-NonCommercial-NoDerivs 3.0 license.
-- See Readme.htm for more information.
--
-- Vanilla WoW (1.12.1) / Turtle WoW version
------------------------------------------------------------

-- Check dependencies
if not VgerCore then
	message("Pawn requires VgerCore to run.  Please ensure that VgerCore is installed and enabled.")
	return
end
if not PawnCompatDebug then
	message("Pawn requires PawnCompat_Vanilla to run.  Please ensure compatibility layer is loaded.")
	return
end

local ScaleProviderName = "Pawn"

-- Item cache
PawnItemCache = {}
PawnItemCacheMaxSize = 200

-- Saved variables defaults
PawnCommonDefault = {
	Debug = false,
	Scales = {},
	ShowUpgradesOnTooltips = true,
	ShowValuesForUpgradesOnly = true,
	ShowTooltipIcons = true,
	ShowBagUpgradeAdvisor = true,
	AlignNumbersRight = false,
	ColorTooltipBorder = true,
	IgnoreGemsWhileLeveling = true,
	ShowRelicUpgrades = false, -- Not applicable for Vanilla
	ShowItemLevelUpgrades = false,
	ShowEnchanted = PawnShowEnchantedDefault,
	ShowArtifactUpgradeAdvisor = false, -- Not applicable for Vanilla
	ShowSetBonusValueInTooltips = true,
	ShowLootUpgradeAdvisor = true,
	AutoSelectScales = true,
	UpgradeTrackingEnabled = true,
	ShowUpgradeDebugInfo = false,
	MigrationVersion = 0,
}

PawnOptionsDefault = {
	Debug = false,
	Scales = {},
	HiddenScales = {},
	ShowComparisonsForBestItems = true,
	["BestItems"] = {},
	EasyKeybindingsMinimum = 1.03,
	["BestItemFor"] = {},
	ShowBestGemsByFamily = true,
	ResetUpgrades = 0,
}

-- Main event frame
local PawnEventFrame = CreateFrame("Frame", "PawnEventFrame")

------------------------------------------------------------
-- Main event handler
------------------------------------------------------------

function PawnOnEvent(Event)
	-- In Lua 5.0, event arguments are in the global arg table
	
	if Event == "ADDON_LOADED" then
		-- In Vanilla, arg1 contains the addon name
		if arg1 == "Pawn" then
			PawnInitialize()
		end
	elseif Event == "PLAYER_LOGIN" then
		PawnPlayerLogin()
	elseif Event == "UNIT_INVENTORY_CHANGED" and arg1 == "player" then
		PawnUnitInventoryChanged()
	elseif Event == "PLAYER_EQUIPMENT_CHANGED" then
		PawnPlayerEquipmentChanged()
	elseif Event == "ITEM_LOCKED" then
		PawnItemLocked(arg1, arg2)
	elseif Event == "BAG_UPDATE" then
		PawnBagUpdate()
	elseif Event == "PLAYER_LEVEL_UP" then
		PawnOnPlayerLevelUp(arg1, arg2)
	elseif Event == "CHAT_MSG_LOOT" then
		PawnOnChatMsgLoot(arg1)
	elseif Event == "VARIABLES_LOADED" then
		-- Alternative initialization point
		if not PawnInitialized then
			PawnInitialize()
		end
	end
end

-- Set up event handlers
PawnEventFrame:SetScript("OnEvent", PawnOnEvent)
PawnEventFrame:RegisterEvent("ADDON_LOADED")
PawnEventFrame:RegisterEvent("PLAYER_LOGIN")
PawnEventFrame:RegisterEvent("VARIABLES_LOADED")

------------------------------------------------------------
-- Initialization
------------------------------------------------------------

function PawnInitialize()
	-- Prevent double initialization
	if PawnInitialized then return end
	PawnInitialized = true
	
	-- Load saved variables
	if not PawnCommon then PawnCommon = {} end
	if not PawnOptions then PawnOptions = {} end
	
	-- Apply defaults
	PawnFillMissingDefaults(PawnCommon, PawnCommonDefault)
	PawnFillMissingDefaults(PawnOptions, PawnOptionsDefault)
	
	-- Initialize caches
	if not PawnItemCache then PawnItemCache = {} end
	
	-- Set up slash commands
	SLASH_PAWN1 = "/pawn"
	SlashCmdList["PAWN"] = PawnCommand
	
	-- Hook tooltips (simplified for Vanilla)
	PawnHookTooltips()
	
	PawnDebugLog("Pawn initialized")
	
	-- Debug message
	if DEFAULT_CHAT_FRAME then
		DEFAULT_CHAT_FRAME:AddMessage("|cff8ec3e6Pawn: Initialization complete, /pawn registered|r")
	end
end

function PawnPlayerLogin()
	-- Register additional events after login
	PawnEventFrame:RegisterEvent("UNIT_INVENTORY_CHANGED")
	PawnEventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
	PawnEventFrame:RegisterEvent("ITEM_LOCKED")
	PawnEventFrame:RegisterEvent("BAG_UPDATE")
	PawnEventFrame:RegisterEvent("PLAYER_LEVEL_UP")
	PawnEventFrame:RegisterEvent("CHAT_MSG_LOOT")
	
	-- Get player info
	PawnPlayerClass = UnitClass("player")
	PawnPlayerClassName = string.upper(string.gsub(PawnPlayerClass, " ", ""))
	
	-- Initialize scale providers
	PawnInitializeScaleProviders()
	
	VgerCore.Message(VgerCore.Color.Blue .. "Pawn loaded.  Type " .. VgerCore.Color.Green .. "/pawn" .. VgerCore.Color.Blue .. " for options.")
end

------------------------------------------------------------
-- Slash commands
------------------------------------------------------------

function PawnCommand(Command)
	if not Command or Command == "" or Command == "help" or Command == "?" then
		PawnShowHelp()
	elseif Command == "debug on" or Command == "debug" then
		PawnCommon.Debug = true
		VgerCore.Message("Pawn debugging enabled.")
	elseif Command == "debug off" then
		PawnCommon.Debug = false
		VgerCore.Message("Pawn debugging disabled.")
	elseif Command == "backup" then
		PawnShowBackup()
	else
		PawnShowHelp()
	end
end

function PawnShowHelp()
	VgerCore.Message(" ")
	VgerCore.Message(VgerCore.Color.Blue .. "Pawn commands:")
	VgerCore.Message("/pawn " .. VgerCore.Color.Green .. "help" .. VgerCore.Color.Blue .. " - Show this help")
	VgerCore.Message("/pawn " .. VgerCore.Color.Green .. "debug on/off" .. VgerCore.Color.Blue .. " - Enable/disable debug mode")
	VgerCore.Message("/pawn " .. VgerCore.Color.Green .. "backup" .. VgerCore.Color.Blue .. " - Show scale backup string")
	VgerCore.Message(" ")
end

------------------------------------------------------------
-- Tooltip hooks (simplified for Vanilla)
------------------------------------------------------------

function PawnHookTooltips()
	-- Hook main tooltip
	local OldSetBagItem = GameTooltip.SetBagItem
	GameTooltip.SetBagItem = function(self, bag, slot)
		OldSetBagItem(self, bag, slot)
		PawnUpdateTooltip("GameTooltip", bag, slot)
	end
	
	local OldSetInventoryItem = GameTooltip.SetInventoryItem
	GameTooltip.SetInventoryItem = function(self, unit, slot)
		OldSetInventoryItem(self, unit, slot)
		if unit == "player" then
			PawnUpdateTooltip("GameTooltip", nil, nil, slot)
		end
	end
	
	-- Hook item ref tooltip (links in chat)
	local OldSetHyperlink = ItemRefTooltip.SetHyperlink
	ItemRefTooltip.SetHyperlink = function(self, link)
		OldSetHyperlink(self, link)
		PawnUpdateTooltipWithItemLink("ItemRefTooltip", link)
	end
end

------------------------------------------------------------
-- Basic item functions
------------------------------------------------------------

function PawnGetItemData(ItemLink)
	if not ItemLink then return end
	
	-- Check cache first
	local CachedItem = PawnItemCache[ItemLink]
	if CachedItem then
		return CachedItem
	end
	
	-- Get basic item info from Vanilla API
	local ItemName, _, ItemRarity, ItemLevel, _, _, _, _, EquipLoc, ItemTexture = GetItemInfo(ItemLink)
	if not ItemName then return end
	
	-- Create item data structure
	local Item = {
		Name = ItemName,
		Link = ItemLink,
		Rarity = ItemRarity,
		Level = ItemLevel,
		Texture = ItemTexture,
		EquipLoc = EquipLoc,
		Stats = {},
	}
	
	-- In Vanilla, we need to parse stats from tooltip
	-- This will be implemented in TooltipParsing_Vanilla.lua
	
	-- Add to cache
	PawnAddItemToCache(ItemLink, Item)
	
	return Item
end

function PawnAddItemToCache(ItemLink, Item)
	-- Add to cache with size limit
	PawnItemCache[ItemLink] = Item
	
	-- Simple cache size management
	local CacheSize = 0
	for _ in pairs(PawnItemCache) do
		CacheSize = CacheSize + 1
	end
	
	if CacheSize > PawnItemCacheMaxSize then
		-- Remove oldest items (simplified - just clear half the cache)
		local Count = 0
		for Link in pairs(PawnItemCache) do
			PawnItemCache[Link] = nil
			Count = Count + 1
			if Count > PawnItemCacheMaxSize / 2 then break end
		end
	end
end

------------------------------------------------------------
-- Scale management
------------------------------------------------------------

function PawnInitializeScaleProviders()
	-- Initialize built-in scales
	if not PawnCommon.Scales then PawnCommon.Scales = {} end
	
	-- Add default scale for testing
	if not PawnCommon.Scales["Test"] then
		PawnCommon.Scales["Test"] = {
			["Strength"] = 1,
			["Agility"] = 1,
			["Stamina"] = 1,
			["Intellect"] = 1,
			["Spirit"] = 1,
		}
	end
end

function PawnGetAllScales()
	return PawnCommon.Scales or {}
end

function PawnGetScaleValues(ScaleName)
	if not ScaleName or not PawnCommon.Scales then return end
	return PawnCommon.Scales[ScaleName]
end

------------------------------------------------------------
-- Tooltip updates (basic version)
------------------------------------------------------------

function PawnUpdateTooltip(TooltipName, Bag, Slot, InventorySlot)
	if not PawnCommon.ShowUpgradesOnTooltips then return end
	
	local ItemLink
	if Bag and Slot then
		ItemLink = GetContainerItemLink(Bag, Slot)
	elseif InventorySlot then
		ItemLink = GetInventoryItemLink("player", InventorySlot)
	end
	
	if ItemLink then
		PawnUpdateTooltipWithItemLink(TooltipName, ItemLink)
	end
end

function PawnUpdateTooltipWithItemLink(TooltipName, ItemLink)
	if not ItemLink or not PawnCommon.ShowUpgradesOnTooltips then return end
	
	local Tooltip = getglobal(TooltipName)
	if not Tooltip then return end
	
	-- Get item data
	local Item = PawnGetItemData(ItemLink)
	if not Item then return end
	
	-- Add debug info for now
	if PawnCommon.Debug then
		Tooltip:AddLine(" ")
		Tooltip:AddLine(VgerCore.Color.Blue .. "Pawn debug:", 1, 1, 1)
		Tooltip:AddLine("Item level: " .. tostring(Item.Level), 1, 1, 1)
		Tooltip:AddLine("Equip slot: " .. tostring(Item.EquipLoc), 1, 1, 1)
	end
	
	-- Update tooltip display
	Tooltip:Show()
end

------------------------------------------------------------
-- Utility functions
------------------------------------------------------------

function PawnFillMissingDefaults(Table, Defaults)
	if not Table or not Defaults then return end
	for Key, Value in pairs(Defaults) do
		if Table[Key] == nil then
			if type(Value) == "table" then
				Table[Key] = {}
				PawnFillMissingDefaults(Table[Key], Value)
			else
				Table[Key] = Value
			end
		end
	end
end

function PawnDebugLog(Message)
	if PawnCommon and PawnCommon.Debug then
		VgerCore.Message(VgerCore.Color.Grey .. "[Pawn] " .. tostring(Message))
	end
end

------------------------------------------------------------
-- Event handlers (stubs for now)
------------------------------------------------------------

function PawnUnitInventoryChanged()
	PawnDebugLog("Unit inventory changed")
end

function PawnPlayerEquipmentChanged()
	PawnDebugLog("Player equipment changed")
end

function PawnItemLocked(Bag, Slot)
	PawnDebugLog("Item locked: " .. tostring(Bag) .. "/" .. tostring(Slot))
end

function PawnBagUpdate()
	-- Throttle this event in real implementation
end

function PawnOnPlayerLevelUp(NewLevel, LevelDelta)
	PawnDebugLog("Player leveled up to " .. tostring(NewLevel))
end

function PawnOnChatMsgLoot(Message)
	-- Handle loot messages
end

function PawnShowBackup()
	VgerCore.Message(" ")
	VgerCore.Message(VgerCore.Color.Blue .. "Pawn scale backup:")
	VgerCore.Message("(Backup functionality will be implemented)")
	VgerCore.Message(" ")
end

-- Debug message
PawnDebugLog("Pawn_Vanilla.lua loaded")

-- Direct initialization for Vanilla
-- In Vanilla, sometimes ADDON_LOADED doesn't fire properly
-- So we initialize directly when the file loads
if not PawnInitialized then
	-- Delay initialization slightly to ensure all files are loaded
	local InitFrame = CreateFrame("Frame")
	InitFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	InitFrame:SetScript("OnEvent", function()
		if not PawnInitialized then
			DEFAULT_CHAT_FRAME:AddMessage("|cff8ec3e6Pawn: Starting initialization...|r")
			PawnInitialize()
		end
		this:UnregisterEvent("PLAYER_ENTERING_WORLD")
	end)
	
	-- Also try immediate initialization
	-- This works if we're already in-game (reload)
	if UnitName("player") and UnitName("player") ~= "Unknown Entity" then
		DEFAULT_CHAT_FRAME:AddMessage("|cff8ec3e6Pawn: Direct initialization (reload detected)|r")
		PawnInitialize()
	end
end