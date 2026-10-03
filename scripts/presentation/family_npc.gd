class_name FamilyNpc
extends Node2D

func get_interaction_anchor() -> Vector2:
	return global_position + Vector2(0.0, -52.0)

func _draw() -> void:
	draw_circle(Vector2(0, 8), 17.0, Color(0.12, 0.19, 0.23, 0.24))
	draw_rect(Rect2(-13.0, -7.0, 26.0, 31.0), Color("#b47862"))
	draw_circle(Vector2(0, -16), 10.0, Color("#dbad88"))
	draw_circle(Vector2(-3, -17), 1.2, Color("#3c302d"))
	draw_circle(Vector2(3, -17), 1.2, Color("#3c302d"))
	draw_arc(Vector2(0.0, -14.0), 4.0, 0.35, 2.8, 8, Color("#835449"), 1.0)
	draw_circle(Vector2(0, -39), 4.0, Color("#f0d889"))
