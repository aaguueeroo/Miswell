class_name LocationActor
extends StaticBody2D

signal door_crossed(location_id: StringName)

@export var definition: LocationDefinition

@onready var _wall_left: CollisionShape2D = $WallLeft
@onready var _wall_right: CollisionShape2D = $WallRight
@onready var _wall_above_door: CollisionShape2D = $WallAboveDoor
@onready var _door_area: Area2D = $DoorArea

func _ready() -> void:
	add_to_group("locations")
	_configure_doorway()
	_door_area.body_entered.connect(_on_door_body_entered)
	queue_redraw()

func _configure_doorway() -> void:
	var door_x: float = clampf(definition.interaction_offset.x if definition != null else 0.0, -45.0, 45.0)
	var left_width: float = door_x + 48.0
	var right_width: float = 48.0 - door_x
	var left_shape := (_wall_left.shape as RectangleShape2D).duplicate() as RectangleShape2D
	left_shape.size = Vector2(left_width, 55.0)
	_wall_left.shape = left_shape
	_wall_left.position = Vector2(-66.0 + left_width * 0.5, -42.0)
	var right_shape := (_wall_right.shape as RectangleShape2D).duplicate() as RectangleShape2D
	right_shape.size = Vector2(right_width, 55.0)
	_wall_right.shape = right_shape
	_wall_right.position = Vector2(66.0 - right_width * 0.5, -42.0)
	_wall_above_door.position.x = door_x
	_door_area.position.x = door_x

func _on_door_body_entered(body: Node2D) -> void:
	if definition != null and body is PlayerActor:
		door_crossed.emit(definition.location_id)

func get_interaction_anchor() -> Vector2:
	if definition == null:
		return global_position
	return global_position + definition.interaction_offset

func _draw() -> void:
	_draw_ellipse(Vector2(0.0, 0.0), 79.0, 15.0, Color(0.14, 0.19, 0.16, 0.18))
	match String(definition.building_style) if definition != null else "":
		"home":
			_draw_home()
		"school":
			_draw_school()
		"supermarket":
			_draw_supermarket()
		"gym":
			_draw_gym()
		_:
			_draw_default()
	if definition != null:
		_draw_sign(definition.display_name.to_upper())

func _draw_home() -> void:
	_draw_rect(Rect2(-65.0, -109.0, 130.0, 94.0), Color("#d9c79e"), Color("#765c48"), 3.0)
	_draw_rect(Rect2(-70.0, -112.0, 140.0, 12.0), Color("#b49b73"), Color("#765c48"), 2.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-83.0, -108.0), Vector2(-71.0, -157.0), Vector2(0.0, -207.0),
		Vector2(71.0, -157.0), Vector2(83.0, -108.0), Vector2(66.0, -101.0),
		Vector2(0.0, -148.0), Vector2(-66.0, -101.0)
	]), Color("#a85f4e"))
	draw_polyline(PackedVector2Array([Vector2(-71.0, -157.0), Vector2(0.0, -207.0), Vector2(71.0, -157.0)]), Color("#78473f"), 3.0)
	_draw_rect(Rect2(39.0, -211.0, 17.0, 42.0), Color("#845847"), Color("#654839"), 2.0)
	_draw_rect(Rect2(-51.0, -91.0, 38.0, 37.0), Color("#a7c9c4"), Color("#f1e2c4"), 5.0)
	_draw_rect(Rect2(13.0, -91.0, 38.0, 37.0), Color("#a7c9c4"), Color("#f1e2c4"), 5.0)
	draw_line(Vector2(-32.0, -90.0), Vector2(-32.0, -55.0), Color("#f2e5ca"), 2.0)
	draw_line(Vector2(32.0, -90.0), Vector2(32.0, -55.0), Color("#f2e5ca"), 2.0)
	_draw_rect(Rect2(-12.0, -70.0, 27.0, 55.0), Color("#84624d"), Color("#654b3e"), 2.0)
	draw_circle(Vector2(8.0, -42.0), 2.0, Color("#f1cf7c"))
	_draw_rect(Rect2(-20.0, -16.0, 43.0, 7.0), Color("#bfa275"), Color("#765c48"), 1.5)
	draw_line(Vector2(-75.0, -111.0), Vector2(75.0, -111.0), Color("#f0e0bf"), 2.0)

