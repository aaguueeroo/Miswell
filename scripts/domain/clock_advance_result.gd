class_name ClockAdvanceResult
extends RefCounted

var day_number: int = 1
var minute_of_day: int = 0
var fractional_game_minutes: float = 0.0
var midnights_crossed: int = 0

func _init(p_day: int = 1, p_minute: int = 0, p_fraction: float = 0.0, p_midnights: int = 0) -> void:
	day_number = p_day
	minute_of_day = p_minute
	fractional_game_minutes = p_fraction
	midnights_crossed = p_midnights
