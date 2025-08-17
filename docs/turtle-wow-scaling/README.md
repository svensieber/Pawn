# Turtle WoW Scaling Changes - Complete Theorycrafting Database

This directory contains comprehensive scaling value changes for all classes in Turtle WoW, organized by class for theorycrafting and rebalancing purposes.

## Purpose
All scaling coefficients, percentage changes, and numerical adjustments have been extracted from patches 1.16.1, 1.17.0, 1.17.2, and 1.18.0. This data is specifically formatted for:
- Theorycrafting simulations
- Class balance analysis
- Scaling coefficient adjustments
- Damage/healing calculations

## File Structure

Each YAML file contains:
- **Baseline Changes**: Core ability modifications
- **Talent Changes**: Specialization-specific adjustments
- **Key Scaling Values**: Quick reference for important coefficients
- **Percentage Changes**: All multiplicative modifiers
- **Cooldown Changes**: Timing adjustments
- **Duration Changes**: Effect length modifications

## Class Files

- `druid-scaling-changes.yaml` - All Druid scaling coefficients and changes
- `hunter-scaling-changes.yaml` - Hunter and pet scaling data
- `mage-scaling-changes.yaml` - Mage spellpower coefficients
- `paladin-scaling-changes.yaml` - Paladin healing/damage scaling
- `priest-scaling-changes.yaml` - Priest healing and shadow coefficients
- `rogue-scaling-changes.yaml` - Rogue energy and damage scaling
- `shaman-scaling-changes.yaml` - Shaman AP/SP conversions and totems
- `warlock-scaling-changes.yaml` - Warlock and demon scaling values
- `warrior-scaling-changes.yaml` - Warrior rage and damage formulas

## Key Scaling Categories

### Attack Power Scaling
- Ability damage coefficients
- Pet/demon AP inheritance
- AP to spell damage conversions

### Spell Power Scaling
- Direct damage coefficients
- Healing power ratios
- DoT/HoT tick scaling

### Percentage Modifiers
- Damage increases/reductions
- Threat modifiers
- Mana cost changes
- Critical damage bonuses

### Resource Changes
- Mana cost adjustments
- Energy modifications
- Rage generation formulas
- Focus costs (pets)

## Usage Notes

1. All values are exact as documented in patch notes
2. Coefficients are presented as percentages or ratios
3. Changes show progression: "old value -> new value"
4. Stacking effects note maximum stacks
5. Conditional effects include trigger requirements

## Data Completeness

This extraction includes:
- ✅ All damage/healing coefficients
- ✅ All percentage-based changes
- ✅ All cooldown modifications
- ✅ All resource cost changes
- ✅ All threat modifiers
- ✅ All duration adjustments
- ✅ All pet/demon scaling
- ✅ All proc chances and conditions

## Version History

- Patches covered: 1.16.1, 1.17.0, 1.17.2, 1.18.0
- Updates include October and November 2024 adjustments
- Final revision: August 2025 (1.18.0)

## Important Notes

- Scaling values are for **mechanically relevant** changes only
- Cosmetic changes and bug fixes are excluded
- Focus is on theorycrafting and rebalancing data
- All values suitable for simulation tools and spreadsheets