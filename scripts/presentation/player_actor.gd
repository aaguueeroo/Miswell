class_name PlayerActor
extends CharacterBody2D

signal interact_requested

@export var move_speed: float = 185.0
var controls_enabled: bool = true
var _touch_direction: Vector2 = Vector2.ZERO
var _facing: String = "down"

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

const PLAYER_ASSET_PATH := "res://assets/characters/player/boy/SeparateAnim/"

func _ready() -> void:
	_build_sprite_frames()
	_sprite.play("idle_down")

func set_controls_enabled(enabled: bool) -> void:
	controls_enabled = enabled
	if not controls_enabled:
		_touch_direction = Vector2.ZERO
		velocity = Vector2.ZERO

func set_touch_direction(direction: Vector2) -> void:
	_touch_direction = direction.normalized()

func _physics_process(_delta: float) -> void:
	if not controls_enabled:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	var direction := Vector2.ZERO
	direction.x = float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)) - float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT))
	direction.y = float(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)) - float(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP))
	direction += _touch_direction
	velocity = direction.normalized() * move_speed
	_update_character_animation(direction)
	move_and_slide()
	var margin := 20.0
	global_position.x = clampf(global_position.x, margin, VillageMapConfig.WORLD_SIZE.x - margin)
	global_position.y = clampf(global_position.y, margin, VillageMapConfig.WORLD_SIZE.y - margin)

func _unhandled_input(event: InputEvent) -> void:
	if not controls_enabled:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
		interact_requested.emit()
		get_viewport().set_input_as_handled()

func _build_sprite_frames() -> void:
	var idle_texture := load(PLAYER_ASSET_PATH + "Idle.png") as Texture2D
	var walk_texture := load(PLAYER_ASSET_PATH + "Walk.png") as Texture2D
	var sprite_frames := SpriteFrames.new()
	sprite_frames.remove_animation("default")
	var directions: PackedStringArray = ["down", "up", "left", "right"]
	for column in range(directions.size()):
		var idle_name: String = "idle_" + directions[column]
		sprite_frames.add_animation(idle_name)
		sprite_frames.set_animation_loop(idle_name, true)
		sprite_frames.add_frame(idle_name, _atlas_frame(idle_texture, column, 0))
		var walk_name: String = "walk_" + directions[column]
		sprite_frames.add_animation(walk_name)
		sprite_frames.set_animation_loop(walk_name, true)
		sprite_frames.set_animation_speed(walk_name, 8.0)
		for row in range(4):
			sprite_frames.add_frame(walk_name, _atlas_frame(walk_texture, column, row))
	_sprite.sprite_frames = sprite_frames

func _atlas_frame(texture: Texture2D, column: int, row: int) -> AtlasTexture:
	var frame := AtlasTexture.new()
	frame.atlas = texture
	frame.region = Rect2(column * 16, row * 16, 16, 16)
	return frame

func _update_character_animation(direction: Vector2) -> void:
	var moving := direction.length_squared() > 0.001
	if moving:
		if absf(direction.x) > absf(direction.y):
			_facing = "right" if direction.x > 0.0 else "left"
		else:
			_facing = "down" if direction.y > 0.0 else "up"
	var animation: String = ("walk_" if moving else "idle_") + _facing
	if _sprite.animation != animation:
		_sprite.play(animation)
