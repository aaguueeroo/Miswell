# Miswell — playable village prototype

A portrait-first Godot 4 prototype for exploring a sketch-built town with a continuous day clock, daily activities, and a family conversation whose consequences unfold across two days.

## Open and play

Open `project.godot` in Godot 4.6 or newer and run the main scene.

- Desktop movement: WASD or arrow keys. Press **E** when the bouncing E key prompt appears by a character or doorway.
- Mobile movement: use the on-screen directional pad; tap the nearby character or door to interact.
- School, supermarket, and gym can each be visited once per day; visits immediately affect anxiety or family trust. The clock advances during exploration and pauses in conversations, messages, and menus. Daily visit limits reset at midnight.
- Home is a place to pause. The family picnic opens a branching conversation on Day 1; your choice changes family trust and anxiety, and shapes the Day 2 follow-up.
- Mom, Dad, Grandpa, and Sister are at the family picnic. Three villagers walk short routes through town; nearby NPCs have short dialogue that can be edited on their scene instances.
- School is beside Miller Park, with a football pitch behind it. Cedar Village and Hillside Farm frame the city with Kenney-style decorative houses and farm tiles.
- Open the Unhealth Graph with **G** on desktop or its HUD button. Select a circular node to inspect its status; scroll sideways to see the full graph on a narrow screen.
- The village light changes continuously with the game clock: cool moonlight and warm building lights overnight, pink and gold at sunrise, and gold fading through dusk. In debug builds, the three play buttons beside the clock set time to **1×**, **8×**, or **16×** for viewing the transition; the selected button is blue. Time still pauses with the game.

The portrait camera follows the player through an editable 34×60 tile layout scaled 2× for the existing world coordinates; activity locations keep their positions. The map combines Kenney RPG Urban for paved streets and squares, Kenney Tiny Town for grass and village houses, and Kenney Tiny Farm for the crop plot and barn (all CC0). Open `scenes/world/village_map.tscn` to paint the `Ground`, `Farmyard`, `TownCourtyards`, `CityPlazas`, `Sidewalks`, `Roads`, `FarmCrops`, `FarmStructures`, `VillageHouses`, and `Trees` TileMapLayers. The 16×16 atlases and larger house, barn, and tree tiles are available in `assets/maps/VillageTileSet.tres`. The clickable activity locations still use their existing drawn artwork; the new Kenney houses and farm building are decorative map tiles.

Home, school, supermarket, and gym each have a separate scene in `scenes/interiors/`. Walk into an exterior doorway, press **E** at it, or tap it on mobile to enter; walk through the marked south exit to return to the village. The fade pauses game time. The former school, shop, and gym visits are now at the **Class**, **Shop**, and **Train** spots indoors, and saving remembers which interior you are in. Home has separate living, kitchen, parent, sister, and player rooms; school has two classrooms, a cafeteria, a director's office, and a teachers' room. Every scene has editable `FloorTiles` and `FurnitureTiles` layers sharing `assets/maps/modern_tiles_free/InteriorTileSet.tres`; `tools/build_interiors.gd` generated their starting layouts. Interior NPCs use the existing portrait dialogue screen. The included Modern Tiles Free `LICENSE.txt` permits noncommercial use only, so replace or relicense those textures before a commercial release.

The HUD uses the Kenney RPG Expansion panels, buttons, touch controls, and green anxiety bar, with the Kenney Mini font. Its layout and image styling are in `scripts/presentation/game_hud.gd`; the copied CC0 font pack is in `assets/fonts/Kenney/`. The bouncing interaction marker is the Kenney Pixel input prompt for E. The game uses Kenney Pixel Pack arrow and pointing-hand cursors on desktop.

Day and night lighting is configured in `scripts/presentation/world_lighting.gd` and `scenes/world/world_lighting.tscn`. The ambient color follows eased stops from 04:30 to 08:00 for sunrise and 17:30 to 21:00 for sunset. Building lights brighten as night falls. Change those stops to adjust the look without replacing map textures. The debug buttons scale the existing game clock and reset to 1× when starting or loading a game.

NPC sprites are in `assets/characters/npcs/`. The shared `scenes/actors/npc_actor.tscn` builds idle and directional walk animations from each 16×16 sheet. Edit `dialogue_text`, `route_offsets`, `walk_speed`, and `pause_seconds` on an NPC instance in `scenes/world/village.tscn`. Each NPC also has an editable `portrait_texture` Faceset; NPC conversations use the battle UI with that portrait at the top right and the player's Faceset at the bottom. Mom's sprite and fallback line are in `scenes/actors/family_npc.tscn`; her existing branching story encounter is unchanged. The graph UI uses Kenney RPG circular buttons and panels, Kenney Mini labels, and one icon per built-in node under `assets/gui/problem_graph/icons/`.

Filtered Kenney footsteps are in `assets/audio/filtered/footsteps/`: grass and concrete follow the map's TileMapLayers, with the default set as fallback. Carpet and wood sets are included for future interior floors. Footsteps trigger on the planted-foot frames of the walk animation, with the first step sounding as movement begins; walk animation and footstep pace follow actual movement speed. Surface variants play in sequence and repeat. Menus, world interactions, and battle buttons choose a random `click1`–`click5` sound; GUI buttons use `rollover1` when hovered. The audio logic is in `scripts/presentation/game_audio.gd`.

## Smoke check

Run `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/portrait_city_smoke.gd` from this folder to check camera bounds, contextual action visibility, and the conversation branch.
