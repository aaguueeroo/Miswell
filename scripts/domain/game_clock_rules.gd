class_name GameClockRules
extends RefCounted

static func advance(day_number: int, minute_of_day: int, fractional_game_minutes: float, real_delta: float, settings: GameClockSettings) -> ClockAdvanceResult:
	var unchanged := ClockAdvanceResult.new(day_number, minute_of_day, fractional_game_minutes, 0)
	if settings == null or not settings.is_valid():
		return unchanged
	if day_number < 1 or minute_of_day < 0 or minute_of_day >= 1440:
		return unchanged
	if fractional_game_minutes < 0.0 or fractional_game_minutes >= 1.0:
		return unchanged
	if real_delta <= 0.0 or not is_finite(real_delta):
		return unchanged

	var accumulated := fractional_game_minutes + real_delta * settings.game_minutes_per_real_second
	if not is_finite(accumulated):
		return unchanged
	var whole_minutes := floori(accumulated)
	var absolute_minute := minute_of_day + whole_minutes
	var midnights := floori(float(absolute_minute) / 1440.0)
	return ClockAdvanceResult.new(
		day_number + midnights,
		posmod(absolute_minute, 1440),
		accumulated - float(whole_minutes),
		midnights
	)

static func phase_for_minute(minute_of_day: int, settings: GameClockSettings) -> StringName:
	if settings == null or not settings.is_valid() or minute_of_day < 0 or minute_of_day >= 1440:
		return &"night"
	if minute_of_day >= settings.day_start_minute and minute_of_day < settings.night_start_minute:
		return &"day"
	return &"night"
