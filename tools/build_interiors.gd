extends SceneTree

# Run from Godot after importing the PNGs. The resulting scenes have normal,
# editable TileMapLayer nodes; this script only seeds their first layout.
const TILESET_PATH := "res://assets/maps/modern_tiles_free/InteriorTileSet.tres"
const ROOM_TEXTURE := "res://assets/maps/modern_tiles_free/Room_Builder_free_32x32.png"
const FURNITURE_TEXTURE := "res://assets/maps/modern_tiles_free/Interiors_free_32x32.png"
const FONT_PATH := "res://assets/fonts/Kenney/Fonts/Kenney Mini.ttf"
const NPC_SCENE := "res://scenes/actors/npc_actor.tscn"
const CELL := 32.0

var _tileset: TileSet

func _initialize() -> void:
	_tileset = _build_tileset()
	if ResourceSaver.save(_tileset, TILESET_PATH) != OK:
		push_error("Could not save indoor tile set")
		quit(1)
		return
	_tileset = load(TILESET_PATH) as TileSet
	if _tileset == null:
		push_error("Could not reopen indoor tile set")
		quit(1)
		return
	_build_home()
	_build_school()
	_build_supermarket()
	_build_gym()
	quit()

func _build_tileset() -> TileSet:
	var result := TileSet.new()
	result.tile_size = Vector2i(32, 32)
	for path in [ROOM_TEXTURE, FURNITURE_TEXTURE]:
		var source := TileSetAtlasSource.new()
		source.texture = load(path) as Texture2D
		source.texture_region_size = Vector2i(32, 32)
		result.add_source(source)
		var grid: Vector2i = source.get_atlas_grid_size()
		for y in grid.y:
			for x in grid.x:
				source.create_tile(Vector2i(x, y))
	return result

func _new_interior(id: StringName, title: String, cells: Vector2i, surface: StringName) -> Dictionary:
	var root := BuildingInterior.new()
	root.name = title.replace(" ", "") + "Interior"
	root.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	root.building_id = id
	root.display_name = title
	root.world_size = Vector2(cells) * CELL
	root.entry_position = Vector2(float(cells.x) * CELL * 0.5, float(cells.y) * CELL - 96.0)
	root.floor_surface = surface
	var floor := _new_layer(root, "FloorTiles", -2)
	var furniture := _new_layer(root, "FurnitureTiles", -1)
	_add_outer_walls(root, root.world_size)
	_add_exit(root, root.world_size)
	_add_room_label(root, "Exit", Vector2(root.world_size.x * 0.5 - 18.0, root.world_size.y - 70.0))
	return {"root": root, "floor": floor, "furniture": furniture, "cells": cells}

func _new_layer(root: Node2D, name: String, layer_index: int) -> TileMapLayer:
	var layer := TileMapLayer.new()
	layer.name = name
	layer.tile_set = _tileset
	layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	layer.z_index = layer_index
	root.add_child(layer)
	layer.owner = root
	return layer

func _paint(floor: TileMapLayer, rect: Rect2i, atlas_origin: Vector2i) -> void:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var atlas := atlas_origin + Vector2i(posmod(x, 3), posmod(y, 2))
			floor.set_cell(Vector2i(x, y), 0, atlas)

func _stamp(layer: TileMapLayer, target: Vector2i, source: Rect2i) -> void:
	for y in source.size.y:
		for x in source.size.x:
			layer.set_cell(target + Vector2i(x, y), 1, source.position + Vector2i(x, y))

func _furniture(root: Node2D, layer: TileMapLayer, target: Vector2i, source: Rect2i, solid: bool = true) -> void:
	_stamp(layer, target, source)
	if solid:
		_add_collision(root, Rect2(Vector2(target) * CELL + Vector2(4, 8), Vector2(source.size) * CELL - Vector2(8, 16)))

