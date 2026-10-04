class_name PlayerActor
extends CharacterBody2D

signal interact_requested
signal footstep_requested

@export var move_speed: float = 185.0
var controls_enabled: bool = true
var _touch_direction: Vector2 = Vector2.ZERO
var _facing: String = "down"
var _is_walking: bool = false
var _suppress_footstep_events: bool = false
var _world_bounds: Vector2 = VillageMapConfig.WORLD_SIZE

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _camera: Camera2D = $Camera2D

const PLAYER_ASSET_PATH := "res://assets/characters/player/boy/SeparateAnim/"
const BASE_WALK_SPEED: float = 185.0

func _ready() -> void:
	_build_sprite_frames()
	_sprite.frame_changed.connect(_on_sprite_frame_changed)
	_sprite.play("idle_down")

func set_controls_enabled(enabled: bool) -> void:
	controls_enabled = enabled
	if not controls_enabled:
		_touch_direction = Vector2.ZERO
		velocity = Vector2.ZERO

func set_touch_direction(direction: Vector2) -> void:
	_touch_direction = direction.normalized()

func set_world_bounds(world_size: Vector2) -> void:
	_world_bounds = world_size
	_camera.limit_right = roundi(world_size.x)
	_camera.limit_bottom = roundi(world_size.y)
	_camera.reset_smoothing()

func teleport_to(world_position: Vector2, world_size: Vector2) -> void:
	set_world_bounds(world_size)
	global_position = world_position
	_camera.reset_smoothing()
	# The world is paused during area transitions, so update the visible scroll now.
	_camera.force_update_scroll()

func _resolve_cardinal_direction(direction: Vector2) -> Vector2:
	if absf(direction.x) > absf(direction.y):
		return Vector2(signf(direction.x), 0.0)
	if absf(direction.y) > 0.0:
		return Vector2(0.0, signf(direction.y))
	return Vector2.ZERO

func _physics_process(_delta: float) -> void:
	if not controls_enabled:
		velocity = Vector2.ZERO
		move_and_slide()
		_update_character_animation(Vector2.ZERO, 0.0)
		return
	var direction := Vector2.ZERO
	direction.x = float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)) - float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT))
	direction.y = float(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)) - float(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP))
	direction += _touch_direction
	var intended_direction := _resolve_cardinal_direction(direction)
	velocity = intended_direction * move_speed
	move_and_slide()
	var margin := 20.0
	global_position.x = clampf(global_position.x, margin, _world_bounds.x - margin)
	global_position.y = clampf(global_position.y, margin, _world_bounds.y - margin)
	# Collision recovery and sliding must not change facing or walking cadence.
	_update_character_animation(intended_direction, move_speed)

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

func _update_character_animation(direction: Vector2, movement_speed: float) -> void:
	var moving := movement_speed > 0.001 and direction.length_squared() > 0.001
	if moving:
		if absf(direction.x) > absf(direction.y):
			_facing = "right" if direction.x > 0.0 else "left"
		else:
			_facing = "down" if direction.y > 0.0 else "up"
	var animation: String = ("walk_" if moving else "idle_") + _facing
	_sprite.speed_scale = movement_speed / BASE_WALK_SPEED if moving else 1.0
	if _sprite.animation != animation:
		var preserve_walk_phase := moving and _is_walking
		var current_frame := _sprite.frame
		var current_progress := _sprite.frame_progress
		_suppress_footstep_events = true
		_sprite.play(animation)
		if preserve_walk_phase:
			_sprite.set_frame_and_progress(current_frame, current_progress)
		elif moving:
			_sprite.set_frame_and_progress(0, 0.0)
		_suppress_footstep_events = false
	if moving and not _is_walking:
		_is_walking = true
		# Frame 0 is the first planted-foot pose, so don't wait a whole stride
		# before the first sound after the player starts moving.
		footstep_requested.emit()
	elif not moving:
		_is_walking = false

func _on_sprite_frame_changed() -> void:
	if not _is_walking or _suppress_footstep_events:
		return
	if not String(_sprite.animation).begins_with("walk_"):
		return
	if _sprite.frame == 0 or _sprite.frame == 2:
		footstep_requested.emit()
