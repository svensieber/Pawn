-- Pawn by Vger-Azjol-Nerub
-- www.vgermods.com
-- © 2006-2025 Travis Spomer.  This mod is released under the Creative Commons Attribution-NonCommercial-NoDerivs 3.0 license.
-- See Readme.htm for more information.

--
-- Core things required for localization - Vanilla/Turtle WoW version
------------------------------------------------------------

-- Make sure compatibility layer is loaded first
if not PawnCompatDebug then
	DEFAULT_CHAT_FRAME:AddMessage("|cffff0000Pawn Error: PawnCompat_Vanilla.lua must be loaded before Core_Vanilla.lua|r")
	return
end

------------------------------------------------------------
-- "Constants"
------------------------------------------------------------

PawnQuestionTexture = "|TInterface\\AddOns\\Pawn\\Textures\\Question:0|t" -- Texture string that represents a (?).
PawnDiamondTexture = "|TInterface\\AddOns\\Pawn\\Textures\\Diamond:0|t" -- Texture string that represents a diamond.
PawnUpgradeTexture = "|TInterface\\AddOns\\Pawn\\Textures\\UpgradeArrow:0|t" -- Texture string that represents an upgrade arrow.
PawnNewFeatureTexture = "|TInterface\\OptionsFrame\\UI-OptionsFrame-NewFeatureIcon:0:0:0:-1|t" -- Texture string that represents a new feature (!) icon.
PawnSingleStatMultiplier = "_SingleMultiplier"
PawnMultipleStatsFixed = "_MultipleFixed"
PawnMultipleStatsExtract = "_MultipleExtract"

-- Vanilla specific constants
PawnClassic = true  -- Important flag for the rest of Pawn

-- In Classic, the best armor for mail and plate classes wasn't available until level 40.
PawnBestArmorMinimumLevel = 40
PawnArmorSpecializationLevel = nil -- No armor specialization in Vanilla

------------------------------------------------------------
-- Localization
------------------------------------------------------------

-- The languages that Pawn is currently translated into (http://www.wowpedia.org/API_GetLocale)
PawnLocalizedLanguages = { "deDE", "enUS", "enGB", "esES", "esMX", "frFR", "itIT", "koKR", "ptBR", "ruRU", "zhCN", "zhTW" }

-- NOTE: These functions are not super-flexible for general purpose; they don't properly handle all sorts of Lua pattern matching syntax
-- that could be in strings, like "." and so on.  But they've been sufficient so far.

-- Extra parentheses around gsub drops all of gsub's return values after the first.

-- Turns a game constant into a regular expression.
function PawnGameConstant(Text)
	return "^" .. PawnGameConstantUnwrapped(Text) .. "$"
end

-- Turns a game constant into a regular expression but without the ^ and $ on the ends.
function PawnGameConstantUnwrapped(Text)
	-- Some of these constants don't exist on Classic versions, so skip them
	if Text == nil then return "^UNUSED$" end
	-- In Lua 5.0, we need to be careful with gsub
	local result = string.gsub(Text, "%%", "%%%%")
	result = string.gsub(result, "%-", "%%-")
	return result
end

-- Turns a game constant with one "%s" placeholder into a pattern that can be used to match that string.
function PawnGameConstantIgnoredPlaceholder(Text)
	-- Optimize for the common case where the %s is on the end.  This yields a more efficient pattern.
	local textLen = string.len(Text)
	if string.sub(Text, textLen - 1) == "%s" then
		return "^" .. PawnGameConstantUnwrapped(string.sub(Text, 1, textLen - 2))
	end
	-- If it's not at the end, replace it.
	local result = string.gsub(Text, "%%s", ".+", 1)
	return PawnGameConstant(result)
end

-- Turns a game constant with "%d" placeholders into a pattern that can be used to match that string.
function PawnGameConstantIgnoredNumberPlaceholder(Text)
	local pattern = PawnGameConstant(Text)
	return string.gsub(pattern, "%%%%d", "%%d+")
end

-- Escapes a string so that it can be more easily printed.
function PawnEscapeString(String)
	if not String then return "" end
	local result = string.gsub(String, "\r", "\\r")
	result = string.gsub(result, "\n", "\\n")
	result = string.gsub(result, "|", "||")
	return result
end

-- Vanilla specific utility functions
-- Safe string length
function PawnStrLen(str)
	if not str then return 0 end
	return string.len(str)
end

-- Test message to verify Core is loaded
if PawnCompatDebug then
	PawnCompatDebug("Core_Vanilla.lua loaded successfully")
end