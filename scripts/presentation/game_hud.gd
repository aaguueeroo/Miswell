class_name GameHUD
extends CanvasLayer

const PANEL_BEIGE: Texture2D = preload("res://assets/gui/kenney_ui-pack-rpg-expansion/PNG/panel_beige.png")
const PANEL_BROWN: Texture2D = preload("res://assets/gui/kenney_ui-pack-rpg-expansion/PNG/panel_brown.png")
const PANEL_INSET_BEIGE: Texture2D = preload("res://assets/gui/kenney_ui-pack-rpg-expansion/PNG/panelInset_beige.png")
const PANEL_INSET_BROWN: Texture2D = preload("res://assets/gui/kenney_ui-pack-rpg-expansion/PNG/panelInset_brown.png")
const BUTTON_LONG_BEIGE: Texture2D = preload("res://assets/gui/kenney_ui-pack-rpg-expansion/PNG/buttonLong_beige.png")
const BUTTON_LONG_BROWN: Texture2D = preload("res://assets/gui/kenney_ui-pack-rpg-expansion/PNG/buttonLong_brown.png")
const BUTTON_LONG_BROWN_PRESSED: Texture2D = preload("res://assets/gui/kenney_ui-pack-rpg-expansion/PNG/buttonLong_brown_pressed.png")
const BUTTON_SQUARE_BEIGE: Texture2D = preload("res://assets/gui/kenney_ui-pack-rpg-expansion/PNG/buttonSquare_beige.png")
const BUTTON_SQUARE_BROWN: Texture2D = preload("res://assets/gui/kenney_ui-pack-rpg-expansion/PNG/buttonSquare_brown.png")
const BUTTON_SQUARE_BROWN_PRESSED: Texture2D = preload("res://assets/gui/kenney_ui-pack-rpg-expansion/PNG/buttonSquare_brown_pressed.png")
const BUTTON_SQUARE_BLUE: Texture2D = preload("res://assets/gui/kenney_ui-pack-rpg-expansion/PNG/buttonSquare_blue.png")
const ARROW_RIGHT: Texture2D = preload("res://assets/gui/kenney_ui-pack-rpg-expansion/PNG/arrowBrown_right.png")
const ARROW_RIGHT_HOVER: Texture2D = preload("res://assets/gui/kenney_ui-pack-rpg-expansion/PNG/arrowBeige_right.png")
const BAR_BACKGROUND: Texture2D = preload("res://assets/gui/kenney_ui-pack-rpg-expansion/PNG/barBack_horizontalMid.png")
const BAR_GREEN: Texture2D = preload("res://assets/gui/kenney_ui-pack-rpg-expansion/PNG/barGreen_horizontalMid.png")
const HUD_FONT: FontFile = preload("res://assets/fonts/Kenney/Fonts/Kenney Mini.ttf")
const INTERACTION_PROMPT_E: Texture2D = preload("res://assets/gui/kenney_input-prompts-pixel/e_key.png")
const MISWELL_LOGO: Texture2D = preload("res://assets/gui/miswell_logo.png")

signal message_action_requested
signal restart_requested
signal touch_direction_changed(direction: Vector2)
signal ui_click_requested
signal ui_hover_requested
signal new_game_requested
signal continue_requested
signal slot_selected(slot_id: StringName)
signal overwrite_confirmed
signal back_requested
signal pause_requested
signal problem_graph_requested
signal resume_requested
signal save_requested
signal time_speed_requested(multiplier: int)

var _root: Control
var _clock_label: Label
var _anxiety_label: Label
var _anxiety_bar: ProgressBar
var _trust_label: Label
var _effect_label: Label
var _notice_label: Label
var _bottom_panel: PanelContainer
var _bottom_content: VBoxContainer
var _panel_heading: Label
var _panel_body: Label
var _actions: BoxContainer
var _context_action: TextureRect
var _context_anchor: Vector2 = Vector2.ZERO
var _dpad: PanelContainer
var _touch_pressed: Dictionary = {}
var _notice_seconds: float = 0.0
var _panel_mode: String = "exploration"
var _mobile_mode: bool = false
var _context_elapsed: float = 0.0
var _bottom_height: float = 150.0
var _top_panel: PanelContainer
var _pause_button: Button
var _problem_graph_button: Button
var _menu_backdrop: ColorRect
var _center_panel: PanelContainer
var _center_content: VBoxContainer
var _menu_actions: VBoxContainer
var _center_heading: Label
var _center_body: Label
var _welcome_logo: TextureRect
var _debug_time_buttons: Array[Button] = []

