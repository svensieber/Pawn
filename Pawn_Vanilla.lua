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
	-- Make sure PawnCommon exists
	if not PawnCommon then
		PawnCommon = {}
		PawnFillMissingDefaults(PawnCommon, PawnCommonDefault)
	end
	
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
	-- Debug message
	PawnDebugLog("Installing tooltip hooks...")
	
	-- Check if hooks are disabled
	if PawnHooksDisabled then
		PawnDebugLog("Tooltip hooks disabled by user")
		return
	end
	
	-- Alternative approach: Read item info directly from tooltip
	-- This works even when GetContainerItemLink returns just the name
	
	-- Hook the tooltip's OnShow to add our info
	GameTooltip:HookScript("OnShow", function()
		if not PawnCommon or not PawnCommon.Debug then return end
		if this.PawnInfoAdded then return end
		
		-- Get the first line of the tooltip (item name)
		local itemName = getglobal(this:GetName().."TextLeft1")
		if not itemName then return end
		
		local name = itemName:GetText()
		if not name or name == "" then return end
		
		-- Extract basic info from tooltip
		local itemInfo = PawnExtractTooltipInfo(this)
		
		-- Always add debug info
		this:AddLine(" ")
		this:AddLine(VgerCore.Color.Blue .. "Pawn debug:", 1, 1, 1)
		this:AddLine("Name: " .. name, 1, 1, 1)
		
		-- Show number of lines in tooltip
		local numLines = this:NumLines()
		this:AddLine("Tooltip lines: " .. numLines, 1, 1, 1)
		
		-- Show extracted info
		if itemInfo.level then
			this:AddLine("Level: " .. itemInfo.level, 1, 1, 1)
		end
		if itemInfo.type then
			this:AddLine("Type: " .. itemInfo.type, 1, 1, 1)
		end
		if itemInfo.stats and table.getn(itemInfo.stats) > 0 then
			this:AddLine("Stats found: " .. table.getn(itemInfo.stats), 1, 1, 1)
			-- Show all stats (or max 10 to avoid tooltip overflow)
			for i = 1, math.min(10, table.getn(itemInfo.stats)) do
				this:AddLine("  " .. itemInfo.stats[i], 0.8, 0.8, 0.8)
			end
		else
			this:AddLine("No stats found - check chat for details", 1, 0.5, 0.5)
		end
		
		-- Try to get item link for more info
		local itemLink = PawnGetItemLinkFromTooltip(this)
		if itemLink and string.find(itemLink, "^|c%x+|Hitem:") then
			local Item = PawnGetItemData(itemLink)
			if Item then
				this:AddLine("Rarity: " .. tostring(Item.Rarity), 1, 1, 1)
				this:AddLine("Equip: " .. tostring(Item.EquipLoc), 1, 1, 1)
			end
		end
		
		this:Show()
		this.PawnInfoAdded = true
	end)
	
	-- Clear flag when tooltip hides
	GameTooltip:HookScript("OnHide", function()
		this.PawnInfoAdded = nil
	end)
	
	-- For item links in chat
	local OldSetHyperlink = ItemRefTooltip.SetHyperlink
	ItemRefTooltip.SetHyperlink = function(link)
		-- Make sure we have a valid link
		if not link or type(link) ~= "string" then 
			if OldSetHyperlink then
				OldSetHyperlink(link)
			end
			return 
		end
		
		-- Call original function with error handling
		local success, err = pcall(OldSetHyperlink, link)
		if not success then
			PawnDebugLog("SetHyperlink error: " .. tostring(err))
			return
		end
		
		-- Add our info only for item links
		if PawnCommon and PawnCommon.Debug and string.find(link, "^item:") then
			-- Delay slightly to let tooltip populate
			local frame = CreateFrame("Frame")
			frame:SetScript("OnUpdate", function()
				this:SetScript("OnUpdate", nil)
				PawnUpdateTooltipWithItemLink("ItemRefTooltip", link)
			end)
		end
	end
	
	PawnDebugLog("Tooltip hooks installed (OnUpdate method)")
end

------------------------------------------------------------
-- Basic item functions
------------------------------------------------------------

