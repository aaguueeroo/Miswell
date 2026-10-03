class_name BattleScene
extends CanvasLayer

const PANEL_BEIGE: Texture2D = preload("res://assets/gui/kenney_ui-pack-rpg-expansion/PNG/panel_beige.png")
const PANEL_INSET_BROWN: Texture2D = preload("res://assets/gui/kenney_ui-pack-rpg-expansion/PNG/panelInset_brown.png")
const BUTTON_LONG_BEIGE: Texture2D = preload("res://assets/gui/kenney_ui-pack-rpg-expansion/PNG/buttonLong_beige.png")
const BUTTON_LONG_BROWN: Texture2D = preload("res://assets/gui/kenney_ui-pack-rpg-expansion/PNG/buttonLong_brown.png")
const BUTTON_LONG_BROWN_PRESSED: Texture2D = preload("res://assets/gui/kenney_ui-pack-rpg-expansion/PNG/buttonLong_brown_pressed.png")
const HUD_FONT: FontFile = preload("res://assets/fonts/Kenney/Fonts/Kenney Mini.ttf")

signal choice_selected(choice_id: StringName)
signal close_requested
signal ui_click_requested
signal ui_hover_requested

var _title: Label
var _opponent: Label
var _player: Label
var _prompt: Label
var _choices: VBoxContainer
var _result_message: Label
var _result_button: Button

func _ready() -> void:
	layer = 10
	_build_scene_ui()

func show_encounter(view: Dictionary) -> void:
	_title.text = str(view.get("title", "Encounter"))
	_opponent.text = str(view.get("opponent_name", "Opponent"))
	_player.text = str(view.get("player_name", "You"))
	_prompt.text = str(view.get("body", ""))
	_clear_choices()
	for resource in view.get("choices", []):
		var choice := resource as EncounterChoiceDefinition
		if choice == null:
			continue
		var button := Button.new()
		button.text = choice.label + "\n" + choice.description
		button.custom_minimum_size.y = 64.0
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_apply_button_style(button)
		button.mouse_entered.connect(_emit_ui_hover_requested.bind(button))
		button.pressed.connect(_emit_ui_click_requested)
		button.pressed.connect(_emit_choice.bind(choice.choice_id))
		_choices.add_child(button)
	_choices.visible = true
	_result_message.visible = false
	_result_button.visible = false

func show_result(title: String, message: String) -> void:
	_title.text = title
	_prompt.visible = false
	_choices.visible = false
	_result_message.text = message
	_result_message.visible = true
	_result_button.text = "Continue"
	_result_button.visible = true

