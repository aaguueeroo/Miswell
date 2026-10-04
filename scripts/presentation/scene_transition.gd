class_name SceneTransition
extends CanvasLayer

const HUD_FONT: FontFile = preload("res://assets/fonts/Kenney/Fonts/Kenney Mini.ttf")

var _screen: Control
var _heading: Label
var _active: bool = false

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_screen = Control.new()
	_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_screen.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_screen)
	var veil := ColorRect.new()
	veil.color = Color("#292232")
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_screen.add_child(veil)
	_heading = Label.new()
	_heading.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_heading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_heading.add_theme_font_override("font", HUD_FONT)
	_heading.add_theme_font_size_override("font_size", 28)
	_heading.add_theme_color_override("font_color", Color("#f1ddbc"))
	_heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_screen.add_child(_heading)
	_screen.visible = false

func fade_through(title: String, swap_scene: Callable) -> void:
	if _active:
		return
	_active = true
	_heading.text = title
	_screen.modulate.a = 0.0
	_screen.visible = true
	var fade_out := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fade_out.tween_property(_screen, "modulate:a", 1.0, 0.28).set_trans(Tween.TRANS_SINE)
	await fade_out.finished
	swap_scene.call()
	var fade_in := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fade_in.tween_interval(0.12)
	fade_in.tween_property(_screen, "modulate:a", 0.0, 0.36).set_trans(Tween.TRANS_SINE)
	await fade_in.finished
	_screen.visible = false
	_active = false
