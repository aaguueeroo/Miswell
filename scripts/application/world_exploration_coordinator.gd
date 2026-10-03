class_name WorldExplorationCoordinator
extends RefCounted

var _state: GameState
var _content: ContentCatalog
var _day_flow: DayLoopCoordinator

func _init(state: GameState, content: ContentCatalog, day_flow: DayLoopCoordinator) -> void:
	_state = state
	_content = content
	_day_flow = day_flow

func visit_location(location_id: StringName, slot_index: int) -> Dictionary:
	var definition := _content.get_location(location_id)
	if definition == null:
		return {"kind": "error", "title": "Place unavailable", "message": "That location has no definition yet."}
	if location_id == &"home":
		return {"kind": "home"}
	if _state.visited_activity_ids.has(location_id):
		return {
			"kind": "message",
			"title": definition.display_name + " is already planned",
			"message": "You have already added this place to today's schedule."
		}
	var schedule := _day_flow.assign_activity(location_id, definition.activity_label, slot_index)
	if not schedule.get("ok", false):
		return {
			"kind": "unavailable",
			"title": "Choose another slot",
			"message": str(schedule.get("message", "That time is unavailable."))
		}
	_state.location_result_text[location_id] = definition.visit_message
	_state.family_trust = clampi(_state.family_trust + definition.family_trust_delta, -3, 3)
	var anxiety_result := AnxietyRules.apply_delta(_state, definition.anxiety_delta)
	var result_message := definition.visit_message + "\n\n" + str(schedule.get("message", ""))
	if anxiety_result.get("effect_activated", false):
		result_message += "\n\nAnxious focus is active. It briefly reveals another dialogue reply."
	return {
		"kind": "message",
		"title": definition.display_name + " · " + str(schedule.get("slot_label", "")),
		"message": result_message,
		"effect_activated": anxiety_result.get("effect_activated", false)
	}

func get_location(location_id: StringName) -> LocationDefinition:
	return _content.get_location(location_id)

func get_available_slots(location_id: StringName) -> Array[Dictionary]:
	var definition := _content.get_location(location_id)
	if definition == null or location_id == &"home":
		return []
	return _day_flow.available_slots(definition.available_slots)

