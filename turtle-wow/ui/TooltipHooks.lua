-- turtle-wow/ui/TooltipHooks.lua
-- Phase 2.3: Universal Tooltip Hooking System for Vanilla WoW

PawnTooltipHooks = {
    hooked = {},
    originalMethods = {},
    initialized = false,
    
    -- Initialize the tooltip hooking system
    Initialize = function(self)
        if PawnDebug then
            PawnDebug:Log(3, "TOOLTIP", "Initializing tooltip hook system")
        end
        
        -- Hook all known tooltips
        self:HookTooltip("GameTooltip")
        self:HookTooltip("ItemRefTooltip")
        self:HookTooltip("ShoppingTooltip1")
        self:HookTooltip("ShoppingTooltip2")
        
        -- Also hook any custom tooltips from other addons
        self:HookAddonTooltips()
    end,
    
    -- Hook a specific tooltip
    HookTooltip = function(self, tooltipName)
        local tooltip = getglobal(tooltipName)
        if not tooltip or self.hooked[tooltipName] then 
            return 
        end
        
        if PawnDebug then
            PawnDebug:Log(4, "TOOLTIP", "Hooking tooltip: " .. tooltipName)
        end
        
        -- Hook all relevant methods
        local methods = {
            "SetBagItem",
            "SetInventoryItem", 
            "SetLootItem",
            "SetQuestItem",
            "SetQuestLogItem",
            "SetTradeSkillItem",
            "SetMerchantItem",
            "SetAuctionItem",
            "SetHyperlink",
            "SetCraftItem",
            "SetTradeTargetItem",
            "SetInboxItem",
            "SetSendMailItem"
        }
        
        for _, method in ipairs(methods) do
            if tooltip[method] then
                self:HookMethod(tooltip, method, tooltipName)
            end
        end
        
        self.hooked[tooltipName] = true
    end,
    
    -- Hook a specific method on a tooltip
    HookMethod = function(self, tooltip, method, tooltipName)
        -- Store original method if not already stored
        local key = tooltipName .. "_" .. method
        if not self.originalMethods[key] then
            self.originalMethods[key] = tooltip[method]
        end
        
        -- Create the hook
        tooltip[method] = function(...)
            -- Call original method
            self.originalMethods[key](...)
            
            -- Then call our handler
            self:OnTooltipUpdate(tooltip, method, tooltipName, ...)
        end
    end,
    
    -- Called when a tooltip is updated
    OnTooltipUpdate = function(self, tooltip, method, tooltipName, ...)
        -- Get item link from the tooltip
        local itemLink = self:GetItemLinkFromTooltip(tooltip, method, ...)
        
        if not itemLink then
            return
        end
        
        if PawnDebug then
            PawnDebug:Log(5, "TOOLTIP", format("Tooltip update: %s.%s with item %s", 
                tooltipName, method, itemLink))
        end
        
        -- Add Pawn information to the tooltip
        self:AddPawnInfo(tooltip, itemLink)
    end,
    
    -- Extract item link from tooltip based on method and arguments
    GetItemLinkFromTooltip = function(self, tooltip, method, ...)
        local arg1, arg2, arg3 = ...
        
        if method == "SetHyperlink" then
            return arg1
        elseif method == "SetBagItem" then
            local bag, slot = arg1, arg2
            return GetContainerItemLink(bag, slot)
        elseif method == "SetInventoryItem" then
            local unit, slot = arg1, arg2
            return GetInventoryItemLink(unit, slot)
        elseif method == "SetLootItem" then
            local slot = arg1
            return GetLootSlotLink(slot)
        elseif method == "SetMerchantItem" then
            local index = arg1
            return GetMerchantItemLink(index)
        elseif method == "SetAuctionItem" then
            local type, index = arg1, arg2
            -- In Vanilla: "list", "bidder", or "owner"
            return GetAuctionItemLink(type, index)
        elseif method == "SetQuestItem" then
            local type, index = arg1, arg2
            if type == "choice" then
                return GetQuestItemLink("choice", index)
            else
                return GetQuestLogItemLink(type, index)
            end
        elseif method == "SetQuestLogItem" then
            local type, index = arg1, arg2
            return GetQuestLogItemLink(type, index)
        elseif method == "SetTradeSkillItem" then
            local skill, id = arg1, arg2
            return GetTradeSkillItemLink(skill)
        elseif method == "SetCraftItem" then
            local skill, id = arg1, arg2  
            return GetCraftItemLink(skill)
        elseif method == "SetTradeTargetItem" then
            local slot = arg1
            return GetTradeTargetItemLink(slot)
        elseif method == "SetInboxItem" then
            local index = arg1
            return GetInboxItemLink(index)
        elseif method == "SetSendMailItem" then
            local index = arg1
            return GetSendMailItemLink(index)
        end
        
        return nil
    end,
    
    -- Add Pawn information to tooltip
    AddPawnInfo = function(self, tooltip, itemLink)
        -- Early exit if Pawn isn't ready or tooltips are disabled
        if not PawnOptions then
            -- Create default options if not exists
            PawnOptions = { ShowTooltipValues = true }
        end
        
        if not PawnOptions.ShowTooltipValues then
            return
        end
        
        -- Get item data (check if function exists)
        if not PawnGetItemData then
            if PawnDebug then
                PawnDebug:Log(4, "TOOLTIP", "PawnGetItemData not available yet")
            end
            return
        end
        
        local item = PawnGetItemData(itemLink)
        if not item then
            return
        end
        
        -- Check if we should show values for this item
        if not self:ShouldShowValues(item) then
            return
        end
        
        -- Add blank line for spacing
        tooltip:AddLine(" ")
        
        -- Add Pawn header
        tooltip:AddLine("|cffffd200Pawn|r")
        
        -- Add values for each active scale
        local hasValues = false
        
        -- Check if PawnCommon exists
        if not PawnCommon or not PawnCommon.Scales then
            tooltip:AddLine("  |cff808080Pawn not initialized|r")
            tooltip:Show()
            return
        end
        
        for scaleName, scale in pairs(PawnCommon.Scales) do
            if scale.Enabled and item.Values and item.Values[scaleName] then
                local value = item.Values[scaleName]
                local color = scale.Color or {r = 1, g = 1, b = 1}
                
                -- Format the value line
                local valueText = format("%.1f", value)
                tooltip:AddDoubleLine(
                    "  " .. scaleName .. ":",
                    valueText,
                    color.r, color.g, color.b,
                    1, 1, 1
                )
                hasValues = true
            end
        end
        
        if not hasValues then
            tooltip:AddLine("  |cff808080No active scales|r")
        end
        
        -- Show the tooltip
        tooltip:Show()
    end,
    
    -- Check if we should show values for this item
    ShouldShowValues = function(self, item)
        -- Don't show values for items without stats
        if not item.Stats then
            return false
        end
        
        -- Don't show values for consumables, quest items, etc.
        if item.ClassID == 0 then -- Consumable
            return false
        end
        
        -- Show values for weapons, armor, and jewelry
        if item.ClassID == 2 or item.ClassID == 4 then
            return true
        end
        
        return false
    end,
    
    -- Hook tooltips from other addons
    HookAddonTooltips = function(self)
        -- AtlasLoot
        if AtlasLootTooltip then
            self:HookTooltip("AtlasLootTooltip")
        end
        
        -- Auctioneer
        if EnhTooltip then
            -- Auctioneer uses GameTooltip, already hooked
        end
        
        -- More addon tooltips can be added here
    end,
    
    -- Clean up hooks (for reloading)
    Cleanup = function(self)
        for tooltipName, _ in pairs(self.hooked) do
            local tooltip = getglobal(tooltipName)
            if tooltip then
                for key, original in pairs(self.originalMethods) do
                    if string.find(key, tooltipName .. "_") then
                        local method = string.sub(key, string.len(tooltipName) + 2)
                        tooltip[method] = original
                    end
                end
            end
        end
        
        self.hooked = {}
        self.originalMethods = {}
    end
}