func _add_outer_walls(root: Node2D, size: Vector2) -> void:
	var door_left: float = size.x * 0.5 - 44.0
	var door_right: float = size.x * 0.5 + 44.0
	_add_wall(root, Rect2(0, 0, size.x, 18))
	_add_wall(root, Rect2(0, 0, 18, size.y))
	_add_wall(root, Rect2(size.x - 18, 0, 18, size.y))
	_add_wall(root, Rect2(0, size.y - 18, door_left, 18))
	_add_wall(root, Rect2(door_right, size.y - 18, size.x - door_right, 18))

func _add_wall(root: Node2D, rect: Rect2) -> void:
	var body := _add_collision(root, rect)
	body.name = "Wall_%d_%d_%dx%d" % [roundi(rect.position.x), roundi(rect.position.y), roundi(rect.size.x), roundi(rect.size.y)]
	var shape := Polygon2D.new()
	shape.name = "WallFill"
	shape.polygon = PackedVector2Array([
		Vector2(-rect.size.x * 0.5, -rect.size.y * 0.5),
		Vector2(rect.size.x * 0.5, -rect.size.y * 0.5),
		Vector2(rect.size.x * 0.5, rect.size.y * 0.5),
		Vector2(-rect.size.x * 0.5, rect.size.y * 0.5)
	])
	shape.color = Color("#51495a")
	body.add_child(shape)
	shape.owner = root
	var trim := Line2D.new()
	trim.name = "WallTrim"
	trim.width = 3.0
	trim.default_color = Color("#d9c49e")
	trim.points = PackedVector2Array([
		Vector2(-rect.size.x * 0.5, -rect.size.y * 0.5),
		Vector2(rect.size.x * 0.5, -rect.size.y * 0.5)
	])
	body.add_child(trim)
	trim.owner = root

func _add_collision(root: Node2D, rect: Rect2) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.name = "FurnitureCollision_%d_%d" % [roundi(rect.position.x), roundi(rect.position.y)]
	body.position = rect.get_center()
	root.add_child(body)
	body.owner = root
	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collision.shape = shape
	body.add_child(collision)
	collision.owner = root
	return body

func _add_exit(root: Node2D, size: Vector2) -> void:
	var area := Area2D.new()
	area.name = "ExitArea"
	area.position = Vector2(size.x * 0.5, size.y - 17.0)
	area.collision_layer = 0
	area.collision_mask = 1
	root.add_child(area)
	area.owner = root
	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var shape := RectangleShape2D.new()
	shape.size = Vector2(88.0, 30.0)
	collision.shape = shape
	area.add_child(collision)
	collision.owner = root

func _add_action(root: Node2D, id: StringName, title: String, position: Vector2) -> void:
	var action := InteriorAction.new()
	action.name = "Activity"
	action.location_id = id
	action.display_name = title
	action.position = position
	root.add_child(action)
	action.owner = root

func _add_room_label(root: Node2D, title: String, position: Vector2) -> void:
	var label := Label.new()
	label.name = title.replace(" ", "") + "Label"
	label.text = title
	label.position = position
	label.add_theme_font_override("font", load(FONT_PATH) as Font)
	label.add_theme_font_size_override("font_size", 17)
	label.add_theme_color_override("font_color", Color("#463c47"))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(label)
	label.owner = root

func _add_npc(root: Node2D, node_name: String, display: String, asset_folder: String, position: Vector2, dialogue: String, route: PackedVector2Array = PackedVector2Array()) -> void:
	var npc := (load(NPC_SCENE) as PackedScene).instantiate() as NpcActor
	npc.name = node_name
	npc.display_name = display
	npc.dialogue_text = dialogue
	npc.story_actor_id = StringName("interior_" + node_name.to_snake_case())
	npc.opens_battle_ui_on_interaction = true
	var portrait_path := asset_folder + "/Faceset.png"
	if not ResourceLoader.exists(portrait_path):
		portrait_path = asset_folder + "/Faceset1.png"
	npc.portrait_texture = load(portrait_path) as Texture2D
	npc.idle_sheet = load(asset_folder + "/SeparateAnim/Idle.png") as Texture2D
	npc.walk_sheet = load(asset_folder + "/SeparateAnim/Walk.png") as Texture2D
	npc.position = position
	npc.route_offsets = route
	root.add_child(npc)
	npc.owner = root

