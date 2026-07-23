# Dolmenwood — Active Effects Items

FGU extension for the Dolmenwood ruleset.

Automatically applies Active Effects to a combat tracker actor when an item is equipped, and removes them when it is unequipped.

## How to Use

### Setting Up Effects on an Item

1. Open any item record (from the Items sidebar or a character's inventory).
2. Click the new **Effects** tab.
3. Click the **+** button to add an effect row.
4. Click the pencil icon on the row to open the effect editor and type an effect string (e.g. `AC: +2` or `ATK: +1; DMG: +1`).
5. Close the editor — the effect string appears in the row.

Add as many effect rows as needed to a single item.

### Equipping the Item

When a character equips an item (sets its Carried status to Equipped in the inventory), each effect defined on that item is automatically applied to the actor in the combat tracker. When the item is unequipped, those effects are automatically removed.

At campaign load, the extension re-scans all character sheets and reapplies effects for any items already equipped, so effects are never lost between sessions.

## Effect String Format

Effect strings follow standard Dolmenwood Active Effects syntax:

| Effect string | What it does |
|---|---|
| `AC: +2` | +2 to armor class |
| `ATK: +1` | +1 to attack rolls |
| `ATK: +1; DMG: +1` | +1 to attack and damage |
| `SPEED: -10` | -10 to movement speed |
| `STRENGTH: +2` | +2 to Strength score |

## Notes

- Effects are permanent while the item is equipped — they have no round/turn duration.
- Effects marked **Hidden** visibility are GM-only in the combat tracker.
- Effects on unidentified items are hidden from players until the item is identified.

## Compatibility

- Dolmenwood ruleset
- Purely additive — does not modify any Dolmenwood ruleset files
