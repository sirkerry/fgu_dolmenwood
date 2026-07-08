# Dolmenwood — Active Effects Items

**Author:** Kerry Harrison (sirkerry)  
**Ruleset:** Dolmenwood  
**Version:** 1.0  
**FG Forge Listing:** not yet published

Automatically applies Advanced Effects to a combat tracker actor when an item is equipped, and removes them when it is unequipped.

---

## How It Works

The Dolmenwood ruleset has a full Advanced Effects system built in — effects can be written as strings like `ATK: +1; AC: +2` and applied to actors in the combat tracker. This extension wires that system to the item inventory so equipping an item can automatically push its effects to the actor.

### Setting Up Effects on an Item

1. Open any item record (from the Items sidebar or a character's inventory).
2. Click the new **Effects** tab.
3. Click the **+** button to add an effect row.
4. Click the pencil icon on the row to open the effect editor and type your effect string (e.g. `AC: +2` or `ATK: +1; DMG: +1`).
5. Close the editor — the effect string appears in the row.

You can add as many effect rows as you like to a single item.

### Equipping the Item

When a character equips an item (sets its **Carried** status to **Equipped** in the inventory), each effect defined on that item is automatically applied to the actor in the combat tracker. The effect source is tagged internally so the extension knows which effects came from which item.

When the item is unequipped, those effects are automatically removed from the actor.

### At Session Start

When the GM loads a campaign, the extension scans all character sheets and reapplies effects for any items that are already equipped, so effects are never lost between sessions.

---

## Effect String Format

Effect strings follow the standard Dolmenwood / Advanced Effects syntax. Examples:

| Effect string | What it does |
|---|---|
| `AC: +2` | +2 to armor class |
| `ATK: +1` | +1 to attack rolls |
| `ATK: +1; DMG: +1` | +1 to attack and damage |
| `SPEED: -10` | -10 to movement speed |
| `STRENGTH: +2` | +2 to Strength score (via the ability effects system) |

---

## Notes

- Effects are permanent while the item is equipped (no round/turn duration — items don't "expire").
- Effects marked **Hidden** visibility (`Hide`) are GM-only in the CT.
- Unidentified items: effects on unidentified items are hidden from players until the item is identified.
- This extension does not modify any Dolmenwood ruleset files — it is purely additive.

---

## Files

| File | Purpose |
|---|---|
| `scripts/manager_item_effects.lua` | Core logic — watches inventory carried state, applies/removes CT effects |
| `base.xml` | Registers the manager; adds Effects tab to items; provides `ref_ability_effects` panel |
| `strings/strings.xml` | Tooltip string for the effect row field |