static func is_mobile_platform() -> bool:
	return OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios")

func _ready() -> void:
	_mobile_mode = is_mobile_platform()
	_build_ui()

func update_clock(day_number: int, minute_of_day: int, phase: StringName) -> void:
	var hour := floori(float(minute_of_day) / 60.0)
	var minute := minute_of_day % 60
	_clock_label.text = "Day %d  ·  %02d:%02d  ·  %s" % [day_number, hour, minute, "Day" if phase == &"day" else "Night"]

func set_debug_time_speed(multiplier: int) -> void:
	for index in _debug_time_buttons.size():
		var button: Button = _debug_time_buttons[index]
		var texture: Texture2D = BUTTON_SQUARE_BLUE if WorldClockCoordinator.DEBUG_TIME_SCALES[index] == multiplier else BUTTON_SQUARE_BEIGE
		button.add_theme_stylebox_override("normal", _texture_stylebox(texture, 10.0, 0.0))

func update_status(state: GameSessionState) -> void:
	_anxiety_bar.value = state.anxiety
	_anxiety_label.text = "ANXIETY  %d" % roundi(state.anxiety)
	var trust_word := "steady"
	var family_trust := RelationshipRules.value_for(state, &"family")
	if family_trust > 0:
		trust_word = "warmer"
	elif family_trust < 0:
		trust_word = "strained"
	_trust_label.text = "Family · " + trust_word
	if state.anxiety_effect_id == &"":
		_effect_label.text = "No temporary effect"
	else:
		_effect_label.text = "Anxious focus · %d sec" % ceili(state.anxiety_effect_seconds)

func set_notice(text: String) -> void:
	_notice_label.text = text
	_notice_seconds = 4.5 if not text.is_empty() else 0.0

func show_exploration() -> void:
	_panel_mode = "exploration"
	_top_panel.visible = true
	_bottom_panel.visible = false
	_context_action.visible = false
	_menu_backdrop.visible = false
	_center_panel.visible = false
	_pause_button.visible = _mobile_mode
	_problem_graph_button.visible = _mobile_mode
	_set_dpad_visible(_mobile_mode)

func show_welcome(has_saves: bool) -> void:
	_panel_mode = "welcome"
	_top_panel.visible = false
	_bottom_panel.visible = false
	_context_action.visible = false
	_pause_button.visible = false
	_problem_graph_button.visible = false
	_set_dpad_visible(false)
	_show_center_panel("Welcome", "Choose how to begin.")
	_rebuild_menu_actions()
	_add_button("New Game", _emit_new_game, 48.0, _menu_actions)
	var continue_button := _add_button("Continue", _emit_continue, 48.0, _menu_actions)
	continue_button.disabled = not has_saves
	_fit_center_panel()

func show_slot_selection(slots: Array[Dictionary], saving: bool, message: String = "") -> void:
	_panel_mode = "save_slots" if saving else "continue_slots"
	_top_panel.visible = false
	_bottom_panel.visible = false
	_context_action.visible = false
	_pause_button.visible = false
	_problem_graph_button.visible = false
	_set_dpad_visible(false)
	_show_center_panel("Choose a Save Slot", message)
	_rebuild_menu_actions()
	for slot in slots:
		var slot_id := StringName(str(slot.get("slot_id", "")))
		var occupied := bool(slot.get("occupied", false))
		var valid := bool(slot.get("valid", false))
		var caption := str(slot.get("display_name", "Save Slot")) + " — Empty"
		if occupied and valid:
			var minute := int(slot.get("minute_of_day", 0))
			caption = "%s — Day %d · %02d:%02d" % [str(slot.get("display_name", "Save Slot")), int(slot.get("day_number", 1)), floori(float(minute) / 60.0), minute % 60]
		elif occupied:
			caption = str(slot.get("display_name", "Save Slot")) + " — Unavailable"
		var slot_button := _add_button(caption, _emit_slot_selected.bind(slot_id), 44.0, _menu_actions)
		slot_button.disabled = not saving and (not occupied or not valid)
	_add_button("Back", _emit_back, 40.0, _menu_actions)
	_fit_center_panel()

