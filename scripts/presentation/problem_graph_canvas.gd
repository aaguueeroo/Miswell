class_name ProblemGraphCanvas
extends Control

signal node_selected(node_id: StringName)
signal ui_hover_requested
signal ui_click_requested

const PARCHMENT: Texture2D = preload("res://assets/gui/problem_graph/graph_parchment.svg")
const ROUND_BEIGE: Texture2D = preload("res://assets/gui/kenney_ui-pack-rpg-expansion/PNG/buttonRound_beige.png")
const ROUND_BROWN: Texture2D = preload("res://assets/gui/kenney_ui-pack-rpg-expansion/PNG/buttonRound_brown.png")
const ROUND_BLUE: Texture2D = preload("res://assets/gui/kenney_ui-pack-rpg-expansion/PNG/buttonRound_blue.png")
const ROUND_GREY: Texture2D = preload("res://assets/gui/kenney_ui-pack-rpg-expansion/PNG/buttonRound_grey.png")
const HUD_FONT: FontFile = preload("res://assets/fonts/Kenney/Fonts/Kenney Mini.ttf")
const NODE_DIAMETER := 76.0
const GRID_STEP_X := 166.0
const GRID_STEP_Y := 164.0
const GRID_ORIGIN := Vector2(88.0, 55.0)

var _definitions: Dictionary = {}
var _buttons: Dictionary = {}
var _labels: Dictionary = {}
var _completed_ids: Array[StringName] = []
var _selected_id: StringName = &""
var _content_minimum_height: float = 560.0

func _ready() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED

func populate(nodes: Array[ProblemGraphNodeDefinition], completed_ids: Array[StringName]) -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_definitions.clear()
	_buttons.clear()
	_labels.clear()
	_completed_ids = completed_ids.duplicate()
	_selected_id = &""
	var max_column := 0
	var max_row := 0
	for definition in nodes:
		if definition == null:
			continue
		_definitions[definition.node_id] = definition
		max_column = maxi(max_column, definition.grid_position.x)
		max_row = maxi(max_row, definition.grid_position.y)
	_content_minimum_height = maxf(560.0, GRID_ORIGIN.y + float(max_row) * GRID_STEP_Y + 112.0)
	custom_minimum_size = Vector2(
		maxf(540.0, GRID_ORIGIN.x * 2.0 + float(max_column) * GRID_STEP_X),
		_content_minimum_height
	)
	size = custom_minimum_size
	for node_id in _definitions:
		_add_node_control(node_id, _definitions[node_id] as ProblemGraphNodeDefinition)
	_update_node_appearance()
	queue_redraw()

func fill_viewport_height(viewport_height: float) -> void:
	var height := maxf(_content_minimum_height, viewport_height)
	if is_equal_approx(custom_minimum_size.y, height):
		return
	custom_minimum_size = Vector2(custom_minimum_size.x, height)
	size = Vector2(size.x, height)
	queue_redraw()

func set_completed_node_ids(completed_ids: Array[StringName]) -> void:
	_completed_ids = completed_ids.duplicate()
	_update_node_appearance()
	queue_redraw()

func set_selected_node(node_id: StringName) -> void:
	_selected_id = node_id
	_update_node_appearance()

func contains_graph_node(node_id: StringName) -> bool:
	return _definitions.has(node_id)

func is_category(node_id: StringName) -> bool:
	var definition := _definitions.get(node_id) as ProblemGraphNodeDefinition
	return definition != null and definition.is_category

func is_completed(node_id: StringName) -> bool:
	return _completed_ids.has(node_id)

