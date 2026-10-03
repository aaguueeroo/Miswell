class_name StoryConditionDefinition
extends Resource

enum ConditionKind { FACT_EXISTS, FACT_EQUALS_BOOL, OUTCOME_COMPLETED, DAY_RANGE, TIME_RANGE, LIFE_STAGE_EQUALS, ALL_OF, ANY_OF }

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
@export var conditions: Array[Resource] = []