func _draw_school() -> void:
	_draw_rect(Rect2(-71.0, -108.0, 142.0, 94.0), Color("#e5d6ab"), Color("#6c6554"), 3.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-82.0, -105.0), Vector2(-82.0, -137.0), Vector2(0.0, -171.0),
		Vector2(82.0, -137.0), Vector2(82.0, -105.0)
	]), Color("#617b69"))
	draw_polyline(PackedVector2Array([Vector2(-82.0, -137.0), Vector2(0.0, -171.0), Vector2(82.0, -137.0)]), Color("#435b4e"), 3.0)
	_draw_rect(Rect2(-14.0, -101.0, 29.0, 80.0), Color("#78836c"), Color("#5c6557"), 2.0)
	for x in [-55.0, 39.0]:
		for y in [-96.0, -55.0]:
			_draw_rect(Rect2(x, y, 25.0, 25.0), Color("#9fc5c4"), Color("#f6edcf"), 4.0)
			draw_line(Vector2(x + 12.5, y + 1.0), Vector2(x + 12.5, y + 24.0), Color("#f6edcf"), 2.0)
	_draw_rect(Rect2(-10.0, -179.0, 20.0, 20.0), Color("#f0e4c6"), Color("#6c6554"), 2.0)
	draw_arc(Vector2(0.0, -169.0), 7.0, 0.0, TAU, 12, Color("#bd7657"), 2.0)
	_draw_rect(Rect2(-21.0, -17.0, 42.0, 7.0), Color("#b4a071"), Color("#6c6554"), 1.5)

func _draw_supermarket() -> void:
	_draw_rect(Rect2(-73.0, -109.0, 146.0, 95.0), Color("#eee0c0"), Color("#6c5947"), 3.0)
	_draw_rect(Rect2(-78.0, -117.0, 156.0, 18.0), Color("#f5ebd1"), Color("#6c5947"), 2.0)
	var stripe_colors: Array[Color] = [Color("#bd7158"), Color("#f2e2bf"), Color("#83a89f"), Color("#f2e2bf"), Color("#bd7158"), Color("#f2e2bf")]
	for index in range(stripe_colors.size()):
		_draw_rect(Rect2(-76.0 + index * 25.5, -135.0, 25.5, 18.0), stripe_colors[index], Color("#6c5947"), 1.0)
	_draw_rect(Rect2(-60.0, -95.0, 39.0, 36.0), Color("#9fc6c4"), Color("#fbf1d6"), 5.0)
	_draw_rect(Rect2(26.0, -95.0, 34.0, 73.0), Color("#83664f"), Color("#6c5947"), 2.0)
	_draw_rect(Rect2(-10.0, -89.0, 25.0, 33.0), Color("#d49b65"), Color("#f4e7c9"), 3.0)
	draw_line(Vector2(-57.0, -78.0), Vector2(-23.0, -78.0), Color("#f2e8ce"), 2.0)
	_draw_rect(Rect2(-17.0, -17.0, 38.0, 7.0), Color("#b99367"), Color("#6c5947"), 1.5)

func _draw_gym() -> void:
	_draw_rect(Rect2(-73.0, -111.0, 146.0, 98.0), Color("#a8c2b7"), Color("#526b69"), 3.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-82.0, -108.0), Vector2(-73.0, -153.0), Vector2(0.0, -174.0),
		Vector2(73.0, -153.0), Vector2(82.0, -108.0)
	]), Color("#526f78"))
	draw_polyline(PackedVector2Array([Vector2(-73.0, -153.0), Vector2(0.0, -174.0), Vector2(73.0, -153.0)]), Color("#3d5963"), 3.0)
	_draw_rect(Rect2(-58.0, -99.0, 35.0, 43.0), Color("#89b8be"), Color("#e4e1ca"), 5.0)
	_draw_rect(Rect2(23.0, -99.0, 35.0, 43.0), Color("#89b8be"), Color("#e4e1ca"), 5.0)
	_draw_rect(Rect2(-15.0, -87.0, 31.0, 72.0), Color("#526b69"), Color("#3d5556"), 2.0)
	draw_circle(Vector2(0.0, -151.0), 11.0, Color("#e7ad70"))
	draw_arc(Vector2(0.0, -151.0), 11.0, 0.0, TAU, 20, Color("#8d5f48"), 1.5)
	draw_line(Vector2(-11.0, -151.0), Vector2(11.0, -151.0), Color("#8d5f48"), 1.0)
	draw_line(Vector2(0.0, -162.0), Vector2(0.0, -140.0), Color("#8d5f48"), 1.0)
	_draw_rect(Rect2(-19.0, -17.0, 38.0, 7.0), Color("#8ca59a"), Color("#526b69"), 1.5)

func _draw_default() -> void:
	_draw_rect(Rect2(-65.0, -100.0, 130.0, 86.0), Color("#ddd0ad"), Color("#645848"), 3.0)

func _draw_sign(text: String) -> void:
	_draw_rect(Rect2(-61.0, -127.0, 122.0, 18.0), Color("#f5e7c5"), Color("#6e5948"), 1.5)
	draw_string(ThemeDB.fallback_font, Vector2(-56.0, -114.0), text, HORIZONTAL_ALIGNMENT_CENTER, 112.0, 12, Color("#35444a"))

func _draw_rect(rect: Rect2, fill: Color, outline: Color, outline_width: float = 2.0) -> void:
	draw_rect(rect, fill)
	draw_rect(rect, outline, false, outline_width)

func _draw_ellipse(center: Vector2, radius_x: float, radius_y: float, color: Color) -> void:
	var points := PackedVector2Array()
	for index in range(24):
		var angle := TAU * float(index) / 24.0
		points.append(center + Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
	draw_colored_polygon(points, color)
