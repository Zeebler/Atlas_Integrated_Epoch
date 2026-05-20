# Atlas Integrated Epoch

Atlas Integrated Epoch brings Atlas dungeon maps into the regular Blizzard world map UI for Project Epoch.

I have always used Atlas and AtlasLoot to check dungeon maps and boss loot. After playing Turtle WoW, I got used to dungeon maps being integrated into the main map, so I wanted something similar for Project Epoch. This addon keeps Atlas and AtlasLoot working normally, but also makes their dungeon map and loot information available directly when you press `M`.

## Features

- Shows Atlas dungeon maps inside the Blizzard world map
- Auto-selects your current dungeon
- Adds a dungeon selector to the world map
- Adds a boss list with pagination for large dungeons
- Shows boss loot when AtlasLoot is installed
- Adds optional trash loot entries when AtlasLoot provides them
- Supports ElvUI styling when ElvUI world map skinning is enabled
- Avoids modifying Atlas, AtlasLoot, Blizzard UI files, pfQuest, ElvUI, or Magnify

## Dependencies

Required:

- Atlas

Optional:

- AtlasLoot
- AtlasLoot_OriginalWoW

Verified Compatibility:

- ElvUI
- pfQuest
- Magnify

## Slash Commands

- `/aie`
- `/atlasintegrated`

## Install

Place the `Atlas_Integrated_Epoch` folder in:

```text
World of Warcraft\Interface\AddOns\
```

Then enable it from the addon list and reload or restart the game.

## Notes

This addon does not include Atlas or AtlasLoot data. You must install Atlas separately, and AtlasLoot is required only if you want loot panels.

Live player position is not available on Atlas dungeon maps.

If Atlas and AtlasLoot versions do not match, boss-to-loot mapping may also be wrong in this addon.

## Credits

Atlas Integrated Epoch depends on Atlas for dungeon map data and optionally integrates with AtlasLoot / AtlasLoot_OriginalWoW for loot data. Credit for those projects belongs to their original authors and maintainers.

