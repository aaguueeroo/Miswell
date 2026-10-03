class_name GameSaveCodec
extends RefCounted

func encode_session(session: GameSession) -> Dictionary:
	return {
		"state": _encode_state(session.state),
		"fractional_game_minutes": session.clock.get_fractional_game_minutes()
	}

func decode_session(snapshot: Dictionary) -> GameSession:
	var state_data: Variant = snapshot.get("state", null)
	if not state_data is Dictionary:
		return null
	var restored_state := _decode_state(state_data)
	if restored_state == null:
		return null
	var fractional_minutes := float(snapshot.get("fractional_game_minutes", 0.0))
	if not is_finite(fractional_minutes) or fractional_minutes < 0.0 or fractional_minutes >= 1.0:
		return null
	return GameSession.new(restored_state, fractional_minutes)

func _encode_state(state: GameSessionState) -> Dictionary:
	var relationships: Dictionary = {}
	for character_id in state.relationship_values:
		relationships[String(character_id)] = state.relationship_values[character_id]
	var daily_actions: Array[String] = []
	for action_id in state.daily_action_ids:
		daily_actions.append(String(action_id))
	var location_results: Dictionary = {}
	for location_id in state.location_result_text:
		location_results[String(location_id)] = str(state.location_result_text[location_id])
	var outcomes: Array[Dictionary] = []
	for outcome_record in state.outcome_journal:
		if outcome_record == null:
			continue
		outcomes.append({
			"event_id": String(outcome_record.event_id),
			"outcome_id": String(outcome_record.outcome_id),
			"day_number": outcome_record.day_number,
			"minute_of_day": outcome_record.minute_of_day
		})
	var pending_events: Array[String] = []
	for event_id in state.pending_event_ids:
		pending_events.append(String(event_id))
	return {
		"day_number": state.day_number,
		"minute_of_day": state.minute_of_day,
		"anxiety": state.anxiety,
		"anxiety_effect_id": String(state.anxiety_effect_id),
		"anxiety_effect_seconds": state.anxiety_effect_seconds,
		"relationship_values": relationships,
		"daily_action_ids": daily_actions,
		"location_result_text": location_results,
		"story_facts": _to_json_value(state.story_facts),
		"life_stage_id": String(state.life_stage_id),
		"outcome_journal": outcomes,
		"pending_event_ids": pending_events,
		"active_encounter": _to_json_value(state.active_encounter)
	}

func _decode_state(data: Dictionary) -> GameSessionState:
	var restored_day := int(data.get("day_number", 0))
	var restored_minute := int(data.get("minute_of_day", -1))
	var restored_anxiety := float(data.get("anxiety", NAN))
	var restored_effect_seconds := float(data.get("anxiety_effect_seconds", NAN))
	if restored_day < 1 or restored_minute < 0 or restored_minute >= 1440:
		return null
	if not is_finite(restored_anxiety) or not is_finite(restored_effect_seconds):
		return null
	var state := GameSessionState.new()
	state.day_number = restored_day
	state.minute_of_day = restored_minute
	state.anxiety = clampf(restored_anxiety, 0.0, 100.0)
	state.anxiety_effect_id = StringName(str(data.get("anxiety_effect_id", "")))
	state.anxiety_effect_seconds = maxf(restored_effect_seconds, 0.0)
	var relationships: Variant = data.get("relationship_values", {})
	if not relationships is Dictionary:
		return null
	state.relationship_values.clear()
	for character_id in relationships:
		state.relationship_values[StringName(str(character_id))] = int(relationships[character_id])
	var daily_actions: Variant = data.get("daily_action_ids", [])
	if not daily_actions is Array:
		return null
	for action_id in daily_actions:
		state.daily_action_ids.append(StringName(str(action_id)))
	var location_results: Variant = data.get("location_result_text", {})
	if not location_results is Dictionary:
		return null
	for location_id in location_results:
		state.location_result_text[StringName(str(location_id))] = str(location_results[location_id])
	var facts: Variant = data.get("story_facts", {})
	if not facts is Dictionary:
		return null
	state.story_facts = _from_json_dictionary(facts, true)
	state.life_stage_id = StringName(str(data.get("life_stage_id", "")))
	var outcomes: Variant = data.get("outcome_journal", [])
	if not outcomes is Array:
		return null
	for value in outcomes:
		if not value is Dictionary:
			return null
		var record_day := int(value.get("day_number", 0))
		var record_minute := int(value.get("minute_of_day", -1))
		if record_day < 1 or record_minute < 0 or record_minute >= 1440:
			return null
		state.outcome_journal.append(StoryOutcomeRecord.new(
			StringName(str(value.get("event_id", ""))),
			StringName(str(value.get("outcome_id", ""))),
			record_day,
			record_minute
		))
	var pending_events: Variant = data.get("pending_event_ids", [])
	if not pending_events is Array:
		return null
	for event_id in pending_events:
		state.pending_event_ids.append(StringName(str(event_id)))
	var encounter: Variant = data.get("active_encounter", {})
	if not encounter is Dictionary:
		return null
	state.active_encounter = _from_json_dictionary(encounter, false)
	return state

func _to_json_value(value: Variant) -> Variant:
	match typeof(value):
		TYPE_STRING_NAME:
			return String(value)
		TYPE_DICTIONARY:
			var converted_dictionary: Dictionary = {}
			for key in value:
				converted_dictionary[String(key)] = _to_json_value(value[key])
			return converted_dictionary
		TYPE_ARRAY:
			var converted_array: Array = []
			for item in value:
				converted_array.append(_to_json_value(item))
			return converted_array
		TYPE_VECTOR2:
			return [value.x, value.y]
		TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING:
			return value
		_:
			return null

func _from_json_dictionary(data: Dictionary, name_keys: bool) -> Dictionary:
	var converted: Dictionary = {}
	for key in data:
		var restored_key: Variant = StringName(str(key)) if name_keys else str(key)
		converted[restored_key] = _from_json_value(data[key], name_keys)
	return converted

func _from_json_value(value: Variant, name_keys: bool) -> Variant:
	if value is Dictionary:
		return _from_json_dictionary(value, name_keys)
	if value is Array:
		var converted_array: Array = []
		for item in value:
			converted_array.append(_from_json_value(item, name_keys))
		return converted_array
	return value