func show_pause(message: String = "") -> void:
	_panel_mode = "pause"
	_top_panel.visible = false
	_bottom_panel.visible = false
	_context_action.visible = false
	_pause_button.visible = false
	_problem_graph_button.visible = false
	_set_dpad_visible(false)
	_show_center_panel("Paused", message if not message.is_empty() else "The game is paused.")
	_rebuild_menu_actions()
	_add_button("Resume", _emit_resume, 46.0, _menu_actions)
	_add_button("Save", _emit_save, 46.0, _menu_actions)
	_fit_center_panel()

func show_overwrite_confirmation(slot_name: String) -> void:
	_panel_mode = "overwrite_confirmation"
	_top_panel.visible = false
	_bottom_panel.visible = false
	_context_action.visible = false
	_pause_button.visible = false
	_set_dpad_visible(false)
	_show_center_panel("Overwrite %s?" % slot_name, "This replaces the save currently in that slot.")
	_rebuild_menu_actions()
	_add_button("Overwrite", _emit_overwrite_confirmed, 46.0, _menu_actions)
	_add_button("Cancel", _emit_back, 42.0, _menu_actions)
	_fit_center_panel()

func set_context_action(screen_position: Vector2, enabled: bool) -> void:
	_context_anchor = screen_position
	_context_action.visible = enabled and not _mobile_mode and _panel_mode == "exploration"
	_update_context_action_position()

func set_pause_control_visible(enabled: bool) -> void:
	_pause_button.visible = enabled and _mobile_mode

func set_graph_control_visible(enabled: bool) -> void:
	_problem_graph_button.visible = enabled and _mobile_mode

func show_message(title: String, message: String) -> void:
	_panel_mode = "message"
	_show_modal_panel()
	_panel_heading.text = title
	_panel_body.text = message
	_rebuild_actions(false)
	_add_button("Continue", _emit_message_action, 44.0)
	_schedule_panel_fit()

func show_finished(title: String, message: String) -> void:
	_panel_mode = "finished"
	_show_modal_panel()
	_panel_heading.text = title
	_panel_body.text = message
	_rebuild_actions(false)
	_add_button("Play again", _emit_restart, 44.0)
	_schedule_panel_fit()

func get_panel_mode() -> String:
	return _panel_mode

