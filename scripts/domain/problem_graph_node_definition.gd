class_name ProblemGraphNodeDefinition
extends Resource

var node_id: StringName = &""
var title: String = ""
var parent_ids: Array[StringName] = []
var required_node_ids: Array[StringName] = []
var ability_ids: Array[StringName] = []
var grid_position: Vector2i = Vector2i.ZERO
var is_category: bool = false

static func from_document(data: Dictionary) -> ProblemGraphNodeDefinition:
	var definition := ProblemGraphNodeDefinition.new()
	definition.node_id = StringName(str(data.get("id", "")))
	definition.title = str(data.get("title", ""))
	definition.is_category = bool(data.get("is_category", false))
	definition.parent_ids = _string_name_array(data.get("parent_ids", []))
	definition.required_node_ids = _string_name_array(data.get("required_node_ids", []))
	definition.ability_ids = _string_name_array(data.get("ability_ids", []))
	var layout: Variant = data.get("layout", [])
	if layout is Array and layout.size() == 2:
		definition.grid_position = Vector2i(int(layout[0]), int(layout[1]))
	return definition

static func _string_name_array(value: Variant) -> Array[StringName]:
	var result: Array[StringName] = []
	if not value is Array:
		return result
	for item in value:
		var item_id := StringName(str(item))
		if item_id != &"":
			result.append(item_id)
	return result
