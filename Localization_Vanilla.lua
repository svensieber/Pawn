-- Pawn by Vger-Azjol-Nerub
-- Simplified localization for Vanilla WoW

PawnLocal = {
	-- Basic strings
	["AverageItemLevelIgnoringRarityTooltipLine"] = "Average item level",
	["BaseValueWord"] = "base",
	["DecimalSeparator"] = ".",
	["EnchantedStatsHeader"] = "(Current value)",
	["UnenchantedStatsHeader"] = "(Base value)",
	["Unusable"] = "(unusable)",
	["ItemIDTooltipLine"] = "Item ID",
	["ItemLevelTooltipLine"] = "Item Level",
	["NoScale"] = "(none)",
	["NoScalesDescription"] = "To begin, import a scale or start a new one.",
	
	-- Commands
	["Usage"] = "Pawn by Vger-Azjol-Nerub\n/pawn -- show or hide the Pawn UI\n/pawn debug on|off -- debug messages\n/pawn backup -- backup scales",
	
	-- Colors
	["ArtifactColor"] = "e5cc80",
	["AzeritePowerColor"] = "ffd200",
	["CommentColor"] = "909090",
	["EnchantedColor"] = "00ff00",
	["ExtraValueColor"] = "ffd200",
	["IgnoredStatColor"] = "808080",
	["MissocketColor"] = "ff4040",
	["NormalColor"] = "ffffffff",
	["RelicColor"] = "ff8000",
	["UnusableColor"] = "ee1111",
	
	-- Messages  
	["DidntUnderstandMessage"] = "   (?) Didn't understand \"%s\".",
	["FoundStatMessage"] = "   %d %s",
	["NeedNewerVgerCoreMessage"] = "Pawn needs a newer version of VgerCore.",
}

-- Function to get localized strings
function PawnGetString(Key)
	return PawnLocal[Key] or Key
end

-- Initialize
if not PawnInitializeLocalization then
	function PawnInitializeLocalization()
		-- Placeholder for future localization initialization
		return true
	end
end

PawnInitializeLocalization()