func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	var hud_theme := Theme.new()
	hud_theme.default_font = HUD_FONT
	hud_theme.default_font_size = 15
	hud_theme.set_color("font_color", "Label", Color("#4d3b29"))
	hud_theme.set_color("font_color", "Button", Color("#4d3b29"))
	hud_theme.set_color("font_hover_color", "Button", Color("#fff4df"))
	hud_theme.set_color("font_pressed_color", "Button", Color("#fff4df"))
	hud_theme.set_color("font_disabled_color", "Button", Color("#887a66"))
	_root.theme = hud_theme

	_top_panel = PanelContainer.new()
	_top_panel.anchor_left = 0.025
	_top_panel.anchor_right = 0.975
	_top_panel.anchor_top = 0.0
	_top_panel.anchor_bottom = 0.0
	_top_panel.offset_top = 12.0
	_top_panel.offset_bottom = 112.0
	_apply_panel_style(_top_panel)
	_root.add_child(_top_panel)

	var top_content := VBoxContainer.new()
	top_content.add_theme_constant_override("separation", 3)
	_top_panel.add_child(top_content)
	var clock_row := HBoxContainer.new()
	clock_row.add_theme_constant_override("separation", 4)
	top_content.add_child(clock_row)
	_clock_label = Label.new()
	_clock_label.add_theme_font_size_override("font_size", 16)
	_clock_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	clock_row.add_child(_clock_label)
	if OS.is_debug_build():
		for index in WorldClockCoordinator.DEBUG_TIME_SCALES.size():
			_add_time_speed_button(clock_row, int(WorldClockCoordinator.DEBUG_TIME_SCALES[index]), index + 1)
		set_debug_time_speed(1)

	var anxiety_row := HBoxContainer.new()
	anxiety_row.add_theme_constant_override("separation", 8)
	top_content.add_child(anxiety_row)
	_anxiety_label = Label.new()
	_anxiety_label.custom_minimum_size.x = 91.0
	_anxiety_label.add_theme_font_size_override("font_size", 12)
	anxiety_row.add_child(_anxiety_label)
	_anxiety_bar = ProgressBar.new()
	_anxiety_bar.min_value = 0.0
	_anxiety_bar.max_value = 100.0
	_anxiety_bar.show_percentage = false
	_anxiety_bar.custom_minimum_size.y = 13.0
	_anxiety_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_anxiety_bar.add_theme_stylebox_override("background", _texture_stylebox(BAR_BACKGROUND, 5.0, 0.0))
	_anxiety_bar.add_theme_stylebox_override("fill", _texture_stylebox(BAR_GREEN, 5.0, 0.0))
	anxiety_row.add_child(_anxiety_bar)

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 12)
	top_content.add_child(footer)
	_trust_label = Label.new()
	_trust_label.add_theme_font_size_override("font_size", 12)
	footer.add_child(_trust_label)
	_effect_label = Label.new()
	_effect_label.add_theme_font_size_override("font_size", 11)
	_effect_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_effect_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	footer.add_child(_effect_label)
	_pause_button = Button.new()
	_pause_button.text = "Ⅱ"
	_pause_button.custom_minimum_size = Vector2(42.0, 34.0)
	_pause_button.focus_mode = Control.FOCUS_NONE
	_pause_button.mouse_entered.connect(_emit_ui_hover_requested.bind(_pause_button))
	_pause_button.pressed.connect(_emit_pause_requested)
	footer.add_child(_pause_button)
	_pause_button.visible = false
	_problem_graph_button = Button.new()
	_problem_graph_button.text = "Graph"
	_problem_graph_button.custom_minimum_size = Vector2(62.0, 34.0)
	_problem_graph_button.focus_mode = Control.FOCUS_NONE
	_problem_graph_button.mouse_entered.connect(_emit_ui_hover_requested.bind(_problem_graph_button))
	_problem_graph_button.pressed.connect(_emit_problem_graph_requested)
	footer.add_child(_problem_graph_button)
	_problem_graph_button.visible = false

	_notice_label = Label.new()
	_notice_label.clip_text = true
	_notice_label.add_theme_color_override("font_color", Color("#8a5b1f"))
	_notice_label.add_theme_font_size_override("font_size", 11)
	top_content.add_child(_notice_label)

	_bottom_panel = PanelContainer.new()
	_bottom_panel.anchor_left = 0.035
	_bottom_panel.anchor_right = 0.965
	_bottom_panel.anchor_top = 1.0
	_bottom_panel.anchor_bottom = 1.0
	_bottom_panel.offset_left = 0.0
	_bottom_panel.offset_right = 0.0
	_apply_panel_style(_bottom_panel)
	_root.add_child(_bottom_panel)
	_bottom_panel.visible = false

	_bottom_content = VBoxContainer.new()
	_bottom_content.add_theme_constant_override("separation", 6)
	_bottom_panel.add_child(_bottom_content)
	_panel_heading = Label.new()
	_panel_heading.add_theme_font_size_override("font_size", 18)
	_panel_heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bottom_content.add_child(_panel_heading)
	_panel_body = Label.new()
	_panel_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_panel_body.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_panel_body.add_theme_font_size_override("font_size", 15)
	_bottom_content.add_child(_panel_body)
	_actions = HBoxContainer.new()
	_bottom_content.add_child(_actions)

	_build_context_action()
	_build_dpad()
	_build_menu_overlay()

