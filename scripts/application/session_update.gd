class_name SessionUpdate
extends RefCounted

var day_number: int = 1
var minute_of_day: int = 480
var phase: StringName = &"day"
var midnights_crossed: int = 0
var encounter_requests: Array[EncounterStartRequest] = []
var anxiety_effect_ended: bool = false

func _init(p_day: int = 1, p_minute: int = 480, p_phase: StringName = &"day", p_midnights: int = 0) -> void:
	day_number = p_day
	minute_of_day = p_minute
	phase = p_phase
	midnights_crossed = p_midnights
