-- turtle-wow/core/EventCompat.lua
PawnEventCompat = {
    -- Map modern events to Vanilla equivalents
    eventMap = {
        ["PLAYER_EQUIPMENT_CHANGED"] = "UNIT_INVENTORY_CHANGED",
        ["ITEM_UPGRADE_MASTER_UPDATE"] = nil,  -- Doesn't exist
        ["ARTIFACT_UPDATE"] = nil,              -- Doesn't exist
        ["AZERITE_EMPOWERED_ITEM_SELECTION_UPDATED"] = nil,
        ["PLAYER_SPECIALIZATION_CHANGED"] = nil,  -- No specs
    },
    
    -- Events that need special handling
    needsDebounce = {
        ["UNIT_INVENTORY_CHANGED"] = 0.5,  -- 500ms debounce
        ["BAG_UPDATE"] = 0.2,              -- 200ms debounce
    },
    
    timers = {},
    handlers = {},
    
    Register = function(self, event, handler)
        -- Map to Vanilla event if needed
        local mappedEvent = self.eventMap[event]
        if mappedEvent == nil then
            -- Event doesn't exist in Vanilla, skip
            return false
        end
        
        event = mappedEvent or event
        
        -- Store handler
        self.handlers[event] = handler
        
        -- Register with WoW
        PawnEventsFrame:RegisterEvent(event)
        
        return true
    end,
    
    OnEvent = function(self, event, arg1, arg2, arg3, arg4, arg5)
        local handler = self.handlers[event]
        if not handler then return end
        
        -- Check if needs debouncing
        local debounce = self.needsDebounce[event]
        if debounce then
            -- Cancel existing timer
            if self.timers[event] then
                -- Timer exists, reset it
                -- Note: In our simple implementation, we just overwrite
            end
            
            -- Store args for closure
            local savedArg1, savedArg2, savedArg3, savedArg4, savedArg5 = arg1, arg2, arg3, arg4, arg5
            
            -- Create new timer
            self.timers[event] = C_Timer.After(debounce, function()
                handler(savedArg1, savedArg2, savedArg3, savedArg4, savedArg5)
                self.timers[event] = nil
            end)
        else
            -- Direct call
            handler(arg1, arg2, arg3, arg4, arg5)
        end
    end
}

-- Create event frame
PawnEventsFrame = CreateFrame("Frame", "PawnEventsFrame")
PawnEventsFrame:SetScript("OnEvent", function()
    -- In Vanilla, event and args are globals
    PawnEventCompat:OnEvent(event, arg1, arg2, arg3, arg4, arg5)
end)