-- Performance monitoring for tooltip updates
PawnTooltipPerformance = {
    enabled = false,
    updates = {},
    
    StartTimer = function(self, operation)
        if not self.enabled then return end
        
        self.updates[operation] = {
            start = debugprofilestop()
        }
    end,
    
    EndTimer = function(self, operation)
        if not self.enabled then return end
        
        local update = self.updates[operation]
        if update then
            update.duration = debugprofilestop() - update.start
            
            -- Log if update took too long
            if update.duration > 5 then -- 5ms threshold
                if PawnDebug then
                    PawnDebug:Log(2, "PERFORMANCE", 
                        format("Tooltip update '%s' took %.2fms", operation, update.duration))
                end
            end
        end
    end,
    
    GetStats = function(self)
        local total = 0
        local count = 0
        local max = 0
        
        for op, data in pairs(self.updates) do
            if data.duration then
                total = total + data.duration
                count = count + 1
                if data.duration > max then
                    max = data.duration
                end
            end
        end
        
        local avg = 0
        if count > 0 then
            avg = total / count
        end
        
        return {
            total = total,
            count = count,
            average = avg,
            maximum = max
        }
    end,
    
    Reset = function(self)
        self.updates = {}
    end
}

-- Initialize on load
local tooltipFrame = CreateFrame("Frame", "PawnTooltipHookFrame")
tooltipFrame:RegisterEvent("PLAYER_LOGIN")
tooltipFrame:RegisterEvent("VARIABLES_LOADED")
tooltipFrame:RegisterEvent("ADDON_LOADED")

local function TryInitialize()
    -- Only initialize once
    if PawnTooltipHooks.initialized then
        return
    end
    
    -- Check if we're logged in
    local isReady = false
    if IsLoggedIn then
        isReady = IsLoggedIn()
    else
        -- Fallback for older clients
        isReady = (UnitName("player") ~= nil and UnitName("player") ~= "Unknown Entity")
    end
    
    if isReady then
        PawnTooltipHooks:Initialize()
        PawnTooltipHooks.initialized = true
        
        if PawnDebug and PawnDebug.enabled then
            print("|cff8ec3e6Pawn: Tooltip hooks initialized|r")
        end
    end
end

tooltipFrame:SetScript("OnEvent", function()
    if event == "PLAYER_LOGIN" or event == "VARIABLES_LOADED" then
        TryInitialize()
    elseif event == "ADDON_LOADED" then
        local addon = arg1
        if addon == "Pawn" or addon == "Pawn_TurtleWoW" then
            TryInitialize()
        end
    end
end)

-- Also try to initialize immediately if already loaded
TryInitialize()

-- Force immediate initialization for testing
-- This ensures the hooks are available even before PLAYER_LOGIN
if not PawnTooltipHooks.initialized and GameTooltip then
    PawnTooltipHooks:Initialize()
    PawnTooltipHooks.initialized = true
    print("|cff8ec3e6Pawn: Tooltip hooks force-initialized for testing|r")
end