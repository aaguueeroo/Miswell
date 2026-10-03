class_name ProblemGraphScene
extends CanvasLayer

signal close_requested
signal debug_completion_requested(node_id: StringName)

var _canvas: ProblemGraphCanvas
var _selected_label: Label
var _debug_complete_button: Button
var _selected_node_id: StringName = &""
var _definitions: Dictionary = {}
var _overlay: Control

func _ready() -> void:
	layer = 5
	_overlay = Control.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)
	var backdrop := ColorRect.new()
	backdrop.color = Color("#252321")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.add_child(backdrop)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 12)
	_overlay.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 7)
	margin.add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	var title := Label.new()
	title.text = "Problem Graph"
	title.add_theme_font_size_override("font_size", 20)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close_button := Button.new()
	close_button.text = "Close"
	close_button.pressed.connect(_emit_close_requested)
	header.add_child(close_button)
	var note := Label.new()
	note.text = "Story outcomes add nodes. Select a node to inspect its current state."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(note)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	column.add_child(scroll)
	_canvas = ProblemGraphCanvas.new()
	_canvas.node_selected.connect(_on_node_selected)
	scroll.add_child(_canvas)
	var footer := HBoxContainer.new()
	column.add_child(footer)
	_selected_label = Label.new()
	_selected_label.text = "Select a graph node."
	_selected_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_selected_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(_selected_label)
	_debug_complete_button = Button.new()
	_debug_complete_button.text = "Debug: mark complete"
	_debug_complete_button.visible = OS.is_debug_build()
	_debug_complete_button.pressed.connect(_emit_debug_completion_requested)
	footer.add_child(_debug_complete_button)

func present(nodes: Array[ProblemGraphNodeDefinition], completed_node_ids: Array[StringName]) -> void:
	_definitions.clear()
	for definition in nodes:
		if definition != null:
			_definitions[definition.node_id] = definition
	_selected_node_id = &""
	_canvas.populate(nodes, completed_node_ids)
	_update_selected_node()

func refresh_completed_nodes(completed_node_ids: Array[StringName]) -> void:
	_canvas.set_completed_node_ids(completed_node_ids)
	_update_selected_node()

func _on_node_selected(node_id: StringName) -> void:
	_selected_node_id = node_id
	_update_selected_node()

func _update_selected_node() -> void:
	var definition := _definitions.get(_selected_node_id) as ProblemGraphNodeDefinition
	if definition == null:
		_selected_label.text = "Select a graph node."
		_debug_complete_button.disabled = true
		return
	var category_text := " · Category" if definition.is_category else ""
	var acquired_text := " · Acquired" if _canvas.is_completed(_selected_node_id) else " · Not acquired" if not definition.is_category else ""
	_selected_label.text = "%s%s%s  (%s)" % [definition.title, category_text, acquired_text, String(definition.node_id)]
	_debug_complete_button.disabled = definition.is_category or _canvas.is_completed(_selected_node_id)

func _emit_close_requested() -> void:
	close_requested.emit()

func _emit_debug_completion_requested() -> void:
	if _selected_node_id != &"" and _canvas.has_node(_selected_node_id) and not _canvas.is_category(_selected_node_id):
		debug_completion_requested.emit(_selected_node_id)
