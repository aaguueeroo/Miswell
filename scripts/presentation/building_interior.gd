class_name BuildingInterior
extends Node2D

signal exit_requested(building_id: StringName)

@export var building_id: StringName = &""
@export var display_name: String = "Interior"
@export var world_size: Vector2 = Vector2(960.0, 1088.0)
@export var entry_position: Vector2 = Vector2(480.0, 992.0)
@export var floor_surface: StringName = &"wood"

@onready var _exit_area: Area2D = $ExitArea

func _ready() -> void:
	_exit_area.body_entered.connect(_on_exit_body_entered)

func get_footstep_surface(world_position: Vector2) -> StringName:
	if building_id == &"school" and world_position.y > 576.0 and world_position.x > 800.0:
		return &"carpet"
	return floor_surface

func get_action_spots() -> Array[InteriorAction]:
	var result: Array[InteriorAction] = []
	for child in get_children():
		var action := child as InteriorAction
		if action != null:
			result.append(action)
	return result

func _on_exit_body_entered(body: Node2D) -> void:
	if body is PlayerActor:
		exit_requested.emit(building_id)
