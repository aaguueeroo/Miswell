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
