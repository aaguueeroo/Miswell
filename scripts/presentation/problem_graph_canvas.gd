class_name ProblemGraphCanvas
extends Control

signal node_selected(node_id: StringName)

const NODE_WIDTH := 142.0
const NODE_HEIGHT := 64.0
const GRID_STEP_X := 152.0
const GRID_STEP_Y := 132.0
const GRID_ORIGIN := Vector2(24.0, 20.0)

var _definitions: Dictionary = {}
var _buttons: Dictionary = {}
var _completed_ids: Array[StringName] = []

func populate(nodes: Array[ProblemGraphNodeDefinition], completed_ids: Array[StringName]) -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_definitions.clear()
	_buttons.clear()
	_completed_ids = completed_ids.duplicate()
	var max_column := 0
	var max_row := 0
	for definition in nodes:
		if definition == null:
			continue
		_definitions[definition.node_id] = definition
		max_column = maxi(max_column, definition.grid_position.x)
		max_row = maxi(max_row, definition.grid_position.y)
	var canvas_width := maxf(540.0, GRID_ORIGIN.x * 2.0 + float(max_column) * GRID_STEP_X + NODE_WIDTH)
	var canvas_height := maxf(560.0, GRID_ORIGIN.y * 2.0 + float(max_row) * GRID_STEP_Y + NODE_HEIGHT)
	custom_minimum_size = Vector2(canvas_width, canvas_height)
	size = custom_minimum_size
	for node_id in _definitions:
		var definition := _definitions[node_id] as ProblemGraphNodeDefinition
		var button := Button.new()
		button.custom_minimum_size = Vector2(NODE_WIDTH, NODE_HEIGHT)
		button.size = button.custom_minimum_size
		button.position = GRID_ORIGIN + Vector2(float(definition.grid_position.x) * GRID_STEP_X, float(definition.grid_position.y) * GRID_STEP_Y)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.pressed.connect(_on_node_pressed.bind(node_id))
		add_child(button)
		_buttons[node_id] = button
		_update_node_button(node_id)
	queue_redraw()

func set_completed_node_ids(completed_ids: Array[StringName]) -> void:
	_completed_ids = completed_ids.duplicate()
	for node_id in _buttons:
		_update_node_button(node_id)
	queue_redraw()

func has_node(node_id: StringName) -> bool:
	return _definitions.has(node_id)

func is_category(node_id: StringName) -> bool:
	var definition := _definitions.get(node_id) as ProblemGraphNodeDefinition
	return definition != null and definition.is_category

func is_completed(node_id: StringName) -> bool:
	return _completed_ids.has(node_id)

func _draw() -> void:
	for child_id in _definitions:
		var child_definition := _definitions[child_id] as ProblemGraphNodeDefinition
		var child_center := _node_center(child_definition)
		for parent_id in child_definition.parent_ids:
			var parent_definition := _definitions.get(parent_id) as ProblemGraphNodeDefinition
			if parent_definition == null:
				continue
			var edge_color := Color("#8c887f")
			if _completed_ids.has(parent_id) and _completed_ids.has(child_id):
				edge_color = Color("#79a889")
			draw_line(_node_center(parent_definition), child_center, edge_color, 3.0, true)

func _node_center(definition: ProblemGraphNodeDefinition) -> Vector2:
	return GRID_ORIGIN + Vector2(float(definition.grid_position.x) * GRID_STEP_X, float(definition.grid_position.y) * GRID_STEP_Y) + Vector2(NODE_WIDTH * 0.5, NODE_HEIGHT * 0.5)

func _update_node_button(node_id: StringName) -> void:
	var definition := _definitions.get(node_id) as ProblemGraphNodeDefinition
	var button := _buttons.get(node_id) as Button
	if definition == null or button == null:
		return
	var status := "Category" if definition.is_category else "Not acquired"
	if _completed_ids.has(node_id):
		status = "Acquired"
	button.text = "%s\n%s" % [definition.title, status]
	button.tooltip_text = String(node_id)

func _on_node_pressed(node_id: StringName) -> void:
	node_selected.emit(node_id)
