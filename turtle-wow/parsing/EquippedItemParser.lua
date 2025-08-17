-- turtle-wow/parsing/EquippedItemParser.lua
-- Special parser for equipped items when GetInventoryItemLink doesn't return proper hyperlinks

PawnEquippedItemParser = {
    -- Parse stats from an equipped item using SetInventoryItem
    ParseEquippedItem = function(self, unit, slot)
        local stats = {}
        
        if not unit or not slot then
            return stats
        end
        
        -- Create/get private tooltip
        local tooltip = PawnPrivateTooltip or CreateFrame("GameTooltip", "PawnPrivateTooltip", UIParent, "GameTooltipTemplate")
        tooltip:SetOwner(UIParent, "ANCHOR_NONE")
        tooltip:ClearLines()
        
        -- Set inventory item directly (doesn't need hyperlink)
        tooltip:SetInventoryItem(unit, slot)
        
        -- Parse each line
        local numLines = tooltip:NumLines()
        if PawnDebug then
            PawnDebug:Log(4, "PARSING", "Parsing %d lines for equipped slot %d", numLines, slot)
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
            PawnDebug:Log(4, "PARSING", "Found %d stats for slot %d", self:CountStats(stats), slot)
        end
        
        return stats
    end,
    
    -- Parse single line for stats (reuse from StatParser)
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
            if matches[1] then
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
    
    -- Utility: Count stats
    CountStats = function(self, stats)
        local count = 0
        for _ in pairs(stats) do
            count = count + 1
        end
        return count
    end
}