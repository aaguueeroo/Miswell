class_name ProblemGraphRules
extends RefCounted

static func can_unlock_node(state: GameSessionState, definition: ProblemGraphNodeDefinition, node_index: Dictionary) -> bool:
	if state == null or definition == null or definition.node_id == &"" or definition.is_category:
		return false
	if state.has_completed_problem_graph_node(definition.node_id):
		return true
	for required_id in definition.required_node_ids:
		if not node_index.has(required_id) or not state.has_completed_problem_graph_node(required_id):
			return false
	return true

static func mark_node_complete(state: GameSessionState, definition: ProblemGraphNodeDefinition, node_index: Dictionary, bypass_prerequisites: bool = false) -> bool:
	if state == null or definition == null or definition.node_id == &"" or definition.is_category:
		return false
	if state.has_completed_problem_graph_node(definition.node_id):
		return true
	if not bypass_prerequisites and not can_unlock_node(state, definition, node_index):
		return false
	state.completed_problem_graph_node_ids.append(definition.node_id)
	return true
