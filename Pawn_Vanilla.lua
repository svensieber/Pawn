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

-- Equipped items cache
PawnEquippedItems = {}
PawnEquippedScores = {}

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
	ShowOnlyClassScales = true, -- Only show scales relevant to player's class
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
	PawnDebugLog("PawnPlayerLogin called")
	
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
	
	-- Scan equipped items
	PawnScanEquippedItems()
	
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
	elseif Command == "scales" then
		PawnShowScales()
	elseif Command == "init" then
		PawnInitializeScaleProviders()
		VgerCore.Message("Scale providers reinitialized.")
	elseif Command == "scan" then
		PawnScanEquippedItems()
		VgerCore.Message("Equipped items rescanned.")
	elseif Command == "equipped" then
		PawnShowEquippedScores()
	elseif Command == "allscales" then
		PawnCommon.ShowOnlyClassScales = false
		VgerCore.Message("Now showing all scales in tooltips.")
	elseif Command == "classscales" then
		PawnCommon.ShowOnlyClassScales = true
		VgerCore.Message("Now showing only class-relevant scales in tooltips.")
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
	VgerCore.Message("/pawn " .. VgerCore.Color.Green .. "scales" .. VgerCore.Color.Blue .. " - Show all scales")
	VgerCore.Message("/pawn " .. VgerCore.Color.Green .. "init" .. VgerCore.Color.Blue .. " - Reinitialize scale providers")
	VgerCore.Message("/pawn " .. VgerCore.Color.Green .. "scan" .. VgerCore.Color.Blue .. " - Rescan equipped items")
	VgerCore.Message("/pawn " .. VgerCore.Color.Green .. "equipped" .. VgerCore.Color.Blue .. " - Show equipped item scores")
	VgerCore.Message("/pawn " .. VgerCore.Color.Green .. "classscales" .. VgerCore.Color.Blue .. " - Show only your class scales (default)")
	VgerCore.Message("/pawn " .. VgerCore.Color.Green .. "allscales" .. VgerCore.Color.Blue .. " - Show all scales")
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
		
		-- CRITICAL: Prevent recursion - don't process if we're showing our own tooltip
		if this.PawnProcessing then return end
		this.PawnProcessing = true
		
		-- Get the first line of the tooltip (item name)
		local itemName = getglobal(this:GetName().."TextLeft1")
		if not itemName then 
			this.PawnProcessing = nil
			return 
		end
		
		local name = itemName:GetText()
		if not name or name == "" then 
			this.PawnProcessing = nil
			return 
		end
		
		-- Skip non-item tooltips (check for common non-item patterns)
		if string.find(name, "^Login:") or 
		   string.find(name, "^This Session:") or
		   string.find(name, "^Now:") or
		   this:NumLines() < 3 then
			this.PawnProcessing = nil
			return
		end
		
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
			-- Show all stats (Debug only anyway)
			for i = 1, table.getn(itemInfo.stats) do
				this:AddLine("  " .. itemInfo.stats[i], 0.8, 0.8, 0.8)
			end
			
			-- Show parsed stats
			if itemInfo.parsedStats then
				this:AddLine(" ", 1, 1, 1)
				this:AddLine("Parsed stats:", 0.5, 0.8, 1)
				for stat, value in pairs(itemInfo.parsedStats) do
					this:AddLine("  " .. stat .. ": " .. value, 0.5, 0.8, 1)
				end
				
				-- Calculate scores for all scales
				this:AddLine(" ", 1, 1, 1)
				
				-- Get item equip slot to compare with equipped
				local equipLoc = itemInfo.equipLoc
				if not equipLoc then
					-- Try to get from item link as fallback
					local itemLink = PawnGetItemLinkFromTooltip(this)
					if itemLink then
						local Item = PawnGetItemData(itemLink)
						if Item and Item.EquipLoc then
							equipLoc = Item.EquipLoc
						end
					end
				end
				
				if equipLoc then
					PawnDebugLog("Item equip location: " .. tostring(equipLoc))
				else
					PawnDebugLog("No equip location found")
				end
				
				-- Determine which slot(s) to compare with
				local compareSlots = nil
				if equipLoc then
					compareSlots = PawnGetItemEquipSlot(equipLoc)
					-- Handle items that can go in multiple slots
					if type(compareSlots) ~= "table" then
						compareSlots = {compareSlots}
					end
					if PawnCommon.Debug then
						PawnDebugLog("Compare slots: " .. table.concat(compareSlots, ", "))
					end
				else
					if PawnCommon.Debug then
						PawnDebugLog("No equip location found for comparison")
					end
				end
				
				this:AddLine("Pawn scores:", 1, 1, 0)
				
				local scoresCalculated = false
				
				-- Get player class for filtering
				local playerClass = PawnPlayerClassName or string.upper(string.gsub(UnitClass("player") or "", " ", ""))
				
				for scaleName, scale in pairs(PawnCommon.Scales or {}) do
					-- Filter scales by class if option is enabled (default true if not set)
					local showScale = true
					local showOnlyClass = PawnCommon.ShowOnlyClassScales
					if showOnlyClass == nil then showOnlyClass = true end
					
					if showOnlyClass and string.find(scaleName, "Classic:") then
						-- Check if this scale is for the player's class
						showScale = false
						if playerClass == "WARRIOR" and string.find(scaleName, "Warrior") then
							showScale = true
						elseif playerClass == "PALADIN" and string.find(scaleName, "Paladin") then
							showScale = true
						elseif playerClass == "HUNTER" and string.find(scaleName, "Hunter") then
							showScale = true
						elseif playerClass == "ROGUE" and string.find(scaleName, "Rogue") then
							showScale = true
						elseif playerClass == "PRIEST" and string.find(scaleName, "Priest") then
							showScale = true
						elseif playerClass == "SHAMAN" and string.find(scaleName, "Shaman") then
							showScale = true
						elseif playerClass == "MAGE" and string.find(scaleName, "Mage") then
							showScale = true
						elseif playerClass == "WARLOCK" and string.find(scaleName, "Warlock") then
							showScale = true
						elseif playerClass == "DRUID" and string.find(scaleName, "Druid") then
							showScale = true
						end
					end
					
					if showScale then
						local score = PawnCalculateItemScore(itemInfo.parsedStats, scaleName)
						if score and score > 0 then
							scoresCalculated = true
							
							-- Debug which scale is being shown
							if PawnCommon.Debug then
								PawnDebugLog("Showing scale " .. scaleName .. " with score " .. score)
							end
						
						-- Get the best equipped score for this scale
						local bestEquippedScore = 0
						if compareSlots then
							for _, slotId in pairs(compareSlots) do
								if PawnEquippedScores[slotId] and PawnEquippedScores[slotId][scaleName] then
									if PawnEquippedScores[slotId][scaleName] > bestEquippedScore then
										bestEquippedScore = PawnEquippedScores[slotId][scaleName]
									end
								end
							end
							if PawnCommon.Debug and bestEquippedScore == 0 then
								PawnDebugLog("No equipped score found for " .. scaleName .. " in slots: " .. table.concat(compareSlots, ", "))
								-- Debug: Show what scores we have for this scale
								for slotId, scores in pairs(PawnEquippedScores) do
									if scores[scaleName] then
										PawnDebugLog("  Found " .. scaleName .. " score " .. scores[scaleName] .. " in slot " .. slotId)
									end
								end
							end
						end
						
						-- Calculate upgrade percentage
						local upgradePercent = 0
						local upgradeText = ""
						local r, g, b = 0.8, 0.8, 0.8 -- Default gray
						
						if bestEquippedScore > 0 then
							upgradePercent = ((score - bestEquippedScore) / bestEquippedScore) * 100
							
							if upgradePercent > 0.5 then
								-- Upgrade
								upgradeText = string.format(" |cff00ff00↑ +%.1f%%|r", upgradePercent)
								if string.find(scaleName, "Classic:") then
									r, g, b = 0.2, 1, 0.2 -- Bright green for classic
								else
									r, g, b = 0.5, 1, 0.5 -- Light green
								end
							elseif upgradePercent < -0.5 then
								-- Downgrade
								upgradeText = string.format(" |cffff0000↓ %.1f%%|r", upgradePercent)
								if string.find(scaleName, "Classic:") then
									r, g, b = 1, 0.2, 0.2 -- Bright red for classic
								else
									r, g, b = 1, 0.5, 0.5 -- Light red
								end
							else
								-- Sidegrade (very close)
								upgradeText = " |cffffff00≈|r"
								if string.find(scaleName, "Classic:") then
									r, g, b = 1, 1, 0.5 -- Yellow for classic
								else
									r, g, b = 0.8, 0.8, 0.5 -- Dim yellow
								end
							end
						else
							-- No equipped item to compare
							if string.find(scaleName, "Classic:") then
								r, g, b = 0.5, 1, 0.5 -- Light green for classic
							end
						end
						
						-- Format: "ScaleName: 123.4 ↑ +15.2%"
						local scoreLine = scaleName .. ": " .. string.format("%.1f", score) .. upgradeText
						
						-- Debug: Show equipped score if exists
						if PawnCommon.Debug and bestEquippedScore > 0 then
							scoreLine = scoreLine .. " (vs " .. string.format("%.1f", bestEquippedScore) .. ")"
						end
						
						this:AddLine("  " .. scoreLine, r, g, b)
						end
					end
				end
				
				if not scoresCalculated then
					this:AddLine("  No scores calculated", 0.5, 0.5, 0.5)
				end
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
		this.PawnProcessing = nil
	end)
	
	-- Clear flag when tooltip hides
	GameTooltip:HookScript("OnHide", function()
		this.PawnInfoAdded = nil
		this.PawnProcessing = nil
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
			-- PawnDebugLog("Mouse focus: " .. name) -- Too spammy
			
			-- For container items
			if string.find(name, "ContainerFrame") then
				local _, _, container, slot = string.find(name, "ContainerFrame(%d+)Item(%d+)")
				if container and slot then
					container = tonumber(container) - 1
					slot = tonumber(slot)
					
					-- Try multiple methods to get the link
					-- Method 1: Direct GetContainerItemLink
					local link = GetContainerItemLink(container, slot)
					-- PawnDebugLog("GetContainerItemLink returned: " .. tostring(link))
					
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
						-- PawnDebugLog("GetInventoryItemLink returned: " .. tostring(link))
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
		stats = {},
		parsedStats = {},  -- New: parsed stats with values
		equipLoc = nil,  -- Equipment location
	}
	
	-- Scan all tooltip lines
	local numLines = tooltip:NumLines()
	if PawnCommon.Debug then
		PawnDebugLog("Scanning tooltip with " .. numLines .. " lines")
	end
	
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
				if PawnCommon.Debug then
					PawnDebugLog("Line " .. i .. " (L): " .. text .. " [Color: " .. string.format("%.2f,%.2f,%.2f", r, g, b) .. "]")
				end
				
				-- Temporary: collect all lines
				table.insert(allLines, {text = text, color = string.format("%.2f,%.2f,%.2f", r, g, b), side = "left"})
				
				-- Check for equipment slot indicators
				if text == "Two-Hand" then
					info.equipLoc = "INVTYPE_2HWEAPON"
				elseif text == "Main Hand" then
					info.equipLoc = "INVTYPE_WEAPONMAINHAND"
				elseif text == "One-Hand" then
					info.equipLoc = "INVTYPE_WEAPON"
				elseif text == "Off Hand" then
					info.equipLoc = "INVTYPE_WEAPONOFFHAND"
				elseif text == "Head" then
					info.equipLoc = "INVTYPE_HEAD"
				elseif text == "Chest" then
					info.equipLoc = "INVTYPE_CHEST"
				elseif text == "Legs" then
					info.equipLoc = "INVTYPE_LEGS"
				elseif text == "Feet" then
					info.equipLoc = "INVTYPE_FEET"
				elseif text == "Hands" then
					info.equipLoc = "INVTYPE_HAND"
				elseif text == "Waist" then
					info.equipLoc = "INVTYPE_WAIST"
				elseif text == "Wrist" then
					info.equipLoc = "INVTYPE_WRIST"
				elseif text == "Shoulder" then
					info.equipLoc = "INVTYPE_SHOULDER"
				elseif text == "Back" then
					info.equipLoc = "INVTYPE_CLOAK"
				elseif text == "Neck" then
					info.equipLoc = "INVTYPE_NECK"
				elseif text == "Finger" then
					info.equipLoc = "INVTYPE_FINGER"
				elseif text == "Trinket" then
					info.equipLoc = "INVTYPE_TRINKET"
				end
				
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
						
						-- Try to determine equipment slot from type
						if string.find(text, "Two%-Hand") then
							info.equipLoc = "INVTYPE_2HWEAPON"
						elseif string.find(text, "One%-Hand") or string.find(text, "Main Hand") then
							info.equipLoc = "INVTYPE_WEAPONMAINHAND"
						elseif string.find(text, "Off Hand") and not string.find(text, "Shield") then
							info.equipLoc = "INVTYPE_WEAPONOFFHAND"
						elseif string.find(text, "Shield") then
							info.equipLoc = "INVTYPE_SHIELD"
						elseif string.find(text, "Bow") or string.find(text, "Gun") or string.find(text, "Crossbow") then
							info.equipLoc = "INVTYPE_RANGED"
						elseif string.find(text, "Thrown") then
							info.equipLoc = "INVTYPE_THROWN"
						end
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
	
	-- Parse the extracted stats
	info.parsedStats = PawnParseStats(info.stats)
	
	return info
