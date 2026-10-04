class_name NpcActor
extends Node2D

@export var display_name: String = "Villager"
@export_multiline var dialogue_text: String = "Hello!"
@export var story_actor_id: StringName = &"npc"
@export var opens_battle_ui_on_interaction: bool = false
@export var portrait_texture: Texture2D
@export var idle_sheet: Texture2D
@export var walk_sheet: Texture2D
@export var route_offsets: PackedVector2Array = PackedVector2Array()
@export var walk_speed: float = 64.0
@export var pause_seconds: float = 0.6

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

var _route_origin: Vector2
var _next_waypoint: int = 1
var _pause_remaining: float = 0.0
var _facing: String = "down"

func _ready() -> void:
	add_to_group("npcs")
	_route_origin = position
	_build_sprite_frames()
	_sprite.play("idle_down")

func _process(delta: float) -> void:
	if route_offsets.size() < 2 or not is_visible_in_tree():
		return
	if _pause_remaining > 0.0:
		_pause_remaining -= delta
		_play_animation("idle_")
		return
	var target: Vector2 = _route_origin + route_offsets[_next_waypoint]
	var movement: Vector2 = target - position
	if movement.length_squared() <= 1.0:
		position = target
		_next_waypoint = (_next_waypoint + 1) % route_offsets.size()
		_pause_remaining = pause_seconds
		_play_animation("idle_")
		return
	var step: Vector2 = movement.normalized() * minf(walk_speed * delta, movement.length())
	position += step
	if absf(step.x) > absf(step.y):
		_facing = "right" if step.x > 0.0 else "left"
	else:
		_facing = "down" if step.y > 0.0 else "up"
	_play_animation("walk_")

func get_interaction_anchor() -> Vector2:
	return global_position + Vector2(0.0, -38.0)

func _play_animation(prefix: String) -> void:
	var animation: String = prefix + _facing
	if _sprite.animation != animation:
		_sprite.play(animation)

func _build_sprite_frames() -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var directions: PackedStringArray = ["down", "up", "left", "right"]
	for column in range(directions.size()):
		var idle_name: String = "idle_" + directions[column]
		frames.add_animation(idle_name)
		frames.add_frame(idle_name, _atlas_frame(idle_sheet, column, 0))
		var walk_name: String = "walk_" + directions[column]
		frames.add_animation(walk_name)
		frames.set_animation_loop(walk_name, true)
		frames.set_animation_speed(walk_name, 8.0)
		for row in range(4):
			frames.add_frame(walk_name, _atlas_frame(walk_sheet, column, row))
	_sprite.sprite_frames = frames

func _atlas_frame(texture: Texture2D, column: int, row: int) -> AtlasTexture:
	var frame := AtlasTexture.new()
	frame.atlas = texture
	frame.region = Rect2(column * 16, row * 16, 16, 16)
	return frame