-- Try to extract item link from tooltip
function PawnGetItemLinkFromTooltip(tooltip)
	-- In Vanilla, we need to scan the tooltip for the item
	-- First, check if the tooltip has an associated item
	
	-- Try to get from current mouse focus
	local focus = GetMouseFocus()
	if focus and focus.GetName then
		local name = focus:GetName()
		if name then
			PawnDebugLog("Mouse focus: " .. name)
			
			-- For container items
			if string.find(name, "ContainerFrame") then
				local _, _, container, slot = string.find(name, "ContainerFrame(%d+)Item(%d+)")
				if container and slot then
					container = tonumber(container) - 1
					slot = tonumber(slot)
					
					-- Try multiple methods to get the link
					-- Method 1: Direct GetContainerItemLink
					local link = GetContainerItemLink(container, slot)
					PawnDebugLog("GetContainerItemLink returned: " .. tostring(link))
					
					-- Method 2: Create link from item ID if we have it
					if (not link or link == "" or not string.find(tostring(link), "^|c%x+|Hitem:")) and focus.hasItem then
						-- Try to get item ID from the button
						local itemId = nil
						
						-- Check if there's an item texture
						local texture = GetContainerItemInfo(container, slot)
						if texture then
							-- In Vanilla, we might need to scan for the item
							-- Create a temporary tooltip to scan
							if not PawnScanTooltip then
								PawnScanTooltip = CreateFrame("GameTooltip", "PawnScanTooltip", UIParent, "GameTooltipTemplate")
							end
							PawnScanTooltip:SetOwner(UIParent, "ANCHOR_NONE")
							PawnScanTooltip:ClearLines()
							PawnScanTooltip:SetBagItem(container, slot)
							
							-- Try to extract item link from hidden tooltip
							local scanLink = PawnScanTooltipForLink()
							if scanLink then
								PawnDebugLog("Got link from scan: " .. scanLink)
								return scanLink
							end
						end
					end
					
					if link and string.find(tostring(link), "^|c%x+|Hitem:") then
						return link
					end
				end
			-- For inventory items
			elseif string.find(name, "Character") and string.find(name, "Slot") then
				local _, _, slotName = string.find(name, "Character(.+)Slot")
				if slotName then
					local slotId = GetInventorySlotInfo(slotName .. "Slot")
					if slotId then
						local link = GetInventoryItemLink("player", slotId)
						PawnDebugLog("GetInventoryItemLink returned: " .. tostring(link))
						if link and string.find(tostring(link), "^|c%x+|Hitem:") then
							return link
						end
					end
				end
			end
		end
	end
	
	return nil
end

-- Scan a hidden tooltip for item link
function PawnScanTooltipForLink()
	if not PawnScanTooltip then return nil end
	
	-- In Vanilla, item links might be in tooltip text
	-- This is a workaround since GetContainerItemLink doesn't always work
	
	-- For now, return nil - proper tooltip scanning would be complex
	return nil
end

