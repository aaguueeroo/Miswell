class_name WorldExplorationCoordinator
extends RefCounted

var _state: GameSessionState
var _content: ContentCatalog

func _init(state: GameSessionState, content: ContentCatalog) -> void:
	_state = state
	_content = content

func visit_location(location_id: StringName) -> Dictionary:
	var definition := _content.get_location(location_id)
	if definition == null:
		return {"kind": "error", "title": "Place unavailable", "message": "That location has no definition yet."}
	if location_id == &"home":
		return {"kind": "home"}
	if _state.has_action_been_used(location_id):
		return {
			"kind": "message",
			"title": definition.display_name + " is already visited",
			"message": "You have already visited this place today."
		}
	_state.record_daily_action(location_id)
	_state.location_result_text[location_id] = definition.visit_message
	if definition.family_trust_delta != 0:
		RelationshipRules.adjust(_state, &"family", definition.family_trust_delta)
	var anxiety_result := AnxietyRules.apply_delta(_state, definition.anxiety_delta)
	var result_message := definition.visit_message
	if anxiety_result.get("effect_activated", false):
		result_message += "\n\nAnxious focus is active. It may change which replies are available in a conversation."
	return {
		"kind": "message",
		"title": definition.display_name,
		"message": result_message,
		"effect_activated": anxiety_result.get("effect_activated", false)
	}

func get_location(location_id: StringName) -> LocationDefinition:
	return _content.get_location(location_id)

