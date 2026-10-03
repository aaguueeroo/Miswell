# Miswell — playable village prototype

A portrait-first Godot 4 prototype for walking around a sketch-built town, planning a day in fixed time slots, and testing a family conversation across two days.

## Open and play

Open `project.godot` in Godot 4.6 or newer and run the main scene.

- Desktop movement: WASD or arrow keys. Press **E** when the bouncing action badge appears by a character or doorway.
- Mobile movement: use the on-screen directional pad; tap the nearby character or door to interact.
- The school, supermarket, gym and family conversation ask you to assign an open Morning, Afternoon, or Evening slot. The top strip shows the planned day order.
- The active home ends the day. Reaching the family picnic on Day 1 opens a branching conversation. Overthinking is now a conversational action; doing it raises anxiety and can reveal the anxious-focus reply.
- School is beside Miller Park, with a football pitch behind it. The residential quarter has labeled, non-interactive home sketches.

The map is 1080×1920 and the portrait camera follows the player. Its editable urban layout uses the Kenney RPG Urban Pack (CC0). Open `scenes/world/village_map.tscn` to paint the `Ground`, `PlazasAndCourts`, `Roads`, and `Trees` TileMapLayers; the 16×16 atlas is in `assets/maps/kenney_rpg-urban-pack/UrbanTileSet.tres`. The map layers are scaled 2× for the existing world coordinates, and the activity locations keep their existing positions. The interactive location buildings still use their existing drawn artwork; replacing those is the remaining map-art refinement.

## Smoke check

Run `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/portrait_city_smoke.gd` from this folder to check camera bounds, contextual action visibility, and the conversation branch.
