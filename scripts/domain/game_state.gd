class_name GameSessionState
extends RefCounted

var day_number: int = 1
var minute_of_day: int = 480
var anxiety: float = 22.0
var anxiety_effect_id: StringName = &""
var anxiety_effect_seconds: float = 0.0
var relationship_values: Dictionary = {&"family": 0}
var daily_action_ids: Array[StringName] = []
var location_result_text: Dictionary = {}
var story_facts: Dictionary = {}
var life_stage_id: StringName = &""
var outcome_journal: Array[StoryOutcomeRecord] = []
var pending_event_ids: Array[StringName] = []
var active_encounter: Dictionary = {}

func has_action_been_used(action_id: StringName) -> bool:
	return daily_action_ids.has(action_id)

func record_daily_action(action_id: StringName) -> bool:
	if action_id == &"" or daily_action_ids.has(action_id):
		return false
	daily_action_ids.append(action_id)
	return true

func has_completed_event(event_id: StringName) -> bool:
	for record in outcome_journal:
		if record.event_id == event_id:
			return true
	return false

func has_completed_outcome(event_id: StringName, outcome_id: StringName) -> bool:
	for record in outcome_journal:
		if record.event_id == event_id and record.outcome_id == outcome_id:
			return true
	return false

func has_completed_event_today(event_id: StringName) -> bool:
	for record in outcome_journal:
		if record.event_id == event_id and record.day_number == day_number:
			return true
	return false
