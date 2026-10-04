class_name ProblemGraphScene
extends CanvasLayer

const PANEL_BEIGE: Texture2D = preload("res://assets/gui/kenney_ui-pack-rpg-expansion/PNG/panel_beige.png")
const PANEL_INSET_BROWN: Texture2D = preload("res://assets/gui/kenney_ui-pack-rpg-expansion/PNG/panelInset_brown.png")
const BUTTON_LONG_BEIGE: Texture2D = preload("res://assets/gui/kenney_ui-pack-rpg-expansion/PNG/buttonLong_beige.png")
const BUTTON_LONG_BROWN: Texture2D = preload("res://assets/gui/kenney_ui-pack-rpg-expansion/PNG/buttonLong_brown.png")
const BUTTON_LONG_BROWN_PRESSED: Texture2D = preload("res://assets/gui/kenney_ui-pack-rpg-expansion/PNG/buttonLong_brown_pressed.png")
const HUD_FONT: FontFile = preload("res://assets/fonts/Kenney/Fonts/Kenney Mini.ttf")

signal close_requested
signal debug_completion_requested(node_id: StringName)
signal ui_click_requested
signal ui_hover_requested

var _canvas: ProblemGraphCanvas
var _scroll: ScrollContainer
var _selected_label: Label
var _debug_complete_button: Button
var _selected_node_id: StringName = &""
var _definitions: Dictionary = {}

func _ready() -> void:
	layer = 5
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.theme = _make_theme()
	add_child(overlay)
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.09, 0.075, 0.06, 0.93)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(backdrop)
	var outer_margin := MarginContainer.new()
	outer_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		outer_margin.add_theme_constant_override("margin_" + side, 10)
	overlay.add_child(outer_margin)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _texture_stylebox(PANEL_BEIGE, 12.0, 15.0))
	outer_margin.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	panel.add_child(column)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	column.add_child(header)
	var title := Label.new()
	title.text = "Unhealth Graph"
	title.add_theme_font_size_override("font_size", 22)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(title)
	var close_button := Button.new()
	close_button.text = "Close"
	close_button.custom_minimum_size = Vector2(88, 42)
	_apply_button_style(close_button)
	close_button.pressed.connect(_emit_close_requested)
	header.add_child(close_button)
	var note := Label.new()
	note.text = "Explore the connected nodes. Select one to see its status."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_font_size_override("font_size", 14)
	column.add_child(note)
	var graph_panel := PanelContainer.new()
	graph_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	graph_panel.add_theme_stylebox_override("panel", _texture_stylebox(PANEL_INSET_BROWN, 12.0, 8.0))
	column.add_child(graph_panel)
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	graph_panel.add_child(_scroll)
	_canvas = ProblemGraphCanvas.new()
	_canvas.node_selected.connect(_on_node_selected)
	_canvas.ui_click_requested.connect(func() -> void: ui_click_requested.emit())
	_canvas.ui_hover_requested.connect(func() -> void: ui_hover_requested.emit())
	_scroll.add_child(_canvas)
	_scroll.resized.connect(_fit_graph_canvas)
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 8)
	column.add_child(footer)
	_selected_label = Label.new()
	_selected_label.text = "Select a graph node."
	_selected_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_selected_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_selected_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_selected_label.custom_minimum_size.y = 46
	footer.add_child(_selected_label)
	_debug_complete_button = Button.new()
	_debug_complete_button.text = "Debug: mark complete"
	_debug_complete_button.visible = OS.is_debug_build()
	_debug_complete_button.disabled = true
	_debug_complete_button.custom_minimum_size = Vector2(160, 42)
	_apply_button_style(_debug_complete_button)
	_debug_complete_button.pressed.connect(_emit_debug_completion_requested)
	footer.add_child(_debug_complete_button)

func present(nodes: Array[ProblemGraphNodeDefinition], completed_node_ids: Array[StringName]) -> void:
	_definitions.clear()
	for definition in nodes:
		if definition != null:
			_definitions[definition.node_id] = definition
	_selected_node_id = &""
	_canvas.populate(nodes, completed_node_ids)
	_fit_graph_canvas.call_deferred()
	_update_selected_node()

func _fit_graph_canvas() -> void:
	var viewport_height := _scroll.size.y
	var horizontal_bar := _scroll.get_h_scroll_bar()
	if horizontal_bar.visible:
		viewport_height -= horizontal_bar.size.y
	_canvas.fill_viewport_height(viewport_height)

func refresh_completed_nodes(completed_node_ids: Array[StringName]) -> void:
	_canvas.set_completed_node_ids(completed_node_ids)
	_update_selected_node()

func _on_node_selected(node_id: StringName) -> void:
	_selected_node_id = node_id
	_canvas.set_selected_node(node_id)
	_update_selected_node()

func _update_selected_node() -> void:
	var definition := _definitions.get(_selected_node_id) as ProblemGraphNodeDefinition
	if definition == null:
		_selected_label.text = "Select a graph node."
		_debug_complete_button.disabled = true
		return
	var status := "Category" if definition.is_category else ("Acquired" if _canvas.is_completed(_selected_node_id) else "Not acquired")
	_selected_label.text = "%s · %s" % [definition.title, status]
	_debug_complete_button.disabled = definition.is_category or _canvas.is_completed(_selected_node_id)

func _make_theme() -> Theme:
	var graph_theme := Theme.new()
	graph_theme.default_font = HUD_FONT
	graph_theme.default_font_size = 15
	graph_theme.set_color("font_color", "Label", Color("#4d3b29"))
	graph_theme.set_color("font_color", "Button", Color("#4d3b29"))
	graph_theme.set_color("font_hover_color", "Button", Color("#fff4df"))
	graph_theme.set_color("font_pressed_color", "Button", Color("#fff4df"))
	graph_theme.set_color("font_disabled_color", "Button", Color("#887a66"))
	return graph_theme

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
	button.add_theme_stylebox_override("disabled", _texture_stylebox(BUTTON_LONG_BEIGE, 12.0, 8.0))
	button.add_theme_color_override("font_color", Color("#4d3b29"))
	button.add_theme_color_override("font_hover_color", Color("#fff4df"))
	button.add_theme_color_override("font_pressed_color", Color("#fff4df"))
	button.mouse_entered.connect(_emit_ui_hover_requested.bind(button))

func _emit_close_requested() -> void:
	ui_click_requested.emit()
	close_requested.emit()

func _emit_debug_completion_requested() -> void:
	if _selected_node_id != &"" and _canvas.contains_graph_node(_selected_node_id) and not _canvas.is_category(_selected_node_id):
		ui_click_requested.emit()
		debug_completion_requested.emit(_selected_node_id)

func _emit_ui_hover_requested(button: Button) -> void:
	if not button.disabled:
		ui_hover_requested.emit()