func _build_scene_ui() -> void:
	var root_control := Control.new()
	root_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_control.mouse_filter = Control.MOUSE_FILTER_STOP
	root_control.theme = _make_theme()
	add_child(root_control)

	var backdrop := ColorRect.new()
	backdrop.color = Color(0.10, 0.075, 0.055, 0.86)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_control.add_child(backdrop)

	var title_panel := _make_panel(PANEL_BEIGE)
	title_panel.anchor_left = 0.05
	title_panel.anchor_right = 0.95
	title_panel.anchor_top = 0.025
	title_panel.anchor_bottom = 0.10
	root_control.add_child(title_panel)
	_title = Label.new()
	_title.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 22)
	title_panel.add_child(_title)

	var opponent_panel := _make_panel(PANEL_INSET_BROWN)
	opponent_panel.anchor_left = 0.56
	opponent_panel.anchor_right = 0.95
	opponent_panel.anchor_top = 0.11
	opponent_panel.anchor_bottom = 0.25
	root_control.add_child(opponent_panel)
	_opponent = Label.new()
	_opponent.text = "Opponent"
	_opponent.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_opponent.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_opponent.add_theme_color_override("font_color", Color("#fff4df"))
	_opponent.add_theme_font_size_override("font_size", 16)
	_opponent.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	opponent_panel.add_child(_opponent)

	var prompt_panel := _make_panel(PANEL_BEIGE)
	prompt_panel.anchor_left = 0.05
	prompt_panel.anchor_right = 0.95
	prompt_panel.anchor_top = 0.31
	prompt_panel.anchor_bottom = 0.48
	root_control.add_child(prompt_panel)
	_prompt = Label.new()
	_prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_prompt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_prompt.add_theme_font_size_override("font_size", 16)
	_prompt.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	prompt_panel.add_child(_prompt)

	var player_panel := _make_panel(PANEL_INSET_BROWN)
	player_panel.anchor_left = 0.05
	player_panel.anchor_right = 0.47
	player_panel.anchor_top = 0.58
	player_panel.anchor_bottom = 0.72
	root_control.add_child(player_panel)
	_player = Label.new()
	_player.text = "You"
	_player.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_player.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_player.add_theme_color_override("font_color", Color("#fff4df"))
	_player.add_theme_font_size_override("font_size", 16)
	_player.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	player_panel.add_child(_player)

	var options_panel := _make_panel(PANEL_BEIGE)
	options_panel.anchor_left = 0.05
	options_panel.anchor_right = 0.95
	options_panel.anchor_top = 0.75
	options_panel.anchor_bottom = 0.98
	root_control.add_child(options_panel)
	var options_margin := MarginContainer.new()
	options_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	options_panel.add_child(options_margin)
	_choices = VBoxContainer.new()
	_choices.add_theme_constant_override("separation", 8)
	options_margin.add_child(_choices)
	_result_message = Label.new()
	_result_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_result_message.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_result_message.add_theme_font_size_override("font_size", 16)
	options_margin.add_child(_result_message)
	_result_button = Button.new()
	_result_button.custom_minimum_size.y = 48.0
	_apply_button_style(_result_button)
	_result_button.mouse_entered.connect(_emit_ui_hover_requested.bind(_result_button))
	_result_button.pressed.connect(_emit_ui_click_requested)
	_result_button.pressed.connect(func() -> void: close_requested.emit())
	options_margin.add_child(_result_button)

func _make_theme() -> Theme:
	var battle_theme := Theme.new()
	battle_theme.default_font = HUD_FONT
	battle_theme.default_font_size = 15
	battle_theme.set_color("font_color", "Label", Color("#4d3b29"))
	battle_theme.set_color("font_color", "Button", Color("#4d3b29"))
	battle_theme.set_color("font_hover_color", "Button", Color("#fff4df"))
	battle_theme.set_color("font_pressed_color", "Button", Color("#fff4df"))
	battle_theme.set_color("font_disabled_color", "Button", Color("#887a66"))
	return battle_theme

func _make_panel(texture: Texture2D) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _texture_stylebox(texture, 12.0, 14.0))
	return panel

func _texture_stylebox(texture: Texture2D, edge_margin: float, content_margin: float) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = edge_margin
	style.texture_margin_right = edge_margin
	style.texture_margin_top = edge_margin
	style.texture_margin_bottom = edge_margin
	style.content_margin_left = content_margin
	style.content_margin_right = content_margin
	style.content_margin_top = content_margin
	style.content_margin_bottom = content_margin
	return style

func _apply_button_style(button: Button) -> void:
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_stylebox_override("normal", _texture_stylebox(BUTTON_LONG_BEIGE, 12.0, 8.0))
	button.add_theme_stylebox_override("hover", _texture_stylebox(BUTTON_LONG_BROWN, 12.0, 8.0))
	button.add_theme_stylebox_override("pressed", _texture_stylebox(BUTTON_LONG_BROWN_PRESSED, 12.0, 8.0))
	button.add_theme_color_override("font_color", Color("#4d3b29"))
	button.add_theme_color_override("font_hover_color", Color("#fff4df"))
	button.add_theme_color_override("font_pressed_color", Color("#fff4df"))

func _clear_choices() -> void:
	for child in _choices.get_children():
		child.queue_free()

func _emit_choice(choice_id: StringName) -> void:
	choice_selected.emit(choice_id)

func _emit_ui_click_requested() -> void:
	ui_click_requested.emit()

func _emit_ui_hover_requested(button: Button) -> void:
	if button.disabled:
		return
	ui_hover_requested.emit()
