class_name GameHUD
extends CanvasLayer

signal choice_selected(choice_id: StringName)
signal message_action_requested
signal restart_requested
signal slot_selected(slot_index: int)
signal slot_picker_cancelled
signal touch_direction_changed(direction: Vector2)

var _root: Control
var _day_label: Label
var _anxiety_label: Label
var _anxiety_bar: ProgressBar
var _trust_label: Label
var _effect_label: Label
var _notice_label: Label
var _slot_activity_labels: Array[Label] = []
var _slot_panels: Array[PanelContainer] = []
var _slot_status_cache: Array[String] = []
var _bottom_panel: PanelContainer
var _bottom_content: VBoxContainer
var _panel_heading: Label
var _panel_body: Label
var _actions: BoxContainer
var _context_action: PanelContainer
var _context_label: Label
var _context_anchor: Vector2 = Vector2.ZERO
var _context_caption: String = ""
var _dpad: PanelContainer
var _touch_pressed: Dictionary = {}
var _notice_seconds: float = 0.0
var _panel_mode: String = "exploration"
var _mobile_mode: bool = false
var _context_elapsed: float = 0.0
var _bottom_height: float = 150.0

static func is_mobile_platform() -> bool:
	return OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios")

func _ready() -> void:
	_mobile_mode = is_mobile_platform()
	_build_ui()

func update_status(state: GameState, day_text: String, timeline: Array[Dictionary]) -> void:
	_day_label.text = day_text
	_anxiety_bar.value = state.anxiety
	_anxiety_label.text = "ANXIETY  %d" % roundi(state.anxiety)
	var trust_word := "steady"
	if state.family_trust > 0:
		trust_word = "warmer"
	elif state.family_trust < 0:
		trust_word = "strained"
	_trust_label.text = "Family · " + trust_word
	if state.anxiety_effect_id == &"":
		_effect_label.text = "No temporary effect"
	else:
		_effect_label.text = "Anxious focus · %d sec" % ceili(state.anxiety_effect_seconds)
	for index in range(mini(timeline.size(), _slot_activity_labels.size())):
		var slot := timeline[index]
		var activity := str(slot.get("activity", ""))
		var slot_status := "scheduled:" + activity if not activity.is_empty() else "open"
		if _slot_status_cache[index] == slot_status:
			continue
		_slot_status_cache[index] = slot_status
		_slot_activity_labels[index].text = activity if not activity.is_empty() else "Free"
		var scheduled := not activity.is_empty()
		var style := StyleBoxFlat.new()
		style.bg_color = Color("#d7dfc8") if scheduled else Color("#27343a")
		style.border_color = Color("#9cb28c") if scheduled else Color("#41534e")
		style.set_border_width_all(1)
		style.set_corner_radius_all(7)
		_slot_panels[index].add_theme_stylebox_override("panel", style)
		_slot_activity_labels[index].add_theme_color_override("font_color", Color("#27343a") if scheduled else Color("#d5ddcf"))

func set_notice(text: String) -> void:
	_notice_label.text = text
	_notice_seconds = 4.5 if not text.is_empty() else 0.0

func show_exploration() -> void:
	_panel_mode = "exploration"
	_bottom_panel.visible = false
	_context_action.visible = not _mobile_mode and not _context_caption.is_empty()
	_set_dpad_visible(_mobile_mode)

func set_context_action(caption: String, screen_position: Vector2, enabled: bool) -> void:
	_context_caption = caption
	_context_anchor = screen_position
	_context_label.text = caption
	_context_action.visible = enabled and not _mobile_mode and _panel_mode == "exploration"
	_update_context_action_position()

func show_slot_picker(title: String, body: String, slots: Array[Dictionary]) -> void:
	_panel_mode = "slot_picker"
	_show_modal_panel()
	_panel_heading.text = title
	_panel_body.text = body
	_rebuild_actions(true)
	for slot in slots:
		var caption := "%s   ·   OPEN" % str(slot.get("label", "Slot"))
		var index := int(slot.get("slot_index", -1))
		_add_button(caption, _emit_slot_selected.bind(index), 42.0)
	_add_button("Cancel", _emit_slot_cancel, 42.0)
	_schedule_panel_fit()

