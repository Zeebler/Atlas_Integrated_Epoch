# Atlas Integrated Epoch

Atlas Integrated Epoch brings Atlas dungeon maps into the regular Blizzard world map UI for Project Epoch.

## Features

- Shows Atlas dungeon maps inside the Blizzard world map frame
- Auto-selects your current dungeon
- Adds a dungeon selector to the world map frame (top right)
- Adds a boss list with pagination for large dungeons like BRD
- Shows boss loot when AtlasLoot is installed
- Adds optional trash loot entries when AtlasLoot provides them
- Supports ElvUI styling when ElvUI world map skinning is enabled

## Dependencies

Required:

- [Atlas](https://github.com/Raynbock/Atlas-Project-Epoch)

Optional:

- [AtlasLoot](https://github.com/reneas/AtlaslootProjectEpoch)
- AtlasLoot_OriginalWoW 

Verified Compatibility:

- ElvUI
- pfQuest
- Magnify

## Slash Commands

- `/aie`
- `/atlasintegrated`

## Install

Download and install required/optional dependencies.

Place the `Atlas_Integrated_Epoch` folder and dependencies in:

```text
World of Warcraft\Interface\AddOns\
```

Then enable it from the addon list and reload or restart the game.

## Notes

This addon does not include Atlas or AtlasLoot data. You must install Atlas separately, and AtlasLoot is required only if you want loot panels.

Live player position is not available on Atlas dungeon maps. If Atlas and AtlasLoot versions do not match, boss-to-loot mapping may also be wrong in this addon.

## Credits

Atlas Integrated Epoch depends on Atlas for dungeon map data and optionally integrates with AtlasLoot / AtlasLoot_OriginalWoW for loot data. Credit for those projects belongs to their original authors and maintainers.

