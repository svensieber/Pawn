# Modern API Usage Report

Generated: 2025-08-17 10:46:07

Total modern APIs found: 94 occurrences

## Summary

| API | Total Occurrences |
|-----|------------------|
| `C_Item` | 28 |
| `GetSpecialization` | 11 |
| `C_ArtifactUI` | 8 |
| `GetSpecializationInfo` | 8 |
| `ProcessInfo` | 6 |
| `C_Container` | 5 |
| `C_Timer` | 5 |
| `TooltipUtil` | 4 |
| `GetDetailedItemLevelInfo` | 4 |
| `C_EquipmentSet` | 3 |
| `C_TradeSkillUI` | 3 |
| `GetItemInfoInstant` | 3 |
| `GetItemStats` | 3 |
| `SetItemByID` | 2 |
| `C_QuestLog` | 1 |

## Detailed Results

### PawnUI.lua

#### `C_Item` (7 occurrences)

- Line 126: `	_, _, _, ItemLevel = C_Item.GetItemInfo(ItemLink)`
- Line 899: `	if Item then _, _, _, _, _, _, _, _, ItemEquipLoc = C_Item.GetItemInfo(Item.Link) end`
- Line 946: `		ItemName, _, ItemRarity, _, _, _, _, _, ItemEquipLoc, ItemTexture = C_Item.GetItemInfo(ItemLink)`
- Line 968: `			_, _, _, _, _, _, _, _, OtherItemEquipLoc = C_Item.GetItemInfo(PawnUIComparisonItems[OtherIndex].`
- Line 1076: `		local _, _, _, _, _, _, _, _, _, ItemTexture = C_Item.GetItemInfo(Item.Link)`
- Line 2092: `								local ExistingItemName, _, Quality = C_Item.GetItemInfo(ThisUpgradeData.ExistingItemLink)`
- Line 2095: `									local _, _, _, QualityColor =  C_Item.GetItemQualityColor(Quality)`

#### `C_Timer` (2 occurrences)

- Line 1318: `		C_Timer.After(0.5, AutomatedRefresh)`
- Line 1319: `		C_Timer.After(1.0, AutomatedRefresh)`

#### `GetSpecializationInfo` (1 occurrences)

- Line 242: `		local _, LocalizedSpecName, _, IconTexturePath = PawnGetSpecializationInfoForClassID(Scale.ClassID`

#### `C_QuestLog` (1 occurrences)

- Line 2202: `	if C_QuestLog.GetSelectedQuest then QuestID = C_QuestLog.GetSelectedQuest() end`

#### `GetSpecialization` (1 occurrences)

- Line 242: `		local _, LocalizedSpecName, _, IconTexturePath = PawnGetSpecializationInfoForClassID(Scale.ClassID`

#### `ProcessInfo` (1 occurrences)

- Line 180: `	-- (This wouldn't be necessary if you hooked GameTooltip.ProcessInfo instead, but you can't do that`

### Pawn.lua

#### `GetItemStats` (3 occurrences)

- Line 4172: `-- (2) It works on level-scaled relics, which GetItemStats doesn't`
- Line 4180: `	-- GetItemStats() on a relic that was looted at 110 and then passed on to a lower-level character w`
- Line 4199: `	Stats = C_Item.GetItemStats(ItemLink, Stats)`

#### `C_Item` (21 occurrences)

