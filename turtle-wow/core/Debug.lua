-- turtle-wow/core/Debug.lua
PawnDebug = {
    enabled = false,
    logLevel = 2,  -- 1=Error, 2=Warning, 3=Info, 4=Debug, 5=Trace
    maxLogSize = 1000,
    log = {},
    
    categories = {
        API = true,
        EVENT = true,
        PARSING = true,
        CACHE = true,
        TOOLTIP = true,
        PERFORMANCE = true,
        EQUIP = true
    },
    
    Log = function(self, level, category, message, arg1, arg2, arg3, arg4, arg5)
        if not self.enabled then return end
        if level > self.logLevel then return end
        if not self.categories[category] then return end
        
        -- Format message with args if provided
        if arg1 then
            -- Count actual arguments
            local args = {}
            if arg1 ~= nil then table.insert(args, arg1) end
            if arg2 ~= nil then table.insert(args, arg2) end
            if arg3 ~= nil then table.insert(args, arg3) end
            if arg4 ~= nil then table.insert(args, arg4) end
            if arg5 ~= nil then table.insert(args, arg5) end
            
            if table.getn(args) > 0 then
                message = format(message, unpack(args))
            end
        end
        
        -- Create log entry
        local entry = {
            time = GetTime(),
            level = level,
            category = category,
            message = message
        }
        
        -- Add to log
        table.insert(self.log, entry)
        
        -- Trim log if too large
        if #self.log > self.maxLogSize then
            table.remove(self.log, 1)
        end
        
        -- Output to chat if high priority
        if level <= 2 then  -- Error or Warning
            local color = level == 1 and "|cffff0000" or "|cffffff00"
            DEFAULT_CHAT_FRAME:AddMessage(format("%sPawn [%s]: %s|r", color, category, message))
        end
    end,
    
    StartTimer = function(self, name)
        self.timers = self.timers or {}
        self.timers[name] = debugprofilestop()
    end,
    
    EndTimer = function(self, name, category)
        if not self.timers or not self.timers[name] then return end
        
        local elapsed = debugprofilestop() - self.timers[name]
        self:Log(4, category or "PERFORMANCE", "%s took %.2f ms", name, elapsed)
        
        self.timers[name] = nil
        return elapsed
    end,
    
    DumpLog = function(self, filter)
        print("=== Pawn Debug Log ===")
        for _, entry in ipairs(self.log) do
            if not filter or entry.category == filter then
                print(format("[%.2f][%s] %s", entry.time, entry.category, entry.message))
            end
        end
    end
}

-- Slash command for debugging
SLASH_PAWNDEBUG1 = "/pawndebug"
SlashCmdList["PAWNDEBUG"] = function(msg)
    if msg == "on" then
        PawnDebug.enabled = true
        print("Pawn debugging enabled")
    elseif msg == "off" then
        PawnDebug.enabled = false
        print("Pawn debugging disabled")
    elseif msg == "dump" then
        PawnDebug:DumpLog()
    else
        print("Usage: /pawndebug [on|off|dump]")
    end
end