-- Extract basic info from visible tooltip
function PawnExtractTooltipInfo(tooltip)
	local info = {
		stats = {}
	}
	
	-- Scan all tooltip lines
	local numLines = tooltip:NumLines()
	PawnDebugLog("Scanning tooltip with " .. numLines .. " lines")
	
	-- Temporary: collect all lines for debugging
	local allLines = {}
	
	for i = 2, numLines do  -- Start at 2 to skip item name
		local leftText = getglobal(tooltip:GetName().."TextLeft"..i)
		local rightText = getglobal(tooltip:GetName().."TextRight"..i)
		
		if leftText then
			local text = leftText:GetText()
			if text and text ~= "" then
				-- Get text color
				local r, g, b = leftText:GetTextColor()
				PawnDebugLog("Line " .. i .. " (L): " .. text .. " [Color: " .. string.format("%.2f,%.2f,%.2f", r, g, b) .. "]")
				
				-- Temporary: collect all lines
				table.insert(allLines, {text = text, color = string.format("%.2f,%.2f,%.2f", r, g, b), side = "left"})
				
				-- Check for item level (e.g. "Item Level 55")
				local _, _, level = string.find(text, "Item Level (%d+)")
				if level then
					info.level = tonumber(level)
				end
				
				-- Check for item type (e.g. "Two-Hand Sword")
				-- Usually in grey text
				if r > 0.6 and g > 0.6 and b > 0.6 and r < 0.7 and g < 0.7 and b < 0.7 then
					-- Grey text, might be item type
					if not string.find(text, "Level") and not string.find(text, "Durability") then
						info.type = text
					end
				end
				
				-- Check for stats (green text or other stat colors)
				-- In Vanilla/Turtle WoW, stats can have different colors
				-- Green: enchants and bonuses
				-- White: base stats
				-- Let's collect all potential stats for now
				
				-- Skip lines we don't care about
				if string.find(text, "Durability") or 
				   string.find(text, "Requires Level") or
				   string.find(text, "Classes:") or
				   string.find(text, "Races:") or
				   string.find(text, "Gold") or
				   string.find(text, "Silver") or
				   string.find(text, "Copper") or
				   string.find(text, "Vendor") or
				   string.find(text, "Value") or
				   string.find(text, "Today") or
				   string.find(text, "%d+g %d+s") or -- Gold patterns like "4g 69s"
				   string.find(text, "%d+s %d+c") or -- Silver/copper patterns
				   string.find(text, "^%d+c$") or -- Just copper like "0c"
				   string.find(text, "^%d+$") then -- Just numbers like "22"
					PawnDebugLog("Skipping line: " .. text)
				else
					-- Check if it's a stat line
					local isStat = false
					
					-- Green text (bonuses)
					if r < 0.2 and g > 0.8 and b < 0.2 then
						isStat = true
					-- White text with numbers (armor, damage, etc)
					elseif r > 0.9 and g > 0.9 and b > 0.9 then
						if string.find(text, "%d") and not string.find(text, "Item Level") then
							-- Skip standalone speed lines - they shouldn't appear for non-weapons
							if string.find(text, "^Speed %d") then
								PawnDebugLog("Skipping standalone speed: " .. text)
							else
								isStat = true
								-- Check if it's a damage line with speed (e.g. "38 - 58 Damage Speed 3.60")
								if string.find(text, "Damage") and string.find(text, "Speed") then
									-- This line contains both damage and speed, might want to split later
									PawnDebugLog("Found damage+speed line: " .. text)
								end
							end
						end
					-- Yellow text (rare stats)
					elseif r > 0.9 and g > 0.8 and b < 0.2 then
						isStat = true
					end
					
					-- Also check for weapon type line (e.g. "Two-Hand Axe")
					-- This is usually gray text and we already handle it as item type
					
					if isStat then
						table.insert(info.stats, text)
						PawnDebugLog("Found stat: " .. text)
					end
				end
			end
		end
		
		-- Check right side text (often has values)
		if rightText then
			local text = rightText:GetText()
			if text and text ~= "" then
				local r, g, b = rightText:GetTextColor()
				PawnDebugLog("Line " .. i .. " (R): " .. text .. " [Color: " .. string.format("%.2f,%.2f,%.2f", r, g, b) .. "]")
				
				-- Right side often has weapon speed and other values
				-- But Speed shouldn't appear for armor/shields
				-- Skip speed entirely here - it should be in the damage line for weapons
				if string.find(text, "Speed") then
					PawnDebugLog("Skipping speed on right side: " .. text)
				end
			end
		end
	end
	
	PawnDebugLog("Extraction complete: Found " .. table.getn(info.stats) .. " stats")
	return info
end