end

-- Parse stat strings into Pawn stat names and values
function PawnParseStats(statLines)
	local parsedStats = {}
	
	-- Stat patterns for Vanilla/Turtle WoW
	local statPatterns = {
		-- Primary stats
		{pattern = "%+(%d+) Strength", stat = "Strength"},
		{pattern = "%+(%d+) Agility", stat = "Agility"},
		{pattern = "%+(%d+) Stamina", stat = "Stamina"},
		{pattern = "%+(%d+) Intellect", stat = "Intellect"},
		{pattern = "%+(%d+) Spirit", stat = "Spirit"},
		
		-- Armor and damage
		{pattern = "(%d+) Armor", stat = "Armor"},
		{pattern = "(%d+) %- (%d+) Damage", stat = "DPS", special = "damage"},
		{pattern = "%(([%d%.]+) damage per second%)", stat = "DPS", isDPS = true},
		{pattern = "(%d+) Block", stat = "Block"},
		
		-- Resistances
		{pattern = "%+(%d+) Shadow Resistance", stat = "ShadowResistance"},
		{pattern = "%+(%d+) Fire Resistance", stat = "FireResistance"},
		{pattern = "%+(%d+) Nature Resistance", stat = "NatureResistance"},
		{pattern = "%+(%d+) Frost Resistance", stat = "FrostResistance"},
		{pattern = "%+(%d+) Arcane Resistance", stat = "ArcaneResistance"},
		
		-- Secondary stats
		{pattern = "%+(%d+) Attack Power", stat = "AttackPower"},
		{pattern = "%+(%d+) Spell Power", stat = "SpellPower"},
		{pattern = "%+(%d+) Healing", stat = "SpellHealing"},
		{pattern = "%+(%d+) Spell Damage", stat = "SpellDamage"},
		{pattern = "%+(%d+) Healing Spells", stat = "SpellHealing"},
		{pattern = "%+(%d+) Damage and Healing Spells", stat = "SpellPower"},
		
		-- Hit and Crit (Vanilla uses % not rating)
		{pattern = "Equip: Improves your chance to hit by (%d+)%%%.", stat = "HitPercent"},
		{pattern = "Equip: Improves your chance to get a critical strike by (%d+)%%%.", stat = "CritPercent"},
		{pattern = "Equip: Improves your chance to hit with spells by (%d+)%%%.", stat = "SpellHitPercent"},
		{pattern = "Equip: Improves your chance to get a critical strike with spells by (%d+)%%%.", stat = "SpellCritPercent"},
		{pattern = "%+(%d+)%% Critical Strike", stat = "CritPercent"},
		{pattern = "%+(%d+)%% Hit", stat = "HitPercent"},
		
		-- Defense and Avoidance
		{pattern = "%+(%d+) Defense", stat = "Defense"},
		{pattern = "%+(%d+) Defense Rating", stat = "Defense"},
		{pattern = "%+(%d+) Dodge", stat = "DodgePercent"},
		{pattern = "%+(%d+) Parry", stat = "ParryPercent"},
		{pattern = "%+(%d+)%% Dodge", stat = "DodgePercent"},
		{pattern = "%+(%d+)%% Parry", stat = "ParryPercent"},
		
		-- Mana regen
		{pattern = "Equip: Restores (%d+) mana per 5 sec%.", stat = "Mp5"},
		{pattern = "%+(%d+) Mana every 5 seconds", stat = "Mp5"},
		{pattern = "Equip: Restores (%d+) health per 5 sec%.", stat = "Hp5"},
		
		-- Weapon skill
		{pattern = "%+(%d+) Axe Skill", stat = "AxeSkill"},
		{pattern = "%+(%d+) Sword Skill", stat = "SwordSkill"},
		{pattern = "%+(%d+) Mace Skill", stat = "MaceSkill"},
		{pattern = "%+(%d+) Dagger Skill", stat = "DaggerSkill"},
		{pattern = "%+(%d+) Bow Skill", stat = "BowSkill"},
		{pattern = "%+(%d+) Gun Skill", stat = "GunSkill"},
		{pattern = "%+(%d+) Staff Skill", stat = "StaffSkill"},
		
		-- Weapon stats
		{pattern = "Speed ([%d%.]+)", stat = "Speed"},
		
		-- Special procs (simplified - just detect presence)
		{pattern = "Equip: Chance on hit", stat = "HasProc", special = "proc"},
		{pattern = "Use:", stat = "HasUse", special = "use"},
	}
	
	-- Process each stat line
	for _, statLine in pairs(statLines) do
		local matched = false
		
		-- First check if line contains multiple stats (e.g. "+2 Strength +2 Stamina")
		if string.find(statLine, "%+%d+.+%+%d+") then
			-- Split and process each part
			if PawnCommon.Debug then
				PawnDebugLog("Multi-stat line detected: " .. statLine)
			end
			-- Process the line multiple times to catch all stats
			for _, pattern in pairs(statPatterns) do
				-- Use gsub to find all matches
				local count = 0
				string.gsub(statLine, pattern.pattern, function(value)
					local numValue = tonumber(value)
					if numValue then
						if parsedStats[pattern.stat] then
							parsedStats[pattern.stat] = parsedStats[pattern.stat] + numValue
						else
							parsedStats[pattern.stat] = numValue
						end
						count = count + 1
						if PawnCommon.Debug then
							PawnDebugLog("Parsed stat (multi): " .. pattern.stat .. " = " .. numValue)
						end
					end
				end)
				if count > 0 then matched = true end
			end
		end
		
		-- If not matched as multi-stat, try single stat patterns
		if not matched then
			for _, pattern in pairs(statPatterns) do
					if pattern.special == "damage" then
					-- Handle damage range
					local minDmg, maxDmg = string.find(statLine, pattern.pattern)
					if minDmg then
						local _, _, min, max = string.find(statLine, pattern.pattern)
						if min and max then
							parsedStats["MinDamage"] = tonumber(min)
							parsedStats["MaxDamage"] = tonumber(max)
							matched = true
							if PawnCommon.Debug then
								PawnDebugLog("Parsed damage: " .. min .. "-" .. max)
							end
						end
					end
				elseif pattern.special == "proc" or pattern.special == "use" then
					-- For procs and use effects, just check if they exist
					if string.find(statLine, pattern.pattern) then
						parsedStats[pattern.stat] = 1
						matched = true
						if PawnCommon.Debug then
							PawnDebugLog("Found special: " .. pattern.stat)
						end
					end
				else
					-- Handle regular stats
					local _, _, value = string.find(statLine, pattern.pattern)
					if value then
						local numValue = tonumber(value)
						if numValue then
							if parsedStats[pattern.stat] then
								parsedStats[pattern.stat] = parsedStats[pattern.stat] + numValue
							else
								parsedStats[pattern.stat] = numValue
							end
							matched = true
							if PawnCommon.Debug then
								PawnDebugLog("Parsed stat: " .. pattern.stat .. " = " .. numValue)
							end
						end
					end
				end
			end
		end
		
		if not matched then
			if PawnCommon.Debug then
				PawnDebugLog("Unmatched stat line: " .. statLine)
			end
		end
	end
	
	return parsedStats
