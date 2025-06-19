-- Pawn Chronoboon Compatibility Fix
-- This file fixes conflicts with ChronoboonTimers addon

-- Only run if ChronoboonTimers is loaded
if not IsAddOnLoaded("ChronoboonTimers") then
    return
end

-- Wait for ChronoboonTimers to load its hooks
local FixFrame = CreateFrame("Frame")
FixFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
FixFrame:SetScript("OnEvent", function()
    -- Delay the fix slightly
    this:SetScript("OnUpdate", function()
        this.elapsed = (this.elapsed or 0) + arg1
        if this.elapsed > 1 then
            this:SetScript("OnUpdate", nil)
            
            -- Apply our fix
            PawnFixChronoboonConflict()
        end
    end)
end)

function PawnFixChronoboonConflict()
    DEFAULT_CHAT_FRAME:AddMessage("|cff8ec3e6Pawn: Applying ChronoboonTimers compatibility fix|r")
    
    -- ChronoboonTimers overwrites SetBagItem in a way that breaks other addons
    -- We need to re-hook after it
    
    if PawnHookTooltips then
        -- Disable existing hooks first
        PawnHooksDisabled = true
        
        -- Re-enable and reinstall
        PawnHooksDisabled = false
        PawnLastTooltipItem = {}
        
        -- Use a safer approach for ChronoboonTimers compatibility
        -- Hook OnUpdate instead of the tooltip functions directly
        GameTooltip:HookScript("OnUpdate", function()
            if not this.PawnUpdatePending then return end
            this.PawnUpdatePending = nil
            
            if PawnLastTooltipItem and PawnLastTooltipItem.link then
                PawnUpdateTooltipWithItemLink("GameTooltip", PawnLastTooltipItem.link)
                PawnLastTooltipItem.link = nil
            end
        end)
        
        -- Alternative hook approach
        local frame = CreateFrame("Frame")
        frame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
        frame:SetScript("OnEvent", function()
            if GameTooltip:IsVisible() and PawnCommon and PawnCommon.Debug then
                -- Try to get current tooltip item
                local focus = GetMouseFocus()
                if focus and focus.GetName then
                    local name = focus:GetName()
                    if name and string.find(name, "ContainerFrame") then
                        -- It's a bag item
                        local _, _, container, slot = string.find(name, "ContainerFrame(%d+)Item(%d+)")
                        if container and slot then
                            container = tonumber(container) - 1  -- Bags are 0-indexed
                            slot = tonumber(slot)
                            local link = GetContainerItemLink(container, slot)
                            if link then
                                PawnLastTooltipItem.link = link
                                GameTooltip.PawnUpdatePending = true
                            end
                        end
                    end
                end
            end
        end)
        
        DEFAULT_CHAT_FRAME:AddMessage("|cff8ec3e6Pawn: ChronoboonTimers fix applied|r")
    end
end