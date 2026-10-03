# Miswell — playable village prototype

A portrait-first Godot 4 prototype for exploring a sketch-built town with a continuous day clock, daily activities, and a family conversation whose consequences unfold across two days.

## Open and play

Open `project.godot` in Godot 4.6 or newer and run the main scene.

- Desktop movement: WASD or arrow keys. Press **E** when the bouncing E key prompt appears by a character or doorway.
- Mobile movement: use the on-screen directional pad; tap the nearby character or door to interact.
- School, supermarket, and gym can each be visited once per day; visits immediately affect anxiety or family trust. The clock advances during exploration and pauses in conversations, messages, and menus. Daily visit limits reset at midnight.
- Home is a place to pause. The family picnic opens a branching conversation on Day 1; your choice changes family trust and anxiety, and shapes the Day 2 follow-up.
- School is beside Miller Park, with a football pitch behind it. Cedar Village and Hillside Farm frame the city with Kenney-style decorative houses and farm tiles.

The portrait camera follows the player through an editable 34×60 tile layout scaled 2× for the existing world coordinates; activity locations keep their positions. The map combines Kenney RPG Urban for paved streets and squares, Kenney Tiny Town for grass and village houses, and Kenney Tiny Farm for the crop plot and barn (all CC0). Open `scenes/world/village_map.tscn` to paint the `Ground`, `Farmyard`, `TownCourtyards`, `CityPlazas`, `Sidewalks`, `Roads`, `FarmCrops`, `FarmStructures`, `VillageHouses`, and `Trees` TileMapLayers. The 16×16 atlases and larger house, barn, and tree tiles are available in `assets/maps/VillageTileSet.tres`. The clickable activity locations still use their existing drawn artwork; the new Kenney houses and farm building are decorative map tiles.

The HUD uses the Kenney RPG Expansion panels, buttons, touch controls, and green anxiety bar, with the Kenney Mini font. Its layout and image styling are in `scripts/presentation/game_hud.gd`; the copied CC0 font pack is in `assets/fonts/Kenney/`. The bouncing interaction marker is the Kenney Pixel input prompt for E. The game uses Kenney Pixel Pack arrow and pointing-hand cursors on desktop.

Filtered Kenney footsteps are in `assets/audio/filtered/footsteps/`: grass and concrete follow the map's TileMapLayers, with the default set as fallback. Carpet and wood sets are included for future interior floors. Footsteps trigger on the planted-foot frames of the walk animation, with the first step sounding as movement begins; walk animation and footstep pace follow actual movement speed. Surface variants play in sequence and repeat. Menus, world interactions, and battle buttons choose a random `click1`–`click5` sound; GUI buttons use `rollover1` when hovered. The audio logic is in `scripts/presentation/game_audio.gd`.

## Smoke check

Run `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/portrait_city_smoke.gd` from this folder to check camera bounds, contextual action visibility, and the conversation branch.