end

-- Get the slot ID for an item based on its equip location
function PawnGetItemEquipSlot(equipLoc)
	if not equipLoc then return nil end
	
	local slotMap = {
		["INVTYPE_HEAD"] = 1,
		["INVTYPE_NECK"] = 2,
		["INVTYPE_SHOULDER"] = 3,
		["INVTYPE_BODY"] = 4, -- Shirt
		["INVTYPE_CHEST"] = 5,
		["INVTYPE_ROBE"] = 5,
		["INVTYPE_WAIST"] = 6,
		["INVTYPE_LEGS"] = 7,
		["INVTYPE_FEET"] = 8,
		["INVTYPE_WRIST"] = 9,
		["INVTYPE_HAND"] = 10,
		["INVTYPE_FINGER"] = {11, 12}, -- Two ring slots
		["INVTYPE_TRINKET"] = {13, 14}, -- Two trinket slots
		["INVTYPE_CLOAK"] = 15,
		["INVTYPE_WEAPON"] = {16, 17}, -- Main hand, off hand
		["INVTYPE_2HWEAPON"] = {16, 17}, -- Check both slots for 2H weapons
		["INVTYPE_WEAPONMAINHAND"] = 16,
		["INVTYPE_WEAPONOFFHAND"] = 17,
		["INVTYPE_HOLDABLE"] = 17,
		["INVTYPE_SHIELD"] = 17,
		["INVTYPE_RANGED"] = 18,
		["INVTYPE_THROWN"] = 18,
		["INVTYPE_RANGEDRIGHT"] = 18,
		["INVTYPE_RELIC"] = 18,
		["INVTYPE_TABARD"] = 19,
	}
	
	return slotMap[equipLoc]
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
	-- Debug log
	PawnDebugLog("Initializing scale providers...")
	
	-- Ensure PawnCommon exists
	if not PawnCommon then 
		PawnCommon = {}
		PawnDebugLog("Created PawnCommon")
	end
	
	-- Initialize built-in scales
	if not PawnCommon.Scales then 
		PawnCommon.Scales = {} 
		PawnDebugLog("Created PawnCommon.Scales")
	end
	
	-- Initialize classic scale providers
	PawnInitializeClassicScales()
	
	-- Add default scale for testing
	if not PawnCommon.Scales["Test"] then
		PawnCommon.Scales["Test"] = {
			-- Primary stats
			["Strength"] = 1,
			["Agility"] = 1,
			["Stamina"] = 1,
			["Intellect"] = 1,
			["Spirit"] = 1,
			-- Armor and defense
			["Armor"] = 0.1,
			["Block"] = 1,
			["Defense"] = 1,
			-- Damage
			["DPS"] = 2,
			["MinDamage"] = 0.5,
			["MaxDamage"] = 0.5,
		}
		PawnDebugLog("Created Test scale")
	else
		PawnDebugLog("Test scale already exists")
	end
	
	-- Debug: show all scales
	PawnDebugLog("Available scales:")
	for scaleName, _ in pairs(PawnCommon.Scales) do
		PawnDebugLog("  - " .. scaleName)
	end
