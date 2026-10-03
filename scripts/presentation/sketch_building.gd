class_name SketchBuilding
extends Node2D

@export var place_name: String = "House"
@export var wall_color: Color = Color("#d9c9a7")
@export var roof_color: Color = Color("#87927c")
@export var building_size: Vector2 = Vector2(112.0, 82.0)

func _draw() -> void:
	var half_width := building_size.x * 0.5
	var wall_height := building_size.y * 0.58
	var top := -building_size.y
	_draw_shadow_oval(Vector2(0.0, 0.0), half_width * 0.82, 11.0, Color(0.16, 0.20, 0.17, 0.17))
	var wall := Rect2(-half_width, top + 26.0, building_size.x, wall_height)
	draw_rect(wall, wall_color)
	draw_rect(wall, Color("#6d6755"), false, 2.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-half_width - 7.0, top + 28.0),
		Vector2(0.0, top),
		Vector2(half_width + 7.0, top + 28.0),
		Vector2(half_width, top + 35.0),
		Vector2(0.0, top + 13.0),
		Vector2(-half_width, top + 35.0)
	]), roof_color)
	draw_polyline(PackedVector2Array([
		Vector2(-half_width - 7.0, top + 28.0),
		Vector2(0.0, top),
		Vector2(half_width + 7.0, top + 28.0)
	]), Color("#626451"), 2.0)
	draw_rect(Rect2(-half_width * 0.58, top + 42.0, 20.0, 18.0), Color("#9fc0bc"))
	draw_rect(Rect2(half_width * 0.25, top + 42.0, 20.0, 18.0), Color("#9fc0bc"))
	draw_rect(Rect2(-9.0, top + wall_height + 3.0, 18.0, 26.0), Color("#896c55"))
	draw_string(ThemeDB.fallback_font, Vector2(-92.0, 21.0), place_name.to_upper(), HORIZONTAL_ALIGNMENT_CENTER, 184.0, 10, Color("#52624e"))

func _draw_shadow_oval(center: Vector2, radius_x: float, radius_y: float, color: Color) -> void:
	var points := PackedVector2Array()
	for index in range(20):
		var angle := TAU * float(index) / 20.0
		points.append(center + Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
	draw_colored_polygon(points, color)

