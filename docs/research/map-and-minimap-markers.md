# Map and minimap markers for WoW Forever

Research date: 2026-11-14. Target: the Forever client / interface 16001 named in this repo. Blizzard's extracted `forever` UI source is the primary reference for API shape. It does not establish that every documented API behaves identically in the installed live build.

## Confirmed API surface

- `C_Map.GetBestMapForUnit("player")` returns a UI map ID (or nil); `C_Map.GetPlayerMapPosition(uiMapID, "player")` returns a map-position vector (or nil). The same API docs describe `C_Map.GetMapInfo`, map children, and `C_Map.GetMapWorldSize`. These are useful for map selection and player position, not for discovering NPC positions. [Forever Map API docs](https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/MapDocumentation.lua)
- Blizzard's MapCanvas implementation supports data providers, pooled pin templates, and pin acquisition (`AddDataProvider`, `AcquirePin`). This is the client UI's map-overlay mechanism. It is not an add-on API guarantee that `WorldMapFrame` accepts arbitrary providers in every state; simplest robust add-on implementation may instead own a child overlay on the map canvas and redraw pins when map/zoom changes. [Forever MapCanvas implementation](https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/Interface/AddOns/Blizzard_MapCanvas/Blizzard_MapCanvas.lua)
- `C_Minimap` provides tracking-state and map identity functions including `GetUiMapID`, `GetViewRadius`, and tracking functions. The generated API has no NPC lookup or arbitrary world-coordinate-to-minimap marker API. Minimap tracking icons are client-owned. Treat a custom minimap overlay as its own coordinate-projection problem, not as a built-in marker feed. [Forever Minimap API docs](https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/MinimapDocumentation.lua)
- Do not assume Retail/other-client minimap methods exist. Current Forever issue reports and API inventory note missing `Minimap:SetBlipTexture` and `SetPlayerTexture`; only `SetIconScale` affects the built-in blips globally. Verify the exact methods in-client before using them. [Forever client API inventory](https://github.com/xIGBClutchIx/ForeverPlusPlus/blob/main/docs/forever-api.md)

## NPC data: useful starting points, not an authoritative exhaustive catalog

No reviewed Blizzard API enumerates Shady Dealers, poison-reagent vendors, or Rogue trainers by type or returns all their coordinates. A marker feature therefore needs a maintained NPC catalog (map ID plus normalized x/y and source/build metadata), rather than expecting runtime discovery from `C_Map` or `C_Minimap`.

- **Shady Dealers and poison vendors:** ForeverDB's Rogue poison guide lists vendor names, factions, locations and Forever-seen flags; its page includes Shady Dealers, poison suppliers, and reagent stock. This is the best practical seed list found, but it is a community-maintained report, not Blizzard-owned data. Cross-check vendor identity and inventory in the Forever client. [ForeverDB Rogue poisons](https://foreverdb.net/class/Rogue/poisons)
- **Rogue trainers:** ForeverDB lists Rogue trainers and locations alongside poison vendors. Forever Tavern's NPC directory is another community index, but explicitly labels many records “Classic reference” or “not yet confirmed in Forever”; do not promote those entries to confirmed Forever markers without an in-game check. [ForeverDB Rogue poisons](https://foreverdb.net/class/Rogue/poisons), [Forever Tavern NPC directory](https://forever-tavern.com/npcs/)
- **Reagent-vendor identification:** At a merchant, use the already documented `C_MerchantFrame.GetItemInfo(index)`/`GetMerchantItemID(index)` listing to determine whether a nearby NPC sells relevant reagent items. This reliably identifies a merchant's current stock when its merchant frame is open; it does not identify NPCs elsewhere in the world. [Repo merchant API note](poison-vendor-purchase-api.md)
- **Coordinates:** Treat catalog coordinates as approximate until checked against the actual Forever map/build. Community ForeverDB provides coordinate observations, and its page distinguishes some “seen in Forever” records from legacy references. Store provenance per entry and do not infer Forever existence from a Classic NPC database alone.

## Unknown runtime behavior and manual verification

The source confirms API declarations and Blizzard's UI implementation, but not the in-game behavior of Roguetastiq's overlay, coordinate alignment, map transitions, or Forever's current NPC placement. Before release, verify manually on the current client:

1. Confirm `/dump C_Map.GetBestMapForUnit("player"), C_Map.GetPlayerMapPosition(C_Map.GetBestMapForUnit("player"), "player")` returns usable map ID/coordinates in each supported city/zone; check interior/subzone behavior and nil cases.
2. Open the world map and check that dealer, poison supplier/vendor, and Rogue trainer markers align on each supported map at multiple zoom levels, after map changes, and after reload. Confirm map pins do not drift when canvas size changes.
3. Visit each catalog NPC in Forever. Record exact NPC name, title/type, map, coordinates, faction/race scope if applicable, and whether they sell poison reagents or train Rogue abilities. Exclude unverified Classic-only entries.
4. For each reagent vendor, open the merchant frame and compare its actual item IDs/names with the catalog's reagent recognition rules. Check variants and stock changes.
5. If a minimap overlay is included, verify rotation, zoom, player movement, map edge behavior, and visibility with the default and alternate minimap settings. The documented C_Minimap API alone does not prove a reliable NPC projection.

### Primary source set

- Blizzard UI source mirror, Forever branch: [Gethe/wow-ui-source](https://github.com/Gethe/wow-ui-source/tree/forever)
- Generated Forever map API: [MapDocumentation.lua](https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/MapDocumentation.lua)
- Generated Forever minimap API: [MinimapDocumentation.lua](https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/MinimapDocumentation.lua)
- Blizzard Forever map canvas implementation: [Blizzard_MapCanvas.lua](https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/Interface/AddOns/Blizzard_MapCanvas/Blizzard_MapCanvas.lua)