end

function PawnGetAllScales()
	return PawnCommon.Scales or {}
end

function PawnGetScaleValues(ScaleName)
	if not ScaleName or not PawnCommon.Scales then return end
	return PawnCommon.Scales[ScaleName]
end

-- Calculate item score based on parsed stats and scale
function PawnCalculateItemScore(parsedStats, scaleName)
	if not parsedStats or not scaleName then return 0 end
	
	-- Debug: Check if PawnCommon exists
	if not PawnCommon then
		PawnDebugLog("PawnCommon does not exist in PawnCalculateItemScore")
		return 0
	end
	if not PawnCommon.Scales then
		PawnDebugLog("PawnCommon.Scales does not exist")
		return 0
	end
	
	local scale = PawnGetScaleValues(scaleName)
	if not scale then 
		PawnDebugLog("Scale not found: " .. scaleName)
		PawnDebugLog("Available scales: ")
		for name, _ in pairs(PawnCommon.Scales or {}) do
			PawnDebugLog("  - " .. name)
		end
		return 0 
	end
	
	local score = 0
	
	-- Calculate score by multiplying stat values with scale weights
	for stat, value in pairs(parsedStats) do
		local weight = scale[stat]
		if weight and weight > 0 then
			local contribution = value * weight
			score = score + contribution
			if PawnCommon.Debug then
				PawnDebugLog("Score calc: " .. stat .. " (" .. value .. ") * " .. weight .. " = " .. contribution)
			end
		end
	end
	
	if PawnCommon.Debug then
		PawnDebugLog("Total score for " .. scaleName .. ": " .. score)
	end
	return score
