-- turtle-wow/core/APICompat.lua
PawnAPICompat = {}

-- Container API (Vanilla uses different names)
PawnAPICompat.GetContainerNumSlots = GetContainerNumSlots or C_Container.GetContainerNumSlots
PawnAPICompat.GetContainerItemLink = GetContainerItemLink or C_Container.GetContainerItemLink
PawnAPICompat.GetContainerItemInfo = GetContainerItemInfo or C_Container.GetContainerItemInfo

-- Timer API (C_Timer doesn't exist in Vanilla)
if not C_Timer then
    C_Timer = {}
    local timers = {}
    local frame = CreateFrame("Frame")
    local elapsed = 0
    
    -- In Vanilla WoW, OnUpdate doesn't pass delta as second argument
    -- We need to track time ourselves
    local lastUpdate = 0
    
    frame:SetScript("OnUpdate", function()
        local currentTime = GetTime()
        local delta = currentTime - lastUpdate
        
        -- Throttle updates to prevent too frequent calls
        if delta < 0.01 then
            return
        end
        
        lastUpdate = currentTime
        elapsed = elapsed + delta
        
        for id, timer in pairs(timers) do
            timer.time = timer.time - delta
            if timer.time <= 0 then
                timer.func()
                timers[id] = nil
            end
        end
    end)
    
    C_Timer.After = function(seconds, func)
        local id = tostring(func) .. GetTime()
        timers[id] = {time = seconds, func = func}
        return id
    end
    
    C_Timer.NewTimer = C_Timer.After  -- Alias
    
    C_Timer.NewTicker = function(seconds, func, iterations)
        local count = 0
        local ticker = {}
        local function tick()
            count = count + 1
            func()
            if not iterations or count < iterations then
                ticker.timer = C_Timer.After(seconds, tick)
            end
        end
        ticker.timer = C_Timer.After(seconds, tick)
        ticker.Cancel = function(self)
            -- Cancel functionality would need timer tracking
        end
        return ticker
    end
end

-- GetItemStats replacement (CRITICAL - doesn't exist in Vanilla!)
PawnAPICompat.GetItemStats = function(itemLink)
    -- This will be implemented in Phase 2.2
    -- For now, return empty table
    return {}
end