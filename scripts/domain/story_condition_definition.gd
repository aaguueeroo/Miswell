class_name StoryConditionDefinition
extends Resource

enum ConditionKind { FACT_EXISTS, FACT_EQUALS_BOOL, OUTCOME_COMPLETED, DAY_RANGE, TIME_RANGE, LIFE_STAGE_EQUALS, ALL_OF, ANY_OF, PROBLEM_GRAPH_NODE_COMPLETED, ABILITY_UNLOCKED }

@export var kind: ConditionKind = ConditionKind.FACT_EXISTS
@export var fact_id: StringName = &""
@export var expected_bool: bool = false
@export var event_id: StringName = &""
@export var outcome_id: StringName = &""
@export var minimum_day: int = 1
@export var maximum_day: int = 999999
@export_range(0, 1439, 1) var start_minute: int = 0
@export_range(0, 1439, 1) var end_minute: int = 1439
@export var life_stage_id: StringName = &""
@export var graph_node_id: StringName = &""
@export var ability_id: StringName = &""
@export var conditions: Array[Resource] = []

static func from_document(data: Dictionary) -> StoryConditionDefinition:
	var result := StoryConditionDefinition.new()
	match str(data.get("kind", "")):
		"fact_exists":
			result.kind = ConditionKind.FACT_EXISTS
			result.fact_id = StringName(str(data.get("fact_id", "")))
			if result.fact_id == &"":
				return null
		"fact_equals_bool":
			result.kind = ConditionKind.FACT_EQUALS_BOOL
			result.fact_id = StringName(str(data.get("fact_id", "")))
			result.expected_bool = bool(data.get("expected_bool", false))
			if result.fact_id == &"":
				return null
		"outcome_completed":
			result.kind = ConditionKind.OUTCOME_COMPLETED
			result.event_id = StringName(str(data.get("event_id", "")))
			result.outcome_id = StringName(str(data.get("outcome_id", "")))
			if result.event_id == &"" or result.outcome_id == &"":
				return null
		"day_range":
			result.kind = ConditionKind.DAY_RANGE
			result.minimum_day = int(data.get("minimum_day", 1))
			result.maximum_day = int(data.get("maximum_day", 999999))
			if result.minimum_day < 1 or result.maximum_day < result.minimum_day:
				return null
		"time_range":
			result.kind = ConditionKind.TIME_RANGE
			result.start_minute = int(data.get("start_minute", 0))
			result.end_minute = int(data.get("end_minute", 1439))
			if result.start_minute < 0 or result.start_minute > 1439 or result.end_minute < 0 or result.end_minute > 1439:
				return null
		"life_stage_equals":
			result.kind = ConditionKind.LIFE_STAGE_EQUALS
			result.life_stage_id = StringName(str(data.get("life_stage_id", "")))
			if result.life_stage_id == &"":
				return null
		"problem_graph_node_completed":
			result.kind = ConditionKind.PROBLEM_GRAPH_NODE_COMPLETED
			result.graph_node_id = StringName(str(data.get("graph_node_id", "")))
			if result.graph_node_id == &"":
				return null
		"ability_unlocked":
			result.kind = ConditionKind.ABILITY_UNLOCKED
			result.ability_id = StringName(str(data.get("ability_id", "")))
			if result.ability_id == &"":
				return null
		"all_of", "any_of":
			result.kind = ConditionKind.ALL_OF if str(data.get("kind", "")) == "all_of" else ConditionKind.ANY_OF
			var nested_conditions: Variant = data.get("conditions", [])
			if not nested_conditions is Array:
				return null
			for nested_data in nested_conditions:
				if not nested_data is Dictionary:
					return null
				var nested_condition := from_document(nested_data)
				if nested_condition == null:
					return null
				result.conditions.append(nested_condition)
		_:
			return null
	return result