func _build_menu_overlay() -> void:
	_menu_backdrop = ColorRect.new()
	_menu_backdrop.color = Color(0.12, 0.1, 0.09, 0.78)
	_menu_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_menu_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(_menu_backdrop)
	_menu_backdrop.visible = false
	_center_panel = PanelContainer.new()
	_center_panel.anchor_left = 0.07
	_center_panel.anchor_right = 0.93
	_center_panel.anchor_top = 0.5
	_center_panel.anchor_bottom = 0.5
	_apply_panel_style(_center_panel)
	_root.add_child(_center_panel)
	_center_panel.visible = false
	_center_content = VBoxContainer.new()
	_center_content.add_theme_constant_override("separation", 8)
	_center_panel.add_child(_center_content)
	_welcome_logo = TextureRect.new()
	_welcome_logo.texture = MISWELL_LOGO
	_welcome_logo.custom_minimum_size = Vector2(0.0, 140.0)
	_welcome_logo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_welcome_logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_welcome_logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_welcome_logo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_welcome_logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_center_content.add_child(_welcome_logo)
	_welcome_logo.visible = false
	_center_heading = Label.new()
	_center_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_center_heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_center_heading.add_theme_font_size_override("font_size", 20)
	_center_content.add_child(_center_heading)
	_center_body = Label.new()
	_center_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_center_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_center_body.add_theme_font_size_override("font_size", 14)
	_center_content.add_child(_center_body)
	_menu_actions = VBoxContainer.new()
	_menu_actions.add_theme_constant_override("separation", 5)
	_center_content.add_child(_menu_actions)

func _show_center_panel(title: String, message: String) -> void:
	_welcome_logo.visible = _panel_mode == "welcome"
	_center_heading.text = title
	_center_body.text = message
	_center_panel.visible = true
	_menu_backdrop.visible = true
	_fit_center_panel()

func _fit_center_panel() -> void:
	if not is_instance_valid(_center_panel) or not _center_panel.visible:
		return
	var content_height := _center_content.get_combined_minimum_size().y
	var viewport_height := get_viewport().get_visible_rect().size.y
	var panel_height := minf(maxf(content_height + 28.0, 190.0), viewport_height - 80.0)
	_center_panel.offset_top = -panel_height * 0.5
	_center_panel.offset_bottom = panel_height * 0.5

func _build_context_action() -> void:
	_context_action = TextureRect.new()
	_context_action.texture = INTERACTION_PROMPT_E
	_context_action.custom_minimum_size = Vector2(32.0, 32.0)
	_context_action.size = Vector2(32.0, 32.0)
	_context_action.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_context_action.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_context_action.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_context_action.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_context_action)
	_context_action.visible = false

func _build_dpad() -> void:
	_dpad = PanelContainer.new()
	_dpad.anchor_left = 1.0
	_dpad.anchor_right = 1.0
	_dpad.anchor_top = 1.0
	_dpad.anchor_bottom = 1.0
	_dpad.offset_left = -150.0
	_dpad.offset_right = -10.0
	_dpad.custom_minimum_size = Vector2(140.0, 142.0)
	var dpad_style := _texture_stylebox(PANEL_BROWN, 12.0, 5.0)
	dpad_style.content_margin_left = 5.0
	dpad_style.content_margin_right = 5.0
	dpad_style.content_margin_top = 5.0
	dpad_style.content_margin_bottom = 5.0
	_dpad.add_theme_stylebox_override("panel", dpad_style)
	_root.add_child(_dpad)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 2)
	grid.add_theme_constant_override("v_separation", 2)
	_dpad.add_child(grid)
	_add_dpad_spacer(grid)
	_add_dpad_button(grid, "↑", &"up")
	_add_dpad_spacer(grid)
	_add_dpad_button(grid, "←", &"left")
	_add_dpad_spacer(grid)
	_add_dpad_button(grid, "→", &"right")
	_add_dpad_spacer(grid)
	_add_dpad_button(grid, "↓", &"down")
	_add_dpad_spacer(grid)
	_dpad.visible = false

