class_name ContentCatalog
extends RefCounted

const CLOCK_SETTINGS_PATH: String = "res://data/time/game_clock_settings.tres"
const LOCATION_PATHS: Dictionary = {
	&"home": "res://data/locations/home.tres",
	&"school": "res://data/locations/school.tres",
	&"supermarket": "res://data/locations/supermarket.tres",
	&"gym": "res://data/locations/gym.tres"
}
const ENCOUNTER_PATHS: Dictionary = {
	&"family_good_news": "res://data/encounters/family_good_news.tres"
}
const EVENT_PATHS: Dictionary = {
	&"family_good_news": "res://data/story/events/family_good_news.tres",
	&"family_follow_up": "res://data/story/events/family_follow_up.tres"
}

var _pack_loader: ContentPackLoader = ContentPackLoader.new()
var _problem_graph_nodes_loaded: bool = false
var _problem_graph_nodes: Dictionary = {}

func get_clock_settings() -> GameClockSettings:
	return load(CLOCK_SETTINGS_PATH) as GameClockSettings

func get_encounter(encounter_id: StringName) -> EncounterDefinition:
	var path: String = str(ENCOUNTER_PATHS.get(encounter_id, ""))
	return load(path) as EncounterDefinition if not path.is_empty() else null

func get_event(event_id: StringName) -> StoryEventDefinition:
	var path: String = str(EVENT_PATHS.get(event_id, ""))
	return load(path) as StoryEventDefinition if not path.is_empty() else null

func get_time_triggered_events() -> Array[StoryEventDefinition]:
	var result: Array[StoryEventDefinition] = []
	for event_id in EVENT_PATHS:
		var event := get_event(event_id)
		if event != null and event.start_policy == StoryEventDefinition.StartPolicy.TIME_TRIGGERED:
			result.append(event)
	return result

func get_location(location_id: StringName) -> LocationDefinition:
	var path: String = str(LOCATION_PATHS.get(location_id, ""))
	if path.is_empty():
		return null
	return load(path) as LocationDefinition

func get_problem_graph_nodes() -> Array[ProblemGraphNodeDefinition]:
	_load_problem_graph_nodes()
	var ids := _problem_graph_nodes.keys()
	ids.sort_custom(func(left: Variant, right: Variant) -> bool: return str(left) < str(right))
	var definitions: Array[ProblemGraphNodeDefinition] = []
	for node_id in ids:
		definitions.append(_problem_graph_nodes[node_id] as ProblemGraphNodeDefinition)
	return definitions

func get_problem_graph_node(node_id: StringName) -> ProblemGraphNodeDefinition:
	_load_problem_graph_nodes()
	return _problem_graph_nodes.get(node_id) as ProblemGraphNodeDefinition

func _load_problem_graph_nodes() -> void:
	if _problem_graph_nodes_loaded:
		return
	_problem_graph_nodes_loaded = true
	for document in _pack_loader.load_json_documents("problem_graph_nodes"):
		var data: Dictionary = document.get("data", {})
		var definition := ProblemGraphNodeDefinition.from_document(data)
		if definition.node_id == &"" or definition.title.is_empty() or definition.grid_position.x < 0 or definition.grid_position.y < 0:
			push_warning("Ignoring invalid problem graph node definition: %s" % str(document.get("source_path", "")))
			continue
		if _problem_graph_nodes.has(definition.node_id):
			push_warning("Ignoring duplicate problem graph node ID: %s" % String(definition.node_id))
			continue
		_problem_graph_nodes[definition.node_id] = definition
	var nodes_to_remove: Array[StringName] = []
	for node_id in _problem_graph_nodes:
		var definition := _problem_graph_nodes[node_id] as ProblemGraphNodeDefinition
		for related_id in definition.parent_ids + definition.required_node_ids:
			if not _problem_graph_nodes.has(related_id):
				push_warning("Ignoring graph node '%s': referenced node '%s' does not exist." % [String(node_id), String(related_id)])
				nodes_to_remove.append(node_id)
				break
	for node_id in nodes_to_remove:
		_problem_graph_nodes.erase(node_id)