function PawnGetItemData(ItemLink)
	if not ItemLink then 
		PawnDebugLog("PawnGetItemData: No ItemLink provided")
		return 
	end
	
	PawnDebugLog("PawnGetItemData called for: " .. tostring(ItemLink))
	
	-- Check cache first
	local CachedItem = PawnItemCache[ItemLink]
	if CachedItem then
		PawnDebugLog("Found in cache: " .. tostring(CachedItem.Name))
		return CachedItem
	end
	
	-- Get basic item info from Vanilla API
	local ItemName, _, ItemRarity, ItemLevel, _, _, _, _, EquipLoc, ItemTexture = GetItemInfo(ItemLink)
	if not ItemName then 
		PawnDebugLog("GetItemInfo returned nil for: " .. tostring(ItemLink))
		-- In Vanilla, items need to be cached by the client
		-- Try to query server
		-- Lua 5.0 doesn't have string.match, use string.find
		local _, _, itemId = string.find(ItemLink, "item:(%d+)")
		itemId = tonumber(itemId)
		if itemId then
			-- Request item info from server
			-- In Vanilla, we can't always use SetHyperlink directly
			-- Just log that we need to wait for the item to cache
			PawnDebugLog("Item not in cache, ID: " .. itemId .. " - hover again to load")
		end
		return 
	end
	
	PawnDebugLog("Got item info: " .. tostring(ItemName) .. " Level: " .. tostring(ItemLevel))
	
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
	-- Ensure PawnCommon exists
	if not PawnCommon then return end
	if not PawnCommon.ShowUpgradesOnTooltips and not PawnCommon.Debug then return end
	
	local ItemLink
	if Bag and Slot then
		-- Validate parameters for Vanilla
		if type(Bag) == "number" and type(Slot) == "number" then
			ItemLink = GetContainerItemLink(Bag, Slot)
		else
			PawnDebugLog("Invalid bag/slot parameters: " .. tostring(Bag) .. "/" .. tostring(Slot))
			return
		end
	elseif InventorySlot then
		ItemLink = GetInventoryItemLink("player", InventorySlot)
	end
	
	if ItemLink then
		PawnUpdateTooltipWithItemLink(TooltipName, ItemLink)
	else
		PawnDebugLog("No item link found for tooltip update")
	end
end

function PawnUpdateTooltipWithItemLink(TooltipName, ItemLink)
	-- Ensure PawnCommon exists
	if not PawnCommon then return end
	
	-- Validate ItemLink
	if not ItemLink or type(ItemLink) ~= "string" then 
		PawnDebugLog("Invalid ItemLink: " .. tostring(ItemLink))
		return 
	end
	
	-- Check if it's actually an item link
	if not string.find(ItemLink, "^item:") then
		PawnDebugLog("Not an item link: " .. ItemLink)
		return
	end
	
	-- Always show debug info if debug is on, regardless of ShowUpgradesOnTooltips
	if not PawnCommon.ShowUpgradesOnTooltips and not PawnCommon.Debug then return end
	
	local Tooltip = getglobal(TooltipName)
	if not Tooltip then 
		PawnDebugLog("Tooltip not found: " .. tostring(TooltipName))
		return 
	end
	
	-- Make sure tooltip is visible
	if not Tooltip:IsVisible() then
		PawnDebugLog("Tooltip not visible: " .. TooltipName)
		return
	end
	
	-- Get item data
	local Item = PawnGetItemData(ItemLink)
	if not Item then 
		-- Don't spam for items not in cache
		return 
	end
	
	-- Add debug info
	if PawnCommon and PawnCommon.Debug then
		Tooltip:AddLine(" ")
		Tooltip:AddLine(VgerCore.Color.Blue .. "Pawn debug:", 1, 1, 1)
		Tooltip:AddLine("Item: " .. tostring(Item.Name), 1, 1, 1)
		Tooltip:AddLine("Level: " .. tostring(Item.Level), 1, 1, 1)
		Tooltip:AddLine("Slot: " .. tostring(Item.EquipLoc), 1, 1, 1)
		Tooltip:AddLine("Rarity: " .. tostring(Item.Rarity), 1, 1, 1)
		
		-- Debug message to console
		PawnDebugLog("Updated tooltip for: " .. tostring(Item.Name))
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
	-- Safe debug logging
	if PawnCommon and PawnCommon.Debug then
		VgerCore.Message(VgerCore.Color.Grey .. "[Pawn] " .. tostring(Message))
	end
end

-- Ensure PawnOptions exists for other functions
function PawnEnsureOptions()
	if not PawnCommon then
		PawnCommon = {}
		PawnFillMissingDefaults(PawnCommon, PawnCommonDefault)
	end
	if not PawnOptions then
		PawnOptions = {}
		PawnFillMissingDefaults(PawnOptions, PawnOptionsDefault)
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