end

-- Initialize Classic scales for Vanilla
function PawnInitializeClassicScales()
	PawnDebugLog("Initializing Classic scales...")
	
	-- Ensure PawnCommon.Scales exists
	if not PawnCommon then
		PawnCommon = {}
	end
	if not PawnCommon.Scales then
		PawnCommon.Scales = {}
	end
	
	-- Classic scales for different classes/specs
	-- These are simplified versions optimized for Vanilla
	
	-- Warrior Tank
	PawnCommon.Scales["Classic:WarriorTank"] = {
		Strength = 0.5,
		Agility = 0.7,
		Stamina = 1,
		Armor = 0.1,
		Defense = 2,
		DodgePercent = 10,
		ParryPercent = 10,
		Block = 1,
		BlockValue = 0.5,
	}
	
	-- Warrior DPS
	PawnCommon.Scales["Classic:WarriorDPS"] = {
		Strength = 2,
		Agility = 1,
		Stamina = 0.1,
		AttackPower = 1,
		CritPercent = 20,
		HitPercent = 30,
		ArmorPenetration = 0.3,
		DPS = 3,
	}
	
	-- Rogue
	PawnCommon.Scales["Classic:Rogue"] = {
		Strength = 1,
		Agility = 2,
		Stamina = 0.1,
		AttackPower = 1,
		CritPercent = 20,
		HitPercent = 30,
		DaggerSkill = 2,
		SwordSkill = 2,
		DPS = 3,
	}
	
	-- Hunter
	PawnCommon.Scales["Classic:Hunter"] = {
		Agility = 2,
		Stamina = 0.1,
		Intellect = 0.5,
		AttackPower = 1,
		RangedAttackPower = 1,
		CritPercent = 20,
		HitPercent = 30,
		Mp5 = 2,
		DPS = 3,
	}
	
	-- Mage
	PawnCommon.Scales["Classic:Mage"] = {
		Intellect = 1,
		Stamina = 0.1,
		Spirit = 0.3,
		SpellPower = 1.2,
		SpellDamage = 1.2,
		SpellCritPercent = 10,
		SpellHitPercent = 16,
		Mp5 = 2,
	}
	
	-- Warlock
	PawnCommon.Scales["Classic:Warlock"] = {
		Intellect = 0.7,
		Stamina = 0.3,
		Spirit = 0.1,
		SpellPower = 1.2,
		SpellDamage = 1.2,
		ShadowSpellDamage = 1.3,
		SpellCritPercent = 10,
		SpellHitPercent = 16,
		Mp5 = 1,
	}
	
	-- Priest Heal
	PawnCommon.Scales["Classic:PriestHeal"] = {
		Intellect = 1,
		Stamina = 0.1,
		Spirit = 0.8,
		SpellHealing = 1.2,
		SpellPower = 0.6,
		Mp5 = 3,
		SpellCritPercent = 8,
	}
	
	-- Priest Shadow
	PawnCommon.Scales["Classic:PriestShadow"] = {
		Intellect = 0.8,
		Stamina = 0.2,
		Spirit = 0.3,
		SpellPower = 1.2,
		SpellDamage = 1.2,
		ShadowSpellDamage = 1.3,
		SpellCritPercent = 10,
		SpellHitPercent = 16,
		Mp5 = 2,
	}
	
	-- Paladin Holy
	PawnCommon.Scales["Classic:PaladinHoly"] = {
		Intellect = 1,
		Stamina = 0.1,
		SpellHealing = 1.2,
		SpellPower = 0.6,
		SpellCritPercent = 8,
		Mp5 = 3,
	}
	
	-- Paladin Ret
	PawnCommon.Scales["Classic:PaladinRet"] = {
		Strength = 2,
		Agility = 0.7,
		Stamina = 0.1,
		Intellect = 0.3,
		AttackPower = 1,
		CritPercent = 15,
		HitPercent = 20,
		SpellPower = 0.3,
		DPS = 3,
		MinDamage = 0,  -- Don't double-count with DPS
		MaxDamage = 0,  -- Don't double-count with DPS
	}
	
	-- Paladin Prot
	PawnCommon.Scales["Classic:PaladinProt"] = {
		Strength = 0.5,
		Stamina = 1,
		Intellect = 0.5,
		Armor = 0.1,
		Defense = 2,
		DodgePercent = 8,
		ParryPercent = 8,
		Block = 1,
		BlockValue = 0.5,
		SpellPower = 0.3,
	}
	
	-- Druid Balance
	PawnCommon.Scales["Classic:DruidBalance"] = {
		Intellect = 1,
		Stamina = 0.1,
		Spirit = 0.5,
		SpellPower = 1.2,
		SpellDamage = 1.2,
		NatureSpellDamage = 1.3,
		ArcaneSpellDamage = 1.1,
		SpellCritPercent = 10,
		SpellHitPercent = 16,
		Mp5 = 2,
	}
	
	-- Druid Feral DPS
	PawnCommon.Scales["Classic:DruidFeralDPS"] = {
		Strength = 2,
		Agility = 1.5,
		Stamina = 0.1,
		AttackPower = 1,
		FeralAttackPower = 1,
		CritPercent = 20,
		HitPercent = 25,
		DPS = 3,
	}
	
	-- Druid Feral Tank
	PawnCommon.Scales["Classic:DruidFeralTank"] = {
		Strength = 0.5,
		Agility = 1,
		Stamina = 1.2,
		Armor = 0.2,
		Defense = 1.5,
		DodgePercent = 15,
	}
	
	-- Druid Resto
	PawnCommon.Scales["Classic:DruidResto"] = {
		Intellect = 1,
		Stamina = 0.1,
		Spirit = 0.9,
		SpellHealing = 1.2,
		SpellPower = 0.6,
		Mp5 = 3.5,
		SpellCritPercent = 8,
	}
	
	-- Shaman Elemental
	PawnCommon.Scales["Classic:ShamanElemental"] = {
		Intellect = 1,
		Stamina = 0.1,
		SpellPower = 1.2,
		SpellDamage = 1.2,
		NatureSpellDamage = 1.3,
		SpellCritPercent = 10,
		SpellHitPercent = 16,
		Mp5 = 2,
	}
	
	-- Shaman Enhancement
	PawnCommon.Scales["Classic:ShamanEnhancement"] = {
		Strength = 1.8,
		Agility = 1.2,
		Stamina = 0.1,
		Intellect = 0.3,
		AttackPower = 1,
		CritPercent = 18,
		HitPercent = 25,
		SpellPower = 0.2,
		Mp5 = 1,
		DPS = 3,
	}
	
	-- Shaman Resto
	PawnCommon.Scales["Classic:ShamanResto"] = {
		Intellect = 1,
		Stamina = 0.1,
		Spirit = 0.5,
		SpellHealing = 1.2,
		SpellPower = 0.6,
		Mp5 = 3.5,
		SpellCritPercent = 8,
	}
	
	PawnDebugLog("Classic scales initialized")
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
	-- Scan equipped items
	PawnScanEquippedItems()