func _add_time_speed_button(row: HBoxContainer, multiplier: int, arrow_count: int) -> void:
	var button := Button.new()
	button.custom_minimum_size = Vector2(23.0 + 10.0 * float(arrow_count), 30.0)
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.tooltip_text = "%d× time" % multiplier
	button.add_theme_stylebox_override("normal", _texture_stylebox(BUTTON_SQUARE_BEIGE, 10.0, 0.0))
	button.add_theme_stylebox_override("hover", _texture_stylebox(BUTTON_SQUARE_BROWN, 10.0, 0.0))
	button.add_theme_stylebox_override("pressed", _texture_stylebox(BUTTON_SQUARE_BROWN_PRESSED, 10.0, 0.0))
	button.mouse_entered.connect(_emit_ui_hover_requested.bind(button))
	button.mouse_entered.connect(_set_time_button_arrows.bind(button, ARROW_RIGHT_HOVER))
	button.mouse_exited.connect(_set_time_button_arrows.bind(button, ARROW_RIGHT))
	button.pressed.connect(_emit_time_speed_requested.bind(multiplier))
	row.add_child(button)
	_debug_time_buttons.append(button)
	for arrow_index in arrow_count:
		var arrow := TextureRect.new()
		arrow.texture = ARROW_RIGHT
		arrow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		arrow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		arrow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		arrow.anchor_left = 0.5
		arrow.anchor_right = 0.5
		arrow.anchor_top = 0.5
		arrow.anchor_bottom = 0.5
		arrow.offset_left = -6.0 * float(arrow_count) + 12.0 * float(arrow_index)
		arrow.offset_right = arrow.offset_left + 12.0
		arrow.offset_top = -6.0
		arrow.offset_bottom = 6.0
		button.add_child(arrow)

func _emit_time_speed_requested(multiplier: int) -> void:
	ui_click_requested.emit()
	time_speed_requested.emit(multiplier)

func _set_time_button_arrows(button: Button, texture: Texture2D) -> void:
	for child in button.get_children():
		var arrow := child as TextureRect
		if arrow != null:
			arrow.texture = texture

func _add_dpad_spacer(grid: GridContainer) -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(39.0, 39.0)
	grid.add_child(spacer)

func _add_dpad_button(grid: GridContainer, caption: String, key: StringName) -> void:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(39.0, 39.0)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 21)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.mouse_entered.connect(_emit_ui_hover_requested.bind(button))
	button.add_theme_stylebox_override("normal", _texture_stylebox(BUTTON_SQUARE_BEIGE, 10.0, 0.0))
	button.add_theme_stylebox_override("hover", _texture_stylebox(BUTTON_SQUARE_BROWN, 10.0, 0.0))
	button.add_theme_stylebox_override("pressed", _texture_stylebox(BUTTON_SQUARE_BROWN_PRESSED, 10.0, 0.0))
	button.add_theme_color_override("font_color", Color("#4d3b29"))
	button.add_theme_color_override("font_hover_color", Color("#fff4df"))
	button.add_theme_color_override("font_pressed_color", Color("#fff4df"))
	button.button_down.connect(_set_touch_pressed.bind(key, true))
	button.button_up.connect(_set_touch_pressed.bind(key, false))
	grid.add_child(button)

func _show_modal_panel() -> void:
	_bottom_panel.visible = true
	_context_action.visible = false
	_pause_button.visible = false
	_problem_graph_button.visible = false
	_set_dpad_visible(false)

func _set_dpad_visible(visible: bool) -> void:
	_dpad.visible = visible and _mobile_mode
	if not _dpad.visible:
		_touch_pressed.clear()
		touch_direction_changed.emit(Vector2.ZERO)

func _apply_panel_style(panel: PanelContainer) -> void:
	panel.add_theme_stylebox_override("panel", _texture_stylebox(PANEL_BEIGE, 12.0, 14.0))

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

