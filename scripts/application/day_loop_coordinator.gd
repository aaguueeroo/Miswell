class_name DayLoopCoordinator
extends RefCounted

const SLOT_IDS: Array[StringName] = [&"morning", &"afternoon", &"evening"]
const SLOT_LABELS: Array[String] = ["Morning", "Afternoon", "Evening"]

var _state: GameState

func _init(state: GameState) -> void:
	_state = state
	_reset_schedule()

func status_text() -> String:
	return "DAY %d  ·  PLAN YOUR DAY" % _state.day_number

func timeline_view() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for index in range(SLOT_LABELS.size()):
		var slot := _state.day_schedule[index]
		var activity_id := str(slot.get("activity_id", ""))
		result.append({
			"slot_index": index,
			"slot_id": SLOT_IDS[index],
			"label": SLOT_LABELS[index],
			"activity": str(slot.get("activity_label", "")),
			"status": "scheduled" if not activity_id.is_empty() else "open"
		})
	return result

func available_slots(allowed_slots: Array[StringName]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for index in range(_state.day_schedule.size()):
		var slot := _state.day_schedule[index]
		if not str(slot.get("activity_id", "")).is_empty():
			continue
		if not allowed_slots.is_empty() and not allowed_slots.has(SLOT_IDS[index]):
			continue
		result.append({
			"slot_index": index,
			"slot_id": SLOT_IDS[index],
			"label": SLOT_LABELS[index]
		})
	return result

func has_open_slot() -> bool:
	for slot in _state.day_schedule:
		if str(slot.get("activity_id", "")).is_empty():
			return true
	return false

func assign_activity(activity_id: StringName, activity_label: String, slot_index: int) -> Dictionary:
	if slot_index < 0 or slot_index >= SLOT_IDS.size():
		return {"ok": false, "message": "Choose a valid time slot."}
	if _state.visited_activity_ids.has(activity_id):
		return {"ok": false, "message": "That activity is already in today's schedule."}
	var slot := _state.day_schedule[slot_index]
	if not str(slot.get("activity_id", "")).is_empty():
		return {"ok": false, "message": "That time slot is already booked. Choose an open slot."}
	slot["activity_id"] = String(activity_id)
	slot["activity_label"] = activity_label
	_state.day_schedule[slot_index] = slot
	_state.visited_activity_ids.append(activity_id)
	return {
		"ok": true,
		"slot_label": SLOT_LABELS[slot_index],
		"message": "%s is planned for %s." % [activity_label, SLOT_LABELS[slot_index]]
	}

func slot_for_activity(activity_id: StringName) -> String:
	for index in range(_state.day_schedule.size()):
		if str(_state.day_schedule[index].get("activity_id", "")) == String(activity_id):
			return SLOT_LABELS[index]
	return ""

func finish_day() -> Dictionary:
	var schedule_text := _schedule_summary(_state.day_schedule)
	if _state.day_number == 1:
		if not _state.family_outcome_chosen:
			_state.family_opportunity_preserved = false
			if not _state.family_encounter_seen:
				_state.last_consequence_text = "The family moment was not part of today's plan."
			_state.family_trust = clampi(_state.family_trust - 1, -3, 3)
		_state.previous_day_schedule = _state.day_schedule.duplicate(true)
		_state.day_schedule.clear()
		_state.visited_activity_ids.clear()
		_state.location_result_text.clear()
		_state.day_number = 2
		_state.anxiety = maxf(0.0, _state.anxiety - 12.0)
		_state.anxiety_effect_id = &""
		_state.anxiety_effect_seconds = 0.0
		_reset_schedule()
		return {
			"complete": false,
			"title": "The next morning",
			"message": "%s\n\n%s" % [_state.last_consequence_text, schedule_text]
		}
	_state.previous_day_schedule = _state.day_schedule.duplicate(true)
	_state.day_number = 3
	return {
		"complete": true,
		"title": "End of the prototype",
		"message": "You explored the village and gave the day its own shape.\n\n%s" % schedule_text
	}

func _reset_schedule() -> void:
	_state.day_schedule.clear()
	for index in range(SLOT_IDS.size()):
		_state.day_schedule.append({
			"slot_id": String(SLOT_IDS[index]),
			"slot_label": SLOT_LABELS[index],
			"activity_id": "",
			"activity_label": ""
		})

func _schedule_summary(schedule: Array[Dictionary]) -> String:
	var summary := "Your day, in order:"
	for slot in schedule:
		var activity := str(slot.get("activity_label", ""))
		if activity.is_empty():
			activity = "Free time"
		summary += "\n%s  ·  %s" % [str(slot.get("slot_label", "")), activity]
	return summary