func _save_scene(room: Dictionary) -> void:
	var root: BuildingInterior = room["root"]
	var packed := PackedScene.new()
	if packed.pack(root) != OK:
		push_error("Could not pack " + root.name)
		return
	var path := "res://scenes/interiors/%s_interior.tscn" % String(root.building_id)
	if ResourceSaver.save(packed, path) != OK:
		push_error("Could not save " + path)
	root.free()

func _build_home() -> void:
	var room := _new_interior(&"home", "Home", Vector2i(30, 34), &"wood")
	var root: Node2D = room["root"]
	var floor: TileMapLayer = room["floor"]
	var furniture: TileMapLayer = room["furniture"]
	_paint(floor, Rect2i(0, 0, 30, 34), Vector2i(0, 11))
	_paint(floor, Rect2i(17, 12, 13, 21), Vector2i(14, 5))
	_add_wall(root, Rect2(0, 352, 128, 12))
	_add_wall(root, Rect2(192, 352, 256, 12))
	_add_wall(root, Rect2(512, 352, 224, 12))
	_add_wall(root, Rect2(800, 352, 160, 12))
	_add_wall(root, Rect2(320, 18, 12, 334))
	_add_wall(root, Rect2(640, 18, 12, 334))
	_add_wall(root, Rect2(544, 364, 12, 246))
	_add_wall(root, Rect2(544, 674, 12, 350))
	_add_room_label(root, "Parents' room", Vector2(58, 44))
	_add_room_label(root, "Sister's room", Vector2(364, 44))
	_add_room_label(root, "My room", Vector2(718, 44))
	_add_room_label(root, "Living room", Vector2(64, 400))
	_add_room_label(root, "Kitchen", Vector2(610, 400))
	for x in [3, 13, 23]:
		_furniture(root, furniture, Vector2i(x, 4), Rect2i(1, 48, 3, 3))
	for x in [7, 17, 27]:
		_furniture(root, furniture, Vector2i(x, 6), Rect2i(7, 48, 2, 3))
	_furniture(root, furniture, Vector2i(23, 9), Rect2i(0, 36, 3, 2))
	_furniture(root, furniture, Vector2i(4, 18), Rect2i(0, 72, 3, 2))
	_furniture(root, furniture, Vector2i(8, 20), Rect2i(7, 13, 3, 2), false)
	_furniture(root, furniture, Vector2i(2, 23), Rect2i(10, 69, 2, 2))
	_furniture(root, furniture, Vector2i(20, 16), Rect2i(0, 54, 3, 2))
	_furniture(root, furniture, Vector2i(26, 17), Rect2i(4, 77, 3, 3))
	_furniture(root, furniture, Vector2i(21, 23), Rect2i(2, 38, 3, 2))
	_add_action(root, &"home", "Rest", Vector2(420, 800))
	_add_npc(root, "Mom", "Mom", "res://assets/characters/npcs/family/mom", Vector2(310, 570), "There's room on the sofa whenever you need it.")
	_add_npc(root, "Dad", "Dad", "res://assets/characters/npcs/family/dad", Vector2(710, 760), "I made something simple for dinner.")
	_add_npc(root, "Sister", "Sister", "res://assets/characters/npcs/family/sister", Vector2(430, 480), "You can visit my room, but knock first!")
	_save_scene(room)