func show_dialogue(view: Dictionary) -> void:
	_panel_mode = "dialogue"
	_show_modal_panel()
	_panel_heading.text = str(view.get("title", "Conversation"))
	_panel_body.text = str(view.get("body", ""))
	_rebuild_actions(true)
	var choices: Array = view.get("choices", [])
	for item in choices:
		var choice := item as DialogueChoiceDefinition
		if choice == null:
			continue
		var caption := "%s\n%s" % [choice.label, choice.description]
		var button := _add_button(caption, _emit_choice.bind(choice.choice_id), 64.0)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_schedule_panel_fit()

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

	var top_panel := PanelContainer.new()
	top_panel.anchor_left = 0.025
	top_panel.anchor_right = 0.975
	top_panel.anchor_top = 0.0
	top_panel.anchor_bottom = 0.0
	top_panel.offset_top = 12.0
	top_panel.offset_bottom = 140.0
	_apply_panel_style(top_panel)
	_root.add_child(top_panel)

	var top_content := VBoxContainer.new()
	top_content.add_theme_constant_override("separation", 3)
	top_panel.add_child(top_content)
	_day_label = Label.new()
	_day_label.add_theme_font_size_override("font_size", 15)
	top_content.add_child(_day_label)

	var slot_row := HBoxContainer.new()
	slot_row.add_theme_constant_override("separation", 5)
	top_content.add_child(slot_row)
	for slot_name in ["MORNING", "AFTERNOON", "EVENING"]:
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.custom_minimum_size.y = 37.0
		var card_style := StyleBoxFlat.new()
		card_style.bg_color = Color("#27343a")
		card_style.border_color = Color("#41534e")
		card_style.set_border_width_all(1)
		card_style.set_corner_radius_all(7)
		card.add_theme_stylebox_override("panel", card_style)
		slot_row.add_child(card)
		var card_content := VBoxContainer.new()
		card_content.add_theme_constant_override("separation", 0)
		card.add_child(card_content)
		var title := Label.new()
		title.text = slot_name
		title.add_theme_font_size_override("font_size", 9)
		title.add_theme_color_override("font_color", Color("#b6c4ae"))
		card_content.add_child(title)
		var activity := Label.new()
		activity.text = "Free"
		activity.clip_text = true
		activity.add_theme_font_size_override("font_size", 11)
		card_content.add_child(activity)
		_slot_panels.append(card)
		_slot_activity_labels.append(activity)
		_slot_status_cache.append("")

	var anxiety_row := HBoxContainer.new()
	anxiety_row.add_theme_constant_override("separation", 8)
	top_content.add_child(anxiety_row)
	_anxiety_label = Label.new()
	_anxiety_label.custom_minimum_size.x = 91.0
	_anxiety_label.add_theme_font_size_override("font_size", 11)
	anxiety_row.add_child(_anxiety_label)
	_anxiety_bar = ProgressBar.new()
	_anxiety_bar.min_value = 0.0
	_anxiety_bar.max_value = 100.0
	_anxiety_bar.show_percentage = false
	_anxiety_bar.custom_minimum_size.y = 9.0
	_anxiety_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	anxiety_row.add_child(_anxiety_bar)

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 12)
	top_content.add_child(footer)
	_trust_label = Label.new()
	_trust_label.add_theme_font_size_override("font_size", 11)
	footer.add_child(_trust_label)
	_effect_label = Label.new()
	_effect_label.add_theme_font_size_override("font_size", 10)
	_effect_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_effect_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	footer.add_child(_effect_label)

	_notice_label = Label.new()
	_notice_label.clip_text = true
	_notice_label.add_theme_color_override("font_color", Color("#f0d889"))
	_notice_label.add_theme_font_size_override("font_size", 10)
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
	_panel_heading.add_theme_font_size_override("font_size", 17)
	_panel_heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bottom_content.add_child(_panel_heading)
	_panel_body = Label.new()
	_panel_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_panel_body.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_panel_body.add_theme_font_size_override("font_size", 14)
	_bottom_content.add_child(_panel_body)
	_actions = HBoxContainer.new()
	_bottom_content.add_child(_actions)

	_build_context_action()
	_build_dpad()

func _build_context_action() -> void:
	_context_action = PanelContainer.new()
	_context_action.custom_minimum_size = Vector2(92.0, 32.0)
	_context_action.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#243237", 0.96)
	style.border_color = Color("#e0c982")
	style.set_border_width_all(2)
	style.set_corner_radius_all(16)
	style.content_margin_left = 9.0
	style.content_margin_right = 9.0
	style.content_margin_top = 2.0
	style.content_margin_bottom = 2.0
	_context_action.add_theme_stylebox_override("panel", style)
	_root.add_child(_context_action)
	_context_label = Label.new()
	_context_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_context_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_context_label.add_theme_font_size_override("font_size", 12)
	_context_label.add_theme_color_override("font_color", Color("#fff4d6"))
	_context_action.add_child(_context_label)
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
	var dpad_style := StyleBoxFlat.new()
	dpad_style.bg_color = Color(0.075, 0.10, 0.12, 0.72)
	dpad_style.border_color = Color(0.45, 0.56, 0.50, 0.75)
	dpad_style.set_border_width_all(1)
	dpad_style.set_corner_radius_all(13)
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

func _add_dpad_spacer(grid: GridContainer) -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(39.0, 39.0)
	grid.add_child(spacer)

func _add_dpad_button(grid: GridContainer, caption: String, key: StringName) -> void:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(39.0, 39.0)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 20)
	button.button_down.connect(_set_touch_pressed.bind(key, true))
	button.button_up.connect(_set_touch_pressed.bind(key, false))
	grid.add_child(button)

func _show_modal_panel() -> void:
	_bottom_panel.visible = true
	_context_action.visible = false
	_set_dpad_visible(false)

func _set_dpad_visible(visible: bool) -> void:
	_dpad.visible = visible and _mobile_mode
	if not _dpad.visible:
		_touch_pressed.clear()
		touch_direction_changed.emit(Vector2.ZERO)

func _apply_panel_style(panel: PanelContainer) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.075, 0.10, 0.12, 0.94)
	style.border_color = Color("#829b87")
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	panel.add_theme_stylebox_override("panel", style)

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

func _add_button(caption: String, callback: Callable, minimum_height: float) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(0.0, minimum_height)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 13)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#29373b")
	normal.border_color = Color("#43544f")
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(7)
	normal.content_margin_left = 7.0
	normal.content_margin_right = 7.0
	normal.content_margin_top = 4.0
	normal.content_margin_bottom = 4.0
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("#3b514d")
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("#536d60")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", normal)
	button.add_theme_color_override("font_color", Color("#f1eee2"))
	button.pressed.connect(callback)
	_actions.add_child(button)
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
	_context_action.position = _context_anchor + Vector2(-46.0, -42.0 + bob)

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

func _emit_slot_selected(slot_index: int) -> void:
	slot_selected.emit(slot_index)

func _emit_slot_cancel() -> void:
	slot_picker_cancelled.emit()

func _emit_choice(choice_id: StringName) -> void:
	choice_selected.emit(choice_id)

func _emit_message_action() -> void:
	message_action_requested.emit()

func _emit_restart() -> void:
	restart_requested.emit()

