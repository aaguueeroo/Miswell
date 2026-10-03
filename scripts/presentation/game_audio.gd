class_name GameAudio
extends Node

const FOOTSTEP_SETS: Dictionary = {
	&"default": [
		preload("res://assets/audio/filtered/footsteps/default/footstep00.ogg"),
		preload("res://assets/audio/filtered/footsteps/default/footstep01.ogg"),
		preload("res://assets/audio/filtered/footsteps/default/footstep02.ogg"),
		preload("res://assets/audio/filtered/footsteps/default/footstep03.ogg"),
		preload("res://assets/audio/filtered/footsteps/default/footstep04.ogg"),
		preload("res://assets/audio/filtered/footsteps/default/footstep05.ogg"),
		preload("res://assets/audio/filtered/footsteps/default/footstep06.ogg"),
		preload("res://assets/audio/filtered/footsteps/default/footstep07.ogg"),
		preload("res://assets/audio/filtered/footsteps/default/footstep08.ogg"),
		preload("res://assets/audio/filtered/footsteps/default/footstep09.ogg"),
	],
	&"carpet": [
		preload("res://assets/audio/filtered/footsteps/carpet/footstep_carpet_000.ogg"),
		preload("res://assets/audio/filtered/footsteps/carpet/footstep_carpet_001.ogg"),
		preload("res://assets/audio/filtered/footsteps/carpet/footstep_carpet_002.ogg"),
		preload("res://assets/audio/filtered/footsteps/carpet/footstep_carpet_003.ogg"),
		preload("res://assets/audio/filtered/footsteps/carpet/footstep_carpet_004.ogg"),
	],
	&"concrete": [
		preload("res://assets/audio/filtered/footsteps/concrete/footstep_concrete_000.ogg"),
		preload("res://assets/audio/filtered/footsteps/concrete/footstep_concrete_001.ogg"),
		preload("res://assets/audio/filtered/footsteps/concrete/footstep_concrete_002.ogg"),
		preload("res://assets/audio/filtered/footsteps/concrete/footstep_concrete_003.ogg"),
		preload("res://assets/audio/filtered/footsteps/concrete/footstep_concrete_004.ogg"),
	],
	&"grass": [
		preload("res://assets/audio/filtered/footsteps/grass/footstep_grass_000.ogg"),
		preload("res://assets/audio/filtered/footsteps/grass/footstep_grass_001.ogg"),
		preload("res://assets/audio/filtered/footsteps/grass/footstep_grass_002.ogg"),
		preload("res://assets/audio/filtered/footsteps/grass/footstep_grass_003.ogg"),
		preload("res://assets/audio/filtered/footsteps/grass/footstep_grass_004.ogg"),
	],
	&"wood": [
		preload("res://assets/audio/filtered/footsteps/wood/footstep_wood_000.ogg"),
		preload("res://assets/audio/filtered/footsteps/wood/footstep_wood_001.ogg"),
		preload("res://assets/audio/filtered/footsteps/wood/footstep_wood_002.ogg"),
		preload("res://assets/audio/filtered/footsteps/wood/footstep_wood_003.ogg"),
		preload("res://assets/audio/filtered/footsteps/wood/footstep_wood_004.ogg"),
	],
}

const UI_CLICKS: Array = [
	preload("res://assets/audio/filtered/gui/click1.ogg"),
	preload("res://assets/audio/filtered/gui/click2.ogg"),
	preload("res://assets/audio/filtered/gui/click3.ogg"),
	preload("res://assets/audio/filtered/gui/click4.ogg"),
	preload("res://assets/audio/filtered/gui/click5.ogg"),
]
const UI_HOVER: AudioStream = preload("res://assets/audio/filtered/gui/rollover1.ogg")

var _footstep_indices: Dictionary = {}
var _random := RandomNumberGenerator.new()
var _footstep_player: AudioStreamPlayer
var _ui_click_player: AudioStreamPlayer
var _ui_hover_player: AudioStreamPlayer

func _ready() -> void:
	_random.randomize()
	_footstep_player = AudioStreamPlayer.new()
	_footstep_player.name = "Footsteps"
	_footstep_player.max_polyphony = 4
	add_child(_footstep_player)
	_ui_click_player = AudioStreamPlayer.new()
	_ui_click_player.name = "UIClicks"
	add_child(_ui_click_player)
	_ui_hover_player = AudioStreamPlayer.new()
	_ui_hover_player.name = "UIHover"
	add_child(_ui_hover_player)

func play_footstep(surface: StringName) -> void:
	var surface_key: StringName = surface if FOOTSTEP_SETS.has(surface) else &"default"
	var samples: Array = FOOTSTEP_SETS[surface_key]
	if samples.is_empty():
		return
	var sample_index := int(_footstep_indices.get(surface_key, 0))
	_footstep_player.stream = samples[sample_index] as AudioStream
	_footstep_player.play()
	_footstep_indices[surface_key] = (sample_index + 1) % samples.size()

func play_ui_click() -> void:
	var sample_index := _random.randi_range(0, UI_CLICKS.size() - 1)
	_ui_click_player.stream = UI_CLICKS[sample_index] as AudioStream
	_ui_click_player.play()

func play_ui_hover() -> void:
	_ui_hover_player.stream = UI_HOVER
	_ui_hover_player.play()