func _build_school() -> void:
	var room := _new_interior(&"school", "School", Vector2i(46, 40), &"wood")
	var root: Node2D = room["root"]
	var floor: TileMapLayer = room["floor"]
	var furniture: TileMapLayer = room["furniture"]
	_paint(floor, Rect2i(0, 0, 46, 40), Vector2i(12, 8))
	_paint(floor, Rect2i(0, 18, 21, 22), Vector2i(11, 9))
	_paint(floor, Rect2i(25, 18, 21, 22), Vector2i(14, 5))
	_add_wall(root, Rect2(448, 18, 12, 430))
	_add_wall(root, Rect2(960, 18, 12, 430))
	for rect in [Rect2(0, 448, 192, 12), Rect2(256, 448, 416, 12), Rect2(800, 448, 360, 12), Rect2(1224, 448, 248, 12)]:
		_add_wall(root, rect)
	for rect in [Rect2(672, 576, 12, 256), Rect2(672, 896, 12, 366), Rect2(800, 576, 12, 256), Rect2(800, 896, 12, 366)]:
		_add_wall(root, rect)
	_add_room_label(root, "Classroom A", Vector2(58, 44))
	_add_room_label(root, "Classroom B", Vector2(542, 44))
	_add_room_label(root, "Director's office", Vector2(1020, 44))
	_add_room_label(root, "Cafeteria", Vector2(58, 624))
	_add_room_label(root, "Teachers' room", Vector2(866, 624))
	for x_start in [2, 17]:
		for x_offset in [0, 5]:
			for y in [5, 9]:
				_furniture(root, furniture, Vector2i(x_start + x_offset, y), Rect2i(2, 38, 2, 2))
	_furniture(root, furniture, Vector2i(3, 2), Rect2i(10, 40, 2, 2))
	_furniture(root, furniture, Vector2i(18, 2), Rect2i(10, 40, 2, 2))
	_furniture(root, furniture, Vector2i(34, 4), Rect2i(0, 36, 6, 2))
	_furniture(root, furniture, Vector2i(31, 10), Rect2i(10, 69, 2, 2))
	for x in [3, 10, 16]:
		for y in [23, 29]:
			_furniture(root, furniture, Vector2i(x, y), Rect2i(2, 38, 3, 2))
	_furniture(root, furniture, Vector2i(29, 23), Rect2i(0, 72, 3, 2))
	_furniture(root, furniture, Vector2i(36, 25), Rect2i(7, 13, 3, 2))
	_furniture(root, furniture, Vector2i(40, 20), Rect2i(10, 69, 2, 2))
	_add_action(root, &"school", "Class", Vector2(864, 372))
	var school_assets := "res://assets/characters/npcs/interiors/"
	_add_npc(root, "ClassmateA", "Classmate", school_assets + "classmate_1", Vector2(250, 300), "Did you finish the assignment?")
	_add_npc(root, "ClassmateB", "Classmate", school_assets + "classmate_2", Vector2(360, 280), "We have class after the break.")
	_add_npc(root, "ClassmateC", "Classmate", school_assets + "classmate_3", Vector2(590, 340), "There's an empty seat nearby.")
	_add_npc(root, "ClassmateD", "Classmate", school_assets + "classmate_4", Vector2(850, 190), "I like this classroom.")
	_add_npc(root, "Director", "Director", school_assets + "director", Vector2(1180, 330), "Welcome to the school. My office is always open.")
	_add_npc(root, "Teacher", "Teacher", school_assets + "teacher", Vector2(1090, 870), "The teachers are preparing the next lesson.")
	_add_npc(root, "StudentTwinA", "Student", school_assets + "student_twin_1", Vector2(240, 920), "The cafeteria has a free table.")
	_add_npc(root, "StudentTwinB", "Student", school_assets + "student_twin_2", Vector2(470, 860), "Meet me after class!")
	_add_npc(root, "YoungStudent", "Student", school_assets + "student_little", Vector2(350, 700), "I brought my lunch today.")
	_save_scene(room)

