class_name InteriorAction
extends Node2D

const HUD_FONT: FontFile = preload("res://assets/fonts/Kenney/Fonts/Kenney Mini.ttf")

@export var location_id: StringName = &""
@export var display_name: String = "Activity"

func get_interaction_anchor() -> Vector2:
	return global_position + Vector2(0.0, -20.0)

func _draw() -> void:
	draw_rect(Rect2(-24.0, -10.0, 48.0, 20.0), Color("#4b3945"))
	draw_rect(Rect2(-22.0, -8.0, 44.0, 16.0), Color("#e7d3a8"))
	draw_string(HUD_FONT, Vector2(-20.0, 4.0), display_name, HORIZONTAL_ALIGNMENT_CENTER, 40.0, 11, Color("#4d3b29"))
