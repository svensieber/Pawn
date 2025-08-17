-- turtle-wow/core/ItemInfo.lua
PawnItemInfo = {
    -- Parse item link into components
    ParseLink = function(self, itemLink)
        -- Format: |cffFFFFFF|Hitem:itemId:enchantId:gem1:gem2:gem3:gem4:suffixId:uniqueId|h[name]|h|r
        -- Vanilla: |cffFFFFFF|Hitem:itemId:enchantId:0:0|h[name]|h|r
        
        local _, _, color, linkType, itemId, enchantId = string.find(itemLink,
            "|?c?(%x*)|?H?([^:]*):?(%d+):?(%d*)")
        
        return {
            id = tonumber(itemId) or 0,
            enchant = tonumber(enchantId) or 0,
            color = color,
            link = itemLink
        }
    end,
    
    -- Get item info with Vanilla compatibility
    GetInfo = function(self, itemLink)
        if not itemLink then return nil end
        
        if PawnDebug then
            PawnDebug:StartTimer("GetItemInfo")
        end
        
        -- Parse link
        local parsed = self:ParseLink(itemLink)
        
        -- Get base info from Vanilla API
        local name, link, quality, _, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(parsed.id)
        
        if not name then
            if PawnDebug then
                PawnDebug:Log(3, "API", "Item not in cache: %d", parsed.id)
            end
            return nil
        end
        
        -- Get item level from tooltip (Vanilla doesn't return it)
        local itemLevel = self:GetItemLevelFromTooltip(itemLink)
        
        if PawnDebug then
            PawnDebug:EndTimer("GetItemInfo", "API")
        end
        
        return {
            name = name,
            link = link or itemLink,
            quality = quality,
            itemLevel = itemLevel,
            requiredLevel = reqLevel,
            class = class,
            subclass = subclass,
            equipSlot = equipSlot,
            texture = texture,
            vendorPrice = vendorPrice,
            itemId = parsed.id
        }
    end,
    
    -- Extract item level from tooltip
    GetItemLevelFromTooltip = function(self, itemLink)
        local tooltip = PawnPrivateTooltip or CreateFrame("GameTooltip", "PawnPrivateTooltip", UIParent, "GameTooltipTemplate")
        tooltip:SetOwner(UIParent, "ANCHOR_NONE")
        
        -- Clear and set item
        tooltip:ClearLines()
        tooltip:SetHyperlink(itemLink)
        
        -- Scan for item level
        for i = 2, tooltip:NumLines() do
            local textLeft = getglobal(tooltip:GetName().."TextLeft"..i)
            if textLeft then
                local text = textLeft:GetText()
                if text then
                    -- Try English pattern first
                    local _, _, level = string.find(text, "Item Level (%d+)")
                    if not level then
                        -- Try German
                        _, _, level = string.find(text, "Gegenstandsstufe (%d+)")
                    end
                    if not level then
                        -- Try French
                        _, _, level = string.find(text, "Niveau d'objet (%d+)")
                    end
                    
                    if level then
                        tooltip:Hide()
                        return tonumber(level)
                    end
                end
            end
        end
        
        tooltip:Hide()
        
        -- Fallback: estimate from required level
        local _, _, _, _, reqLevel = GetItemInfo(itemLink)
        if reqLevel then
            local level = tonumber(reqLevel)
            if level then
                return level + 5  -- Rough estimate
            end
        end
        
        return 0
    end
}