end

-- Scan all equipped items and calculate their scores
function PawnScanEquippedItems()
	PawnDebugLog("Scanning equipped items...")
	
	-- Ensure PawnCommon exists
	if not PawnCommon or not PawnCommon.Scales then
		PawnDebugLog("Cannot scan equipped items - scales not initialized")
		return
	end
	
	-- Clear old data
	PawnEquippedItems = {}
	PawnEquippedScores = {}
	
	-- Slot IDs for equipment
	local slots = {
		1, -- Head
		2, -- Neck
		3, -- Shoulder
		5, -- Chest
		6, -- Waist
		7, -- Legs
		8, -- Feet
		9, -- Wrist
		10, -- Hands
		11, -- Finger 1
		12, -- Finger 2
		13, -- Trinket 1
		14, -- Trinket 2
		15, -- Back
		16, -- Main Hand
		17, -- Off Hand
		18, -- Ranged
	}
	
	for _, slotId in pairs(slots) do
		local itemLink = GetInventoryItemLink("player", slotId)
		if itemLink then
			-- Store the item link
			PawnEquippedItems[slotId] = itemLink
			
			-- In Vanilla, GetItemInfo often fails, so we scan tooltip directly
			-- Parse stats from equipped item
			local tooltip = PawnPrivateTooltip
			if not tooltip then
				tooltip = CreateFrame("GameTooltip", "PawnPrivateTooltip", UIParent, "GameTooltipTemplate")
				PawnPrivateTooltip = tooltip
			end
			
			tooltip:SetOwner(UIParent, "ANCHOR_NONE")
			tooltip:ClearLines()
			tooltip:SetInventoryItem("player", slotId)
			
			-- Force the tooltip to load
			local firstLine = getglobal(tooltip:GetName().."TextLeft1")
			if firstLine and firstLine:GetText() then
				if PawnCommon.Debug then
					PawnDebugLog("Scanning equipped slot " .. slotId .. ": " .. firstLine:GetText())
				end
			else
				if PawnCommon.Debug then
					PawnDebugLog("Slot " .. slotId .. " tooltip is empty")
				end
			end
			
			-- WICHTIG: Private tooltip braucht keine Debug-Info Zeilen
			local oldDebug = this.PawnInfoAdded
			this.PawnInfoAdded = true -- Prevent debug info being added
			
			local itemInfo = PawnExtractTooltipInfo(tooltip)
			
			this.PawnInfoAdded = oldDebug
			
			if itemInfo and itemInfo.parsedStats then
				if PawnCommon.Debug then
					PawnDebugLog("Slot " .. slotId .. " has parsed stats:")
					for stat, value in pairs(itemInfo.parsedStats) do
						PawnDebugLog("  " .. stat .. " = " .. value)
					end
				end
				
				-- Calculate scores for all scales
				PawnEquippedScores[slotId] = {}
				local scoresFound = 0
				for scaleName, _ in pairs(PawnCommon.Scales or {}) do
					local score = PawnCalculateItemScore(itemInfo.parsedStats, scaleName)
					if score and score > 0 then
						PawnEquippedScores[slotId][scaleName] = score
						scoresFound = scoresFound + 1
					end
				end
				if PawnCommon.Debug then
					PawnDebugLog("Slot " .. slotId .. " scores calculated: " .. scoresFound)
				end
			else
				if PawnCommon.Debug then
					PawnDebugLog("No stats found for slot " .. slotId)
				end
			end
			
			tooltip:Hide()
		end
	end
	
	PawnDebugLog("Equipped items scan complete")
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

