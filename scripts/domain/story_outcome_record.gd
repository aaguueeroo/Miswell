class_name StoryOutcomeRecord
extends RefCounted

var event_id: StringName
var outcome_id: StringName
var day_number: int
var minute_of_day: int

func _init(p_event_id: StringName = &"", p_outcome_id: StringName = &"", p_day: int = 1, p_minute: int = 0) -> void:
	event_id = p_event_id
	outcome_id = p_outcome_id
	day_number = p_day
	minute_of_day = p_minute