func _build_supermarket() -> void:
	var room := _new_interior(&"supermarket", "Supermarket", Vector2i(36, 34), &"concrete")
	var root: Node2D = room["root"]
	var floor: TileMapLayer = room["floor"]
	var furniture: TileMapLayer = room["furniture"]
	_paint(floor, Rect2i(0, 0, 36, 34), Vector2i(14, 5))
	_paint(floor, Rect2i(0, 0, 36, 8), Vector2i(0, 11))
	_add_wall(root, Rect2(0, 256, 896, 12))
	_add_wall(root, Rect2(968, 256, 184, 12))
	_add_room_label(root, "Stockroom", Vector2(64, 44))
	_add_room_label(root, "Fresh food", Vector2(64, 308))
	_add_room_label(root, "Checkout", Vector2(484, 878))
	for x in [4, 11, 18, 25]:
		for y in [12, 15, 18, 21]:
			_furniture(root, furniture, Vector2i(x, y), Rect2i(10, 69, 2, 2))
	for x in [3, 9, 15, 21, 27]:
		_furniture(root, furniture, Vector2i(x, 2), Rect2i(0, 54, 3, 2))
	_furniture(root, furniture, Vector2i(6, 26), Rect2i(0, 16, 5, 2))
	_furniture(root, furniture, Vector2i(24, 26), Rect2i(0, 16, 5, 2))
	_add_action(root, &"supermarket", "Shop", Vector2(576, 878))
	_add_npc(root, "Cashier", "Cashier", "res://assets/characters/npcs/interiors/villager_5", Vector2(350, 905), "I can help you at the checkout.")
	_add_npc(root, "ShopperA", "Shopper", "res://assets/characters/npcs/villager_1", Vector2(285, 420), "I'm looking for something for dinner.")
	_add_npc(root, "ShopperB", "Shopper", "res://assets/characters/npcs/villager_2", Vector2(770, 670), "The shelves are well stocked today.")
	_add_npc(root, "Stocker", "Stocker", "res://assets/characters/npcs/villager_3", Vector2(420, 145), "More supplies are in the back room.")
	_save_scene(room)

func _build_gym() -> void:
	var room := _new_interior(&"gym", "Gym", Vector2i(34, 34), &"concrete")
	var root: Node2D = room["root"]
	var floor: TileMapLayer = room["floor"]
	var furniture: TileMapLayer = room["furniture"]
	_paint(floor, Rect2i(0, 0, 34, 34), Vector2i(14, 5))
	_paint(floor, Rect2i(2, 3, 18, 23), Vector2i(11, 9))
	_paint(floor, Rect2i(22, 16, 11, 13), Vector2i(11, 9))
	_add_wall(root, Rect2(640, 18, 12, 494))
	_add_wall(root, Rect2(640, 608, 12, 480))
	_add_wall(root, Rect2(652, 448, 148, 12))
	_add_wall(root, Rect2(864, 448, 224, 12))
	_add_room_label(root, "Training floor", Vector2(64, 44))
	_add_room_label(root, "Locker room", Vector2(724, 44))
	_add_room_label(root, "Stretching", Vector2(734, 516))
	for x in [3, 9, 15]:
		_furniture(root, furniture, Vector2i(x, 7), Rect2i(11, 80, 4, 3))
		_furniture(root, furniture, Vector2i(x, 16), Rect2i(12, 74, 2, 2), false)
	for x in [23, 27]:
		_furniture(root, furniture, Vector2i(x, 4), Rect2i(4, 77, 3, 3))
	for x in [23, 28]:
		_furniture(root, furniture, Vector2i(x, 20), Rect2i(1, 42, 4, 2), false)
	_add_action(root, &"gym", "Train", Vector2(416, 784))
	var gym_assets := "res://assets/characters/npcs/interiors/"
	_add_npc(root, "GymBroA", "Gym regular", gym_assets + "gym_bro_1", Vector2(240, 420), "One more set, then a break.")
	_add_npc(root, "GymBroB", "Gym regular", gym_assets + "gym_bro_2", Vector2(500, 580), "Remember to warm up first.")
	_add_npc(root, "GymBroC", "Gym regular", gym_assets + "gym_bro_3", Vector2(860, 725), "The stretching space is quiet today.")
	_save_scene(room)