- Line 806: `	local _, _, _, _, MinLevel = C_Item.GetItemInfo(ItemLink)`
- Line 881: `				local IsReady2 = (C_Item.GetItemInfo(ItemLink2) ~= nil)`
- Line 889: `				local IsReady1 = (C_Item.GetItemInfo(ItemLink1) ~= nil)`
- Line 1150: `	local _, _, _, InvType, _, ItemClassID, ItemSubClassID = C_Item.GetItemInfoInstant(ItemLink)`
- Line 1189: `	local ItemID, _, _, InvType, ItemTexture = C_Item.GetItemInfoInstant(ItemLink)`
- Line 1190: `	local ItemName, NewItemLink, ItemRarity, ItemLevel = C_Item.GetItemInfo(ItemLink)`
- Line 1221: `		Item.Level = C_Item.GetDetailedItemLevelInfo(ItemLink) or ItemLevel -- The level from GetItemInfo `
- Line 1380: `	local ItemName, ItemLink, ItemRarity, ItemLevel, _, _, _, _, _, ItemTexture = C_Item.GetItemInfo(It`
- Line 1389: `	Item.Level = C_Item.GetDetailedItemLevelInfo(ItemLink) or ItemLevel`
- Line 1462: `			Item.Level = C_Item.GetDetailedItemLevelInfo(MainHandLink) or Item.Level`
- Line 1813: `					local _, _, _, _, _, _, _, _, InvType = C_Item.GetItemInfo(GetInventoryItemLink(UnitName, Slot)`
- Line 1838: `					local ThisItemLevel = C_Item.GetDetailedItemLevelInfo(ItemLink)`
- Line 3037: `			TextureName = C_Item.GetItemIconByID(ItemLink)`
- Line 3185: `	local ItemName, _, _, _, _, _, _, _, _, ItemTexture = C_Item.GetItemInfo(Item.ID)`
- Line 3642: `	--	local _, ItemLink = C_Item.GetItemInfo(BestOfType[2])`
- Line 3645: `	--		_, ItemLink = C_Item.GetItemInfo(BestOfType[5])`
- Line 3763: `	local _, _, _, _, _, _, _, _, InvType = C_Item.GetItemInfo(ItemLink)`
- Line 3860: `				local _, _, _, _, _, _, _, _, _, _, Value = C_Item.GetItemInfo(Info.Item.Link)`
- Line 4199: `	Stats = C_Item.GetItemStats(ItemLink, Stats)`
- Line 4238: `	local RelicItemID = C_Item.GetItemInfoInstant(RelicItemLink)`
- Line 5381: `	local _, _, _, _, MinLevel = C_Item.GetItemInfo(ItemLink)`

#### `GetItemInfoInstant` (3 occurrences)

- Line 1150: `	local _, _, _, InvType, _, ItemClassID, ItemSubClassID = C_Item.GetItemInfoInstant(ItemLink)`
- Line 1189: `	local ItemID, _, _, InvType, ItemTexture = C_Item.GetItemInfoInstant(ItemLink)`
- Line 4238: `	local RelicItemID = C_Item.GetItemInfoInstant(RelicItemLink)`

#### `TooltipUtil` (4 occurrences)

- Line 336: `			local _, ItemLink = TooltipUtil.GetDisplayedItem(ShoppingTooltip1)`
- Line 340: `			local _, ItemLink = TooltipUtil.GetDisplayedItem(ShoppingTooltip2)`
- Line 2268: `	elseif TooltipUtil then`
- Line 2269: `		_, PrettyLink = TooltipUtil.GetDisplayedItem(Tooltip)`

#### `C_ArtifactUI` (8 occurrences)

- Line 4128: `	local ArtifactItemID, _, ArtifactName = C_ArtifactUI.GetArtifactInfo()`
- Line 4133: `	ArtifactName = C_ArtifactUI.GetArtifactArtInfo().titleName or ArtifactName`
- Line 4145: `	local NumRelicSlots = C_ArtifactUI.GetNumRelicSlots() or 0`
- Line 4147: `		local _, _, _, ThisRelicItemLink = C_ArtifactUI.GetRelicInfo(RelicIndex)`
- Line 4148: `		local LockedReason = C_ArtifactUI.GetRelicLockedReason(RelicIndex)`
- Line 4156: `			ThisRelic.Type = C_ArtifactUI.GetRelicSlotType(RelicIndex)`
- Line 4170: `-- This function does the same as C_ArtifactUI.GetItemLevelIncreaseProvidedByRelic, but provides two`
- Line 4239: `	local _, _, RelicType = C_ArtifactUI.GetRelicInfoByItemID(RelicItemID)`

#### `C_EquipmentSet` (3 occurrences)

- Line 3591: `		for _, i in pairs(C_EquipmentSet.GetEquipmentSetIDs()) do`
- Line 3592: `			local _, _, EquipmentSetID = C_EquipmentSet.GetEquipmentSetInfo(i)`
- Line 3593: `			local ItemLocations = C_EquipmentSet.GetItemLocations(EquipmentSetID)`

#### `GetSpecializationInfo` (7 occurrences)

- Line 1714: `				local _, LocalizedSpecName = PawnGetSpecializationInfoForClassID(ClassID, Scale.SpecID)`
- Line 4838: `	if SpecID then _, _, _, IconTexturePath, Role = PawnGetSpecializationInfoForClassID(ClassID, SpecID`
- Line 5191: `		_, LocalizedSpecName, _, IconTexturePath, Role = PawnGetSpecializationInfoForClassID(ClassID, Spec`
- Line 5270: `-- Wraps the GetSpecializationInfoForClassID function so that it can be called on WoW Classic.`
- Line 5272: `function PawnGetSpecializationInfoForClassID(ClassID, SpecID)`
- Line 5273: `	if VgerCore.IsMainline then return GetSpecializationInfoForClassID(ClassID, SpecID) end`
- Line 5286: `-- 			local _, LocalizedSpecName, _, IconID, Role = GetSpecializationInfoForClassID(ClassID, SpecID)`

