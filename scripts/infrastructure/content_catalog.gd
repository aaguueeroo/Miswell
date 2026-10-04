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
var _external_conversations_loaded: bool = false
var _external_conversations: Dictionary = {}
var _external_story_events_loaded: bool = false
var _external_story_events: Dictionary = {}

func get_clock_settings() -> GameClockSettings:
	return load(CLOCK_SETTINGS_PATH) as GameClockSettings

func get_encounter(encounter_id: StringName) -> EncounterDefinition:
	var path: String = str(ENCOUNTER_PATHS.get(encounter_id, ""))
	if not path.is_empty():
		return load(path) as EncounterDefinition
	_load_external_conversations()
	return _external_conversations.get(encounter_id) as EncounterDefinition

func get_event(event_id: StringName) -> StoryEventDefinition:
	var path: String = str(EVENT_PATHS.get(event_id, ""))
	if not path.is_empty():
		return load(path) as StoryEventDefinition
	_load_external_story_events()
	return _external_story_events.get(event_id) as StoryEventDefinition

func get_time_triggered_events() -> Array[StoryEventDefinition]:
	var result: Array[StoryEventDefinition] = []
	for event_id in EVENT_PATHS:
		var event := get_event(event_id)
		if event != null and event.start_policy == StoryEventDefinition.StartPolicy.TIME_TRIGGERED:
			result.append(event)
	_load_external_story_events()
	for event in _external_story_events.values():
		var definition := event as StoryEventDefinition
		if definition != null and definition.start_policy == StoryEventDefinition.StartPolicy.TIME_TRIGGERED:
			result.append(definition)
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

func get_external_json_documents(content_type: String) -> Array[Dictionary]:
	return _pack_loader.load_json_documents(content_type)

func _load_external_conversations() -> void:
	if _external_conversations_loaded:
		return
	_external_conversations_loaded = true
	for document in _pack_loader.load_json_documents("conversations"):
		var data: Dictionary = document.get("data", {})
		var definition := EncounterDefinition.from_document(data)
		if definition == null or definition.encounter_id != StringName(document.get("id", &"")):
			push_warning("Ignoring invalid conversation definition: %s" % str(document.get("source_path", "")))
			continue
		var pack_prefix := String(document.get("pack_id", "")) + ":"
		var choice_ids: Dictionary = {}
		var valid_choices := true
		for choice_resource in definition.choices:
			var choice := choice_resource as EncounterChoiceDefinition
			if choice == null or not String(choice.choice_id).begins_with(pack_prefix) or choice_ids.has(choice.choice_id):
				valid_choices = false
				break
			choice_ids[choice.choice_id] = true
		if not valid_choices:
			push_warning("Ignoring conversation with invalid or duplicate namespaced choices: %s" % str(document.get("source_path", "")))
			continue
		if _external_conversations.has(definition.encounter_id):
			push_warning("Ignoring duplicate conversation ID: %s" % String(definition.encounter_id))
			continue
		_external_conversations[definition.encounter_id] = definition

func _load_external_story_events() -> void:
	if _external_story_events_loaded:
		return
	_external_story_events_loaded = true
	for document in _pack_loader.load_json_documents("story_events"):
		var data: Dictionary = document.get("data", {})
		var definition := StoryEventDefinition.from_document(data)
		if definition == null or definition.event_id != StringName(document.get("id", &"")):
			push_warning("Ignoring invalid story event definition: %s" % str(document.get("source_path", "")))
			continue
		var pack_prefix := String(document.get("pack_id", "")) + ":"
		var outcome_ids: Dictionary = {}
		var valid_outcomes := true
		for outcome_resource in definition.outcomes:
			var outcome := outcome_resource as StoryOutcomeDefinition
			if outcome == null or not String(outcome.outcome_id).begins_with(pack_prefix) or outcome_ids.has(outcome.outcome_id):
				valid_outcomes = false
				break
			outcome_ids[outcome.outcome_id] = true
		if not valid_outcomes:
			push_warning("Ignoring story event with invalid or duplicate namespaced outcomes: %s" % str(document.get("source_path", "")))
			continue
		var encounter := get_encounter(definition.encounter_id)
		if encounter == null:
			push_warning("Ignoring story event with missing conversation '%s': %s" % [String(definition.encounter_id), str(document.get("source_path", ""))])
			continue
		var references_valid_outcomes := true
		for choice_resource in encounter.choices:
			var choice := choice_resource as EncounterChoiceDefinition
			if choice == null or not outcome_ids.has(choice.outcome_id):
				references_valid_outcomes = false
				break
		if not references_valid_outcomes:
			push_warning("Ignoring story event whose conversation references an undefined outcome: %s" % str(document.get("source_path", "")))
			continue
		if _external_story_events.has(definition.event_id):
			push_warning("Ignoring duplicate story event ID: %s" % String(definition.event_id))
			continue
		_external_story_events[definition.event_id] = definition

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