function PawnShowScales()
	VgerCore.Message(" ")
	VgerCore.Message(VgerCore.Color.Blue .. "Current Pawn scales:")
	
	-- Ensure PawnCommon exists
	if not PawnCommon then
		VgerCore.Message("|cffff0000PawnCommon does not exist!|r")
		return
	end
	
	if not PawnCommon.Scales then
		VgerCore.Message("|cffff0000PawnCommon.Scales does not exist!|r")
		return
	end
	
	local count = 0
	for scaleName, scale in pairs(PawnCommon.Scales) do
		count = count + 1
		VgerCore.Message(VgerCore.Color.Green .. scaleName .. ":")
		-- Show first few stats
		local statCount = 0
		for stat, value in pairs(scale) do
			statCount = statCount + 1
			if statCount <= 5 then
				VgerCore.Message("  " .. stat .. " = " .. value)
			end
		end
		if statCount > 5 then
			VgerCore.Message("  ... and " .. (statCount - 5) .. " more stats")
		end
	end
	
	if count == 0 then
		VgerCore.Message("|cffff0000No scales found!|r")
	else
		VgerCore.Message("Total scales: " .. count)
	end
	VgerCore.Message(" ")
end

function PawnShowEquippedScores()
	VgerCore.Message(" ")
	VgerCore.Message(VgerCore.Color.Blue .. "Equipped item scores:")
	
	local count = 0
	for slotId, scores in pairs(PawnEquippedScores) do
		local itemLink = PawnEquippedItems[slotId]
		if itemLink then
			count = count + 1
			local _, itemName = string.find(itemLink, "%[(.+)%]")
			if itemName then
				VgerCore.Message(VgerCore.Color.Green .. "Slot " .. slotId .. ": " .. itemName)
			else
				VgerCore.Message(VgerCore.Color.Green .. "Slot " .. slotId .. ": " .. tostring(itemLink))
			end
			
			local scaleCount = 0
			for scaleName, score in pairs(scores) do
				scaleCount = scaleCount + 1
				if scaleCount <= 3 then -- Show first 3 scales
					VgerCore.Message("  " .. scaleName .. ": " .. string.format("%.1f", score))
				end
			end
			if scaleCount > 3 then
				VgerCore.Message("  ... and " .. (scaleCount - 3) .. " more scales")
			end
		end
	end
	
	if count == 0 then
		VgerCore.Message("|cffff0000No equipped items found!|r")
		VgerCore.Message("Try /pawn scan first")
	else
		VgerCore.Message("Total equipped items: " .. count)
	end
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
		-- Also initialize scales directly for reloads
		PawnInitializeScaleProviders()
	end
end

-- Removed - will cause error