#### `C_TradeSkillUI` (3 occurrences)

- Line 221: `				local ItemLink = C_TradeSkillUI.GetRecipeItemLink(RecipeId)`
- Line 439: `	if C_TradeSkillUI and C_TradeSkillUI.SetTooltipRecipeResultItem then`
- Line 440: `		hooksecurefunc(C_TradeSkillUI, "SetTooltipRecipeResultItem", function() PawnUpdateTooltip("GameToo`

#### `C_Timer` (3 occurrences)

- Line 885: `					C_Timer.After(1, function() PawnUI_SetCompareItemAndShow(2, ItemLink2) end)`
- Line 893: `					C_Timer.After(1, function() PawnUI_SetCompareItemAndShow(1, ItemLink1) end)`
- Line 4445: `	C_Timer.After(15, function() TalkingHeadFrame_FadeoutFrames() end)`

#### `SetItemByID` (2 occurrences)

- Line 206: `	hooksecurefunc(GameTooltip, "SetItemByID", function() PawnUpdateTooltip("GameTooltip", "SetItemByID`
- Line 369: `		VgerCore.HookInsecureFunction(AtlasLootTooltip, "SetItemByID", function() PawnUpdateTooltip("Atlas`

#### `C_Container` (5 occurrences)

- Line 391: `				local ItemInfo = C_Container.GetContainerItemInfo(bagID, slot)`
- Line 3616: `						if C_Container and C_Container.GetContainerItemLink then`
- Line 3617: `							ItemLink = C_Container.GetContainerItemLink(Bag, SetSlot)`
- Line 3817: `		if C_Container and C_Container.GetContainerItemLink then`
- Line 3818: `			ItemLink = C_Container.GetContainerItemLink(arg1, arg2)`

#### `GetDetailedItemLevelInfo` (4 occurrences)

- Line 1221: `		Item.Level = C_Item.GetDetailedItemLevelInfo(ItemLink) or ItemLevel -- The level from GetItemInfo `
- Line 1389: `	Item.Level = C_Item.GetDetailedItemLevelInfo(ItemLink) or ItemLevel`
- Line 1462: `			Item.Level = C_Item.GetDetailedItemLevelInfo(MainHandLink) or Item.Level`
- Line 1838: `					local ThisItemLevel = C_Item.GetDetailedItemLevelInfo(ItemLink)`

#### `GetSpecialization` (10 occurrences)

- Line 465: `	if GetSpecialization then`
- Line 758: `		SpecID = GetSpecialization()`
- Line 1714: `				local _, LocalizedSpecName = PawnGetSpecializationInfoForClassID(ClassID, Scale.SpecID)`
- Line 4073: `	local SpecID = GetSpecialization and GetSpecialization() or GetPrimaryTalentTree()`
- Line 4838: `	if SpecID then _, _, _, IconTexturePath, Role = PawnGetSpecializationInfoForClassID(ClassID, SpecID`
- Line 5191: `		_, LocalizedSpecName, _, IconTexturePath, Role = PawnGetSpecializationInfoForClassID(ClassID, Spec`
- Line 5270: `-- Wraps the GetSpecializationInfoForClassID function so that it can be called on WoW Classic.`
- Line 5272: `function PawnGetSpecializationInfoForClassID(ClassID, SpecID)`
- Line 5273: `	if VgerCore.IsMainline then return GetSpecializationInfoForClassID(ClassID, SpecID) end`
- Line 5286: `-- 			local _, LocalizedSpecName, _, IconID, Role = GetSpecializationInfoForClassID(ClassID, SpecID)`

#### `ProcessInfo` (5 occurrences)

- Line 179: `	-- Note that in Dragonflight, most or all of this could be replaced by hooking GameTooltip.ProcessI`
- Line 332: `	-- Dragonflight replaces SetCompareItem with ProcessInfo. (ProcessInfo is now used internally by lo`
- Line 334: `	if ShoppingTooltip1.ProcessInfo then`
- Line 335: `		hooksecurefunc(ShoppingTooltip1, "ProcessInfo", function()`
- Line 339: `		hooksecurefunc(ShoppingTooltip2, "ProcessInfo", function()`


## Replacement Notes

### Critical APIs requiring replacement:

- `C_Timer`: Must implement custom timer system
- `C_Container`: Use old Container API functions
- `C_Item`: Use GetItemInfo and related functions
- `GetItemStats`: Must parse from tooltip
- `GetSpecialization*`: No spec system in Vanilla

