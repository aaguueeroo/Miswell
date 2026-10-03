class_name ProblemGraphCoordinator
extends RefCounted

var _state: GameSessionState
var _content: ContentCatalog
var _node_index: Dictionary = {}

func _init(state: GameSessionState, content: ContentCatalog) -> void:
	_state = state
	_content = content
	for definition in _content.get_problem_graph_nodes():
		_node_index[definition.node_id] = definition

func get_nodes() -> Array[ProblemGraphNodeDefinition]:
	return _content.get_problem_graph_nodes()

func get_node(node_id: StringName) -> ProblemGraphNodeDefinition:
	return _node_index.get(node_id) as ProblemGraphNodeDefinition

func get_completed_node_ids() -> Array[StringName]:
	return _state.completed_problem_graph_node_ids.duplicate()

func can_unlock_node(node_id: StringName) -> bool:
	return ProblemGraphRules.can_unlock_node(_state, get_node(node_id), _node_index)

func unlock_node_from_story(node_id: StringName) -> bool:
	return ProblemGraphRules.mark_node_complete(_state, get_node(node_id), _node_index)

func debug_complete_node(node_id: StringName) -> bool:
	if not OS.is_debug_build():
		return false
	return ProblemGraphRules.mark_node_complete(_state, get_node(node_id), _node_index, true)

func is_ability_unlocked(ability_id: StringName) -> bool:
	if ability_id == &"":
		return false
	for node_id in _state.completed_problem_graph_node_ids:
		var definition := get_node(node_id)
		if definition != null and definition.ability_ids.has(ability_id):
			return true
	return false

func get_unlocked_ability_ids() -> Array[StringName]:
	var unlocked: Array[StringName] = []
	for node_id in _state.completed_problem_graph_node_ids:
		var definition := get_node(node_id)
		if definition == null:
			continue
		for ability_id in definition.ability_ids:
			if not unlocked.has(ability_id):
				unlocked.append(ability_id)
	return unlocked
