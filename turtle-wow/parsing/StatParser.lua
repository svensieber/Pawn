-- turtle-wow/parsing/StatParser.lua
PawnStatParser = {
    cache = {},
    cacheSize = 0,
    maxCacheSize = 500,
    
    -- Main parsing function
    ParseItemStats = function(self, itemLink)
        if PawnDebug then
            PawnDebug:StartTimer("ParseItemStats")
        end
        
        -- Check cache
        local cached = self.cache[itemLink]
        if cached then
            cached.hits = (cached.hits or 0) + 1
            if PawnDebug then
                PawnDebug:Log(5, "CACHE", "Cache hit for %s", itemLink)
                PawnDebug:EndTimer("ParseItemStats", "CACHE")
            end
            return cached.stats
        end
        
        -- Parse from tooltip
        local stats = self:ParseTooltip(itemLink)
        
        -- Add to cache
        self:AddToCache(itemLink, stats)
        
        if PawnDebug then
            PawnDebug:EndTimer("ParseItemStats", "PARSING")
        end
        
        return stats
    end,
    
    -- Parse tooltip for stats
    ParseTooltip = function(self, itemLink)
        local stats = {}
        
        -- Validate item link
        if not itemLink or type(itemLink) ~= "string" then
            if PawnDebug then
                PawnDebug:Log(2, "PARSING", "Invalid item link: %s", tostring(itemLink))
            end
            return stats
        end
        
        -- Check if it's a valid item link format
        if not string.find(itemLink, "item:") then
            if PawnDebug then
                PawnDebug:Log(2, "PARSING", "Not an item link: %s", itemLink)
            end
            return stats
        end
        
        -- Create/get private tooltip
        local tooltip = PawnPrivateTooltip or CreateFrame("GameTooltip", "PawnPrivateTooltip", UIParent, "GameTooltipTemplate")
        tooltip:SetOwner(UIParent, "ANCHOR_NONE")
        tooltip:ClearLines()
        
        -- Set item with error protection
        local success, err = pcall(function()
            tooltip:SetHyperlink(itemLink)
        end)
        
        if not success then
            if PawnDebug then
                PawnDebug:Log(2, "PARSING", "Failed to set hyperlink: %s - Error: %s", itemLink, tostring(err))
            end
            return stats
        end
        
        -- Parse each line
        local numLines = tooltip:NumLines()
        if PawnDebug then
            PawnDebug:Log(4, "PARSING", "Parsing %d lines for %s", numLines, itemLink)
        end
        
        for i = 2, numLines do  -- Skip line 1 (item name)
            -- Get left text
            local leftText = getglobal(tooltip:GetName().."TextLeft"..i)
            if leftText then
                local text = leftText:GetText()
                if text then
                    self:ParseLine(text, stats)
                end
            end
            
            -- Get right text (some items have stats on right)
            local rightText = getglobal(tooltip:GetName().."TextRight"..i)
            if rightText then
                local text = rightText:GetText()
                if text then
                    self:ParseLine(text, stats)
                end
            end
        end
        
        -- Special handling for weapon damage and speed
        if tooltip:NumLines() >= 2 then
            local line2 = getglobal(tooltip:GetName().."TextLeft2")
            if line2 then
                local text = line2:GetText()
                if text then
                    -- Check for damage range (e.g., "44 - 82 Damage")
                    local _, _, minDmg, maxDmg = string.find(text, "(%d+) %- (%d+) Damage")
                    if minDmg and maxDmg then
                        stats.MinDamage = tonumber(minDmg)
                        stats.MaxDamage = tonumber(maxDmg)
                    end
                    
                    -- Check for speed (e.g., "Speed 3.60")
                    local _, _, speed = string.find(text, "Speed (%d+%.%d+)")
                    if speed then
                        stats.Speed = tonumber(speed)
                    end
                end
            end
        end
        
        tooltip:Hide()
        
        if PawnDebug then
            PawnDebug:Log(4, "PARSING", "Found %d stats", self:CountStats(stats))
        end
        
        return stats
    end,
    
    -- Parse single line for stats
    ParseLine = function(self, text, stats)
        -- Remove color codes
        text = string.gsub(text, "|c%x%x%x%x%x%x%x%x", "")
        text = string.gsub(text, "|r", "")
        text = string.gsub(text, "|n", "")
        
        -- Skip empty or very short lines
        if not text or string.len(text) < 3 then return end
        
        -- Try each pattern
        for _, patternInfo in ipairs(PawnStatPatterns.patterns) do
            local matches = {string.find(text, patternInfo.pattern)}
            
            -- string.find returns start, end, then captures
            -- We only care about captures (3rd value onwards)
            if matches[1] then
                -- Extract actual captured values (skip first 2 values from string.find)
                local capturedValue = matches[3]
                
                -- Found a match
                if capturedValue and patternInfo.stat then
                    -- Single stat
                    local value = tonumber(capturedValue)
                    if value then
                        stats[patternInfo.stat] = (stats[patternInfo.stat] or 0) + value
                        if PawnDebug then
                            PawnDebug:Log(5, "PARSING", "Matched %s: %d", patternInfo.stat, value)
                        end
                    end
                elseif capturedValue and patternInfo.stats then
                    -- Multiple stats
                    local value = tonumber(capturedValue)
                    if value then
                        for stat, multiplier in pairs(patternInfo.stats) do
                            stats[stat] = (stats[stat] or 0) + (value * multiplier)
                        end
                        if PawnDebug then
                            PawnDebug:Log(5, "PARSING", "Matched multi-stat with value %d", value)
                        end
                    end
                end
                
                -- Only match one pattern per line
                break
            end
        end
    end,
    
    -- Cache management
    AddToCache = function(self, itemLink, stats)
        -- Check cache size
        if self.cacheSize >= self.maxCacheSize then
            -- Find and remove oldest entry
            local oldest = nil
            local oldestTime = GetTime()
            
            for link, data in pairs(self.cache) do
                if data.time < oldestTime then
                    oldest = link
                    oldestTime = data.time
                end
            end
            
            if oldest then
                self.cache[oldest] = nil
                self.cacheSize = self.cacheSize - 1
            end
        end
        
        -- Add to cache
        self.cache[itemLink] = {
            stats = stats,
            time = GetTime(),
            hits = 0
        }
        self.cacheSize = self.cacheSize + 1
    end,
    
    -- Utility: Count stats
    CountStats = function(self, stats)
        local count = 0
        for _ in pairs(stats) do
            count = count + 1
        end
        return count
    end,
    
    -- Clear cache
    ClearCache = function(self)
        self.cache = {}
        self.cacheSize = 0
        if PawnDebug then
            PawnDebug:Log(3, "CACHE", "Stat cache cleared")
        end
    end
}