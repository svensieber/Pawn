-- Pawn UI Strings for Vanilla
-- Simplified version without dependencies

-- Make sure PawnLocal exists
if not PawnLocal then PawnLocal = {} end

-- UI-specific strings
PawnLocal.ScaleTab = "Scale"
PawnLocal.CompareTab = "Compare"  
PawnLocal.GemsTab = "Gems"
PawnLocal.OptionsTab = "Options"
PawnLocal.AboutTab = "About"

-- Option strings
PawnLocal.UI = {
	["ShowItemLevelUpgradesCheck"] = "Show item level upgrades",
	["ShowTooltipIconsCheck"] = "Show inventory icons on tooltips",
	["ShowBagUpgradeAdvisorCheck"] = "Show bag upgrade advisor",
	["ShowUpgradesOnTooltipsCheck"] = "Show upgrades on tooltips",
	["ShowUpgradesOnTooltipsCheckTooltip"] = "Show item values and upgrade information on tooltips.",
	["ShowRelicUpgradesCheck"] = "Show relic upgrades",
	["AlignRightCheck"] = "Align values on the right side of tooltips",
	["ShowSetBonusValueInTooltipsCheck"] = "Show set bonus values separately",
	["ShowItemIDsCheck"] = "Show item IDs",
	["ShowIconsCheck"] = "Show profession icons",
	["ShowExtraSpaceCheck"] = "Add blank line before values",
	["Debug"] = "Debug (extremely verbose)",
}

-- Initialize UI strings in PawnLocal
for Key, Value in pairs(PawnLocal.UI) do
	PawnLocal[Key] = Value
end