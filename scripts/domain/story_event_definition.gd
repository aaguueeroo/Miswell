class_name StoryEventDefinition
extends Resource

enum StartPolicy { PLAYER_INTERACTION, NPC_INTERACTION, TIME_TRIGGERED, STORY_TRIGGERED }

@export var event_id: StringName = &""
@export var start_policy: StartPolicy = StartPolicy.PLAYER_INTERACTION
@export var trigger_source: StringName = &"player_interaction"
@export var initiator_id: StringName = &""
@export var encounter_id: StringName = &""
@export var daily_action_id: StringName = &""
@export var repeatable: bool = false
@export var opens_on_day: int = 1
@export_range(0, 1439, 1) var opens_at_minute: int = 0
@export var closes_on_day: int = -1
@export_range(0, 1439, 1) var closes_at_minute: int = 1439
@export_range(0, 1439, 1) var trigger_at_minute: int = 0
@export var conditions: Array[Resource] = []
@export var outcomes: Array[Resource] = []

static func from_document(data: Dictionary) -> StoryEventDefinition:
	var result := StoryEventDefinition.new()
	result.event_id = StringName(str(data.get("id", "")))
	if result.event_id == &"":
		return null
	match str(data.get("start_policy", "")):
		"player_interaction":
			result.start_policy = StartPolicy.PLAYER_INTERACTION
		"npc_interaction":
			result.start_policy = StartPolicy.NPC_INTERACTION
		"time_triggered":
			result.start_policy = StartPolicy.TIME_TRIGGERED
		"story_triggered":
			result.start_policy = StartPolicy.STORY_TRIGGERED
		_:
			return null
	result.trigger_source = StringName(str(data.get("trigger_source", "")))
	result.initiator_id = StringName(str(data.get("initiator_id", "")))
	result.encounter_id = StringName(str(data.get("encounter_id", "")))
	result.daily_action_id = StringName(str(data.get("daily_action_id", "")))
	result.repeatable = bool(data.get("repeatable", false))
	result.opens_on_day = int(data.get("opens_on_day", 1))
	result.opens_at_minute = int(data.get("opens_at_minute", 0))
	result.closes_on_day = int(data.get("closes_on_day", -1))
	result.closes_at_minute = int(data.get("closes_at_minute", 1439))
	result.trigger_at_minute = int(data.get("trigger_at_minute", 0))
	if result.trigger_source == &"" or result.encounter_id == &"" or result.opens_on_day < 1:
		return null
	if result.opens_at_minute < 0 or result.opens_at_minute > 1439 or result.closes_at_minute < 0 or result.closes_at_minute > 1439 or result.trigger_at_minute < 0 or result.trigger_at_minute > 1439:
		return null
	var condition_documents: Variant = data.get("conditions", [])
	var outcome_documents: Variant = data.get("outcomes", [])
	if not condition_documents is Array or not outcome_documents is Array:
		return null
	for condition_data in condition_documents:
		if not condition_data is Dictionary:
			return null
		var condition := StoryConditionDefinition.from_document(condition_data)
		if condition == null:
			return null
		result.conditions.append(condition)
	for outcome_data in outcome_documents:
		if not outcome_data is Dictionary:
			return null
		var outcome := StoryOutcomeDefinition.from_document(outcome_data)
		if outcome == null:
			return null
		result.outcomes.append(outcome)
	if result.outcomes.is_empty():
		return null
	return result
