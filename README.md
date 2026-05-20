# Atlas Integrated Epoch

Atlas Integrated Epoch is a World of Warcraft 3.3.5a addon for Project Epoch that displays Atlas dungeon maps inside the Blizzard world map experience.

It adds a self-contained dungeon overlay with a boss list, boss loot panel, optional AtlasLoot integration, and compatibility-minded behavior for common map/UI addons.

## Features

- Atlas dungeon maps shown inside the Blizzard world map area
- Auto-selects the current dungeon when you are inside one
- Dungeon selector attached to the world map controls
- Boss list with pagination for long dungeons
- Boss loot panel with item tooltips and drop-rate display
- Optional trash loot entry when AtlasLoot exposes dungeon trash loot
- ElvUI-aware styling when ElvUI world map skinning is enabled
- Interface Options panel for addon settings
- Slash commands:
  - `/aie`
  - `/atlasintegrated`
  - `/edg` legacy alias
  - `/epochdungeons` legacy alias

## Requirements

Required:

- Atlas

Optional:

- AtlasLoot
- AtlasLoot_OriginalWoW

Not required:

- ElvUI
- pfQuest
- Magnify

The addon is designed to keep those addons untouched. It only controls frames it creates itself.

## Credits

Atlas Integrated Epoch depends on Atlas for dungeon map data and optionally integrates with AtlasLoot and AtlasLoot_OriginalWoW for loot data.

This addon does not include or redistribute Atlas or AtlasLoot files. Users must install those addons separately, and credit for those projects remains with their original authors and maintainers.

## Installation

1. Download or clone this repository.
2. Place the `Atlas_Integrated_Epoch` folder in:

   `World of Warcraft\Interface\AddOns\`

3. Make sure `Atlas` is installed and enabled.
4. Optionally enable `AtlasLoot` and `AtlasLoot_OriginalWoW` for loot display.
5. Restart the client or run `/reload`.

## Compatibility Notes

Atlas Integrated Epoch does not modify Blizzard default addon files and does not alter Atlas, AtlasLoot, ElvUI, pfQuest, or Magnify files.

The overlay is intentionally self-owned:

- No broad WorldMap frame scanning
- No reparenting third-party frames
- No global map-layer suppression
- No modifications to Atlas or AtlasLoot data tables

When a dungeon overlay is active, the addon may temporarily hide known world-map markers that would visually overlap the dungeon map. Those frames are restored when the overlay closes.

## Data Model

Dungeon, boss, floor, and loot definitions are kept separate from UI code. In this release, dungeon maps are discovered from Atlas and loot pages are linked from AtlasLoot when available.

The addon does not ship fake Project Epoch dungeon data, bosses, loot, or item IDs.

## Localization

English fallback strings are seeded in `Utils.lua` so the addon always has safe defaults. Additional locale files can be added under `Locales/` and loaded from the TOC before the UI modules.

## Known Limitations

- Live player position is not available on Atlas dungeon maps.
- Loot data depends on the installed AtlasLoot version.
- If Atlas and AtlasLoot are mismatched, boss-to-loot mapping can be incorrect in Atlas itself and in this addon.

## Publishing / Packaging

For manual release packaging, zip the folder itself:

`Atlas_Integrated_Epoch.zip`

The zip should contain:

`Atlas_Integrated_Epoch\Atlas_Integrated_Epoch.toc`

Do not zip the contents without the folder, or WoW will not load the addon correctly.