func _rebuild_actions(vertical: bool) -> void:
	if is_instance_valid(_actions):
		_bottom_content.remove_child(_actions)
		_actions.queue_free()
	if vertical:
		_actions = VBoxContainer.new()
		_actions.add_theme_constant_override("separation", 5)
	else:
		_actions = HBoxContainer.new()
		_actions.add_theme_constant_override("separation", 6)
	_bottom_content.add_child(_actions)

func _rebuild_menu_actions() -> void:
	for child in _menu_actions.get_children():
		_menu_actions.remove_child(child)
		child.queue_free()

func _add_button(caption: String, callback: Callable, minimum_height: float, parent: BoxContainer = null) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(0.0, minimum_height)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 14)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var normal := _texture_stylebox(BUTTON_LONG_BEIGE, 12.0, 7.0)
	var hover := _texture_stylebox(BUTTON_LONG_BROWN, 12.0, 7.0)
	var pressed := _texture_stylebox(BUTTON_LONG_BROWN_PRESSED, 12.0, 7.0)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", normal)
	button.add_theme_color_override("font_color", Color("#4d3b29"))
	button.add_theme_color_override("font_hover_color", Color("#fff4df"))
	button.add_theme_color_override("font_pressed_color", Color("#fff4df"))
	button.mouse_entered.connect(_emit_ui_hover_requested.bind(button))
	button.pressed.connect(_emit_ui_click_requested)
	button.pressed.connect(callback)
	var container := parent if parent != null else _actions
	container.add_child(button)
	return button

func _schedule_panel_fit() -> void:
	call_deferred("_fit_bottom_panel")

func _fit_bottom_panel() -> void:
	await get_tree().process_frame
	if not is_instance_valid(_bottom_content) or not _bottom_panel.visible:
		return
	var content_height := _bottom_content.get_combined_minimum_size().y
	var viewport_height := get_viewport().get_visible_rect().size.y
	_bottom_height = minf(maxf(content_height + 24.0, 150.0), viewport_height - 184.0)
	_bottom_panel.offset_top = -_bottom_height - 12.0
	_bottom_panel.offset_bottom = -12.0

func _update_context_action_position() -> void:
	var bob := sin(_context_elapsed * 5.0) * 4.0
	_context_action.position = _context_anchor + Vector2(-16.0, -42.0 + bob)

func _set_touch_pressed(key: StringName, pressed: bool) -> void:
	_touch_pressed[key] = pressed
	var direction := Vector2(
		float(bool(_touch_pressed.get(&"right", false))) - float(bool(_touch_pressed.get(&"left", false))),
		float(bool(_touch_pressed.get(&"down", false))) - float(bool(_touch_pressed.get(&"up", false)))
	)
	touch_direction_changed.emit(direction.normalized())

func _process(delta: float) -> void:
	_context_elapsed += delta
	if _context_action.visible:
		_update_context_action_position()
	if _notice_seconds > 0.0:
		_notice_seconds -= delta
		if _notice_seconds <= 0.0:
			_notice_label.text = ""

func _emit_message_action() -> void:
	message_action_requested.emit()

func _emit_restart() -> void:
	restart_requested.emit()

func _emit_new_game() -> void:
	new_game_requested.emit()

func _emit_continue() -> void:
	continue_requested.emit()

func _emit_slot_selected(slot_id: StringName) -> void:
	slot_selected.emit(slot_id)

func _emit_overwrite_confirmed() -> void:
	overwrite_confirmed.emit()

func _emit_back() -> void:
	back_requested.emit()

func _emit_pause_requested() -> void:
	pause_requested.emit()

func _emit_problem_graph_requested() -> void:
	problem_graph_requested.emit()

func _emit_resume() -> void:
	resume_requested.emit()

func _emit_save() -> void:
	save_requested.emit()

func _emit_ui_click_requested() -> void:
	ui_click_requested.emit()

func _emit_ui_hover_requested(button: Button) -> void:
	if button.disabled:
		return
	ui_hover_requested.emit()
