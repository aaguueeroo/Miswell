class_name GameClockSettings
extends Resource

@export var start_day_number: int = 1
@export_range(0, 1439, 1) var start_minute_of_day: int = 480
@export var game_minutes_per_real_second: float = 2.0
@export_range(0, 1439, 1) var day_start_minute: int = 360
@export_range(0, 1439, 1) var night_start_minute: int = 1200

func is_valid() -> bool:
	return (
		start_day_number > 0
		and start_minute_of_day >= 0 and start_minute_of_day < 1440
		and game_minutes_per_real_second > 0.0
		and is_finite(game_minutes_per_real_second)
		and day_start_minute >= 0 and day_start_minute < night_start_minute
		and night_start_minute < 1440
	)