func _draw() -> void:
	draw_texture_rect(PARCHMENT, Rect2(Vector2.ZERO, size), true)
	for child_id in _definitions:
		var child_definition := _definitions[child_id] as ProblemGraphNodeDefinition
		var child_center := _node_center(child_definition)
		for parent_id in child_definition.parent_ids:
			var parent_definition := _definitions.get(parent_id) as ProblemGraphNodeDefinition
			if parent_definition == null:
				continue
			var parent_center := _node_center(parent_definition)
			var along: Vector2 = (child_center - parent_center).normalized()
			var start: Vector2 = parent_center + along * (NODE_DIAMETER * 0.53)
			var finish: Vector2 = child_center - along * (NODE_DIAMETER * 0.53)
			draw_line(start + Vector2(0, 2), finish + Vector2(0, 2), Color("#877653"), 7.0)
			var edge_color := Color("#9b8b6b")
			if _completed_ids.has(parent_id) and _completed_ids.has(child_id):
				edge_color = Color("#73947b")
			draw_line(start, finish, edge_color, 4.0)
			draw_circle((start + finish) * 0.5, 3.0, edge_color)
	for node_id in _definitions:
		var center := _node_center(_definitions[node_id] as ProblemGraphNodeDefinition)
		var plate := Rect2(center + Vector2(-77.0, 42.0), Vector2(154.0, 48.0))
		draw_rect(plate, Color("#e9dcb9"))
		draw_rect(plate, Color("#ab936c"), false, 1.0)

func _node_center(definition: ProblemGraphNodeDefinition) -> Vector2:
	return GRID_ORIGIN + Vector2(float(definition.grid_position.x) * GRID_STEP_X, float(definition.grid_position.y) * GRID_STEP_Y)

func _add_node_control(node_id: StringName, definition: ProblemGraphNodeDefinition) -> void:
	var center := _node_center(definition)
	var button := TextureButton.new()
	button.name = "GraphNode_" + String(node_id).replace(":", "_")
	button.position = center - Vector2.ONE * (NODE_DIAMETER * 0.5)
	button.custom_minimum_size = Vector2.ONE * NODE_DIAMETER
	button.size = button.custom_minimum_size
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	button.texture_hover = ROUND_BLUE
	button.texture_pressed = ROUND_BROWN
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(_on_node_pressed.bind(node_id))
	button.mouse_entered.connect(func() -> void: ui_hover_requested.emit())
	add_child(button)
	_buttons[node_id] = button
	var icon_path := "res://assets/gui/problem_graph/icons/%s.svg" % String(node_id).get_slice(":", 1)
	if ResourceLoader.exists(icon_path):
		var icon := Sprite2D.new()
		var icon_texture := load(icon_path) as Texture2D
		icon.texture = icon_texture
		icon.position = Vector2.ONE * (NODE_DIAMETER * 0.5)
		icon.scale = Vector2(38.0 / icon_texture.get_width(), 38.0 / icon_texture.get_height())
		button.add_child(icon)
	else:
		var initial := Label.new()
		initial.text = definition.title.left(1)
		initial.position = Vector2(16.0, 13.0)
		initial.size = Vector2(44.0, 50.0)
		initial.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		initial.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		initial.add_theme_font_override("font", HUD_FONT)
		initial.add_theme_font_size_override("font_size", 27)
		initial.add_theme_color_override("font_color", Color("#4d3b29"))
		initial.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(initial)
	var label := Label.new()
	label.text = definition.title
	label.position = center + Vector2(-76.0, 42.0)
	label.size = Vector2(152.0, 48.0)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	label.add_theme_font_override("font", HUD_FONT)
	label.add_theme_font_size_override("font_size", 15)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	_labels[node_id] = label

func _update_node_appearance() -> void:
	for node_id in _buttons:
		var definition := _definitions[node_id] as ProblemGraphNodeDefinition
		var button := _buttons[node_id] as TextureButton
		var label := _labels[node_id] as Label
		button.texture_normal = ROUND_BEIGE if definition.is_category or _completed_ids.has(node_id) else ROUND_GREY
		if node_id == _selected_id:
			button.texture_normal = ROUND_BLUE
		label.add_theme_color_override("font_color", Color("#4d3b29") if definition.is_category or _completed_ids.has(node_id) else Color("#665f58"))
		button.tooltip_text = "%s · %s" % [definition.title, "Category" if definition.is_category else ("Acquired" if _completed_ids.has(node_id) else "Not acquired")]

func _on_node_pressed(node_id: StringName) -> void:
	ui_click_requested.emit()
	node_selected.emit(node_id)
