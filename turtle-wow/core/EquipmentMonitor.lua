-- turtle-wow/core/EquipmentMonitor.lua
PawnEquipmentMonitor = {
    cache = {},
    initialized = false,
    
    Initialize = function(self)
        -- Cache current equipment
        for slot = 1, 19 do
            self.cache[slot] = GetInventoryItemLink("player", slot)
        end
        
        -- Register for changes
        PawnEventCompat:Register("UNIT_INVENTORY_CHANGED", function(unit)
            if unit == "player" then
                self:OnInventoryChanged()
            end
        end)
        
        self.initialized = true
    end,
    
    OnInventoryChanged = function(self)
        if not self.initialized then return end
        
        local changes = {}
        local hasChanges = false
        
        for slot = 1, 19 do
            local current = GetInventoryItemLink("player", slot)
            local cached = self.cache[slot]
            
            if current ~= cached then
                changes[slot] = {
                    old = cached,
                    new = current,
                    slot = slot
                }
                hasChanges = true
                
                -- Update cache
                self.cache[slot] = current
                
                -- Debug output
                if PawnDebug and PawnDebug.enabled then
                    local slotName = self:GetSlotName(slot)
                    if current then
                        PawnDebug:Log(3, "EQUIP", format("Equipped %s in %s", current, slotName))
                    else
                        PawnDebug:Log(3, "EQUIP", format("Unequipped item from %s", slotName))
                    end
                end
            end
        end
        
        if hasChanges then
            -- Trigger Pawn updates
            if PawnInvalidateItemCache then
                PawnInvalidateItemCache()
            end
            if PawnUpdateBagUpgradeArrows then
                PawnUpdateBagUpgradeArrows()
            end
        end
        
        return changes
    end,
    
    GetSlotName = function(self, slotId)
        local slotNames = {
            [1] = "Head", [2] = "Neck", [3] = "Shoulder", [4] = "Shirt",
            [5] = "Chest", [6] = "Belt", [7] = "Legs", [8] = "Feet",
            [9] = "Wrist", [10] = "Gloves", [11] = "Finger0", [12] = "Finger1",
            [13] = "Trinket0", [14] = "Trinket1", [15] = "Back", [16] = "MainHand",
            [17] = "OffHand", [18] = "Ranged", [19] = "Tabard"
        }
        return slotNames[slotId] or "Unknown"
    end
}