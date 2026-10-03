class_name EncounterCoordinator
extends RefCounted

var _state: GameSessionState
var _content: ContentCatalog
var _story: StoryProgressionCoordinator
var _active_definition: EncounterDefinition
var _active_request: EncounterStartRequest
var _encounter_active: bool = false

func _init(state: GameSessionState, content: ContentCatalog, story: StoryProgressionCoordinator) -> void:
	_state = state
	_content = content
	_story = story

func begin_encounter(request: EncounterStartRequest) -> Dictionary:
	if request == null or _encounter_active or not _state.active_encounter.is_empty():
		return {"ok": false, "message": "Another encounter is already active."}
	var event := _content.get_event(request.event_id)
	var definition := _content.get_encounter(request.encounter_id)
	if event == null or definition == null or event.encounter_id != request.encounter_id:
		return {"ok": false, "message": "That encounter is unavailable."}
	if not _story.is_event_available(request.event_id, request.trigger_source):
		return {"ok": false, "message": "That event is not available right now."}
	_active_request = request
	_active_definition = definition
	_encounter_active = true
	_state.active_encounter = {
		"event_id": String(request.event_id),
		"encounter_id": String(request.encounter_id),
		"initiator_id": String(request.initiator_id),
		"trigger_source": String(request.trigger_source),
		"active": true
	}
	return {"ok": true, "view": _build_view()}

func choose(choice_id: StringName) -> Dictionary:
	if not _encounter_active or _active_definition == null or _active_request == null:
		return {"ok": false, "message": "There is no active encounter."}
	for choice_resource in _active_definition.choices:
		var choice := choice_resource as EncounterChoiceDefinition
		if choice == null or choice.choice_id != choice_id:
			continue
		if choice.required_effect_id != &"" and choice.required_effect_id != _state.anxiety_effect_id:
			return {"ok": false, "message": "That reply is no longer available."}
		var effect_was_active := _state.anxiety_effect_id != &""
		if not _story.apply_outcome(_active_request.event_id, choice.outcome_id):
			return {"ok": false, "message": "That outcome is no longer available."}
		_encounter_active = false
		_state.active_encounter["active"] = false
		_state.active_encounter["outcome_id"] = String(choice.outcome_id)
		return {
			"ok": true,
			"kind": "complete",
			"title": choice.label,
			"message": choice.result_message,
			"effect_activated": not effect_was_active and _state.anxiety_effect_id != &""
		}
	return {"ok": false, "message": "That reply is no longer available."}

func is_encounter_active() -> bool:
	return _encounter_active

func close_result() -> void:
	_encounter_active = false
	_active_definition = null
	_active_request = null
	_state.active_encounter.clear()

func _build_view() -> Dictionary:
	var choices: Array[Resource] = []
	for resource in _active_definition.choices:
		var choice := resource as EncounterChoiceDefinition
		if choice == null:
			continue
		if choice.required_effect_id != &"" and choice.required_effect_id != _state.anxiety_effect_id:
			continue
		choices.append(choice)
	return {
		"encounter_id": _active_definition.encounter_id,
		"title": _active_definition.title,
		"body": _active_definition.prompt,
		"player_name": _active_definition.player_name,
		"opponent_name": _active_definition.opponent_name,
		"choices": choices
	}
