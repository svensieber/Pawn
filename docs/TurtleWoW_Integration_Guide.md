# Turtle WoW Scaling Integration Guide for Pawn Addon

## Overview
This guide explains how to integrate Turtle WoW-specific class scaling adjustments into the Pawn addon for accurate stat weights on the Turtle WoW private server.

## Installation

### Method 1: Complete Replacement
1. Backup your existing `ClassicHawsJon.lua` file
2. Copy `TurtleWowScalingAdjustments_Complete.lua` to your Pawn addon folder
3. Rename it to replace the original scaling file or modify Pawn.toc to load it

### Method 2: Manual Integration
1. Open `ClassicHawsJon.lua` in your Pawn addon folder
2. Add the Turtle WoW scaling values from `TurtleWowScalingAdjustments.lua`
3. Modify each class/spec entry with the adjustment multipliers

### Method 3: Dynamic Loading
1. Keep both files in the Pawn folder
2. Add to Pawn.toc:
   ```
   TurtleWowScalingAdjustments_Complete.lua
   ```
3. The integration function will automatically hook into Pawn

## Key Changes by Class

### Druid
- **Balance**: +3% crit from Moonkin Form, +25% nature damage from Eclipse
- **Feral**: +12% attack speed from Blood Frenzy, improved Swipe/Rake AP scaling
- **Restoration**: Tree of Life healing improvements

### Hunter
- **Beast Mastery**: Spirit Bond 25% AP to pet, Bestial Precision 18% spell hit
- **Marksmanship**: Lethal Shots crit improvements
- **Survival**: Balanced stat distribution

### Mage
- **Arcane**: Arcane Missiles 14.7% damage increase, +6% crit from Arcane Impact
- **Fire**: Ignite and Combustion synergies
- **Frost**: Winter's Chill and Shatter combo improvements

### Paladin
- **Holy**: Standard healing improvements
- **Protection**: Consecration threat and block value scaling
- **Retribution**: Crusader Strike 130% weapon damage, Seal of Command 43% spellpower

### Priest
- **Discipline**: Balanced healing/utility
- **Holy**: Spirit-based regeneration focus
- **Shadow**: Mind Flay 66.7% spellpower increase, Shadow Form +15% damage

### Rogue
- **Assassination**: Improved poison application
- **Combat**: Blade Flurry penalty removed (+20% damage)
- **Subtlety**: Stealth and burst improvements

### Shaman
- **Elemental**: Lightning Overload synergies
- **Enhancement**: Stormstrike +25% nature damage, 10% AP to spell conversion
- **Restoration**: Water Shield mana regeneration

### Warlock
- **Affliction**: Dark Harvest 20% tick reduction, Drain Soul improvements
- **Demonology**: Felguard 30% spell damage, Master Demonologist +5%
- **Destruction**: Conflagrate 60% coefficient, Shadowburn efficiency

### Warrior
- **Arms**: Mortal Strike 130% weapon damage, Master of Arms +5% crit
- **Fury**: Rampage +30% attack speed, Bloodthirst 45% AP
- **Protection**: Shield Slam block value scaling

## Coefficient Calculations

The adjustments use multiplicative scaling:
```lua
NewValue = OriginalValue * TurtleMultiplier
```

Example for Druid Balance:
- Original SpellCritRating: `SpellCritRatingPer * 0.62`
- Turtle WoW adjustment: `* 1.03` (Moonkin +3% crit)
- Final value: `SpellCritRatingPer * 0.62 * 1.03`

## Testing

To verify the integration:
1. Load the addon in-game
2. Open Pawn interface (`/pawn`)
3. Check that class templates show modified values
4. Compare tooltips with expected Turtle WoW mechanics

## Troubleshooting

### Values Not Updating
- Ensure the integration function runs after Pawn loads
- Check that class/spec IDs match Turtle WoW's numbering
- Verify the scaling file is listed in Pawn.toc

### Incorrect Calculations
- Review the multipliers against current Turtle WoW patch notes
- Confirm rating conversions match the server's formulas
- Test with known gear pieces to validate

## Contributing

To add or update scaling values:
1. Research the current Turtle WoW class changes
2. Calculate the appropriate multipliers
3. Update the relevant class/spec section
4. Test in-game with appropriate gear
5. Submit changes with documentation

## References

- Turtle WoW Class Changes: [Forum/Wiki links]
- Original Pawn Scaling: ClassicHawsJon.lua
- WoW Classic Formulas: Various theorycrafting resources

## Version History

- v1.0: Initial implementation with all 9 classes
- v1.1: Added missing specializations
- v1.2: Updated coefficients based on latest patches