class_name WorldClockCoordinator
extends RefCounted

const DEBUG_TIME_SCALES = [1, 8, 16]

var _state: GameSessionState
var _settings: GameClockSettings
var _fractional_game_minutes: float = 0.0
var _time_scale: float = 1.0

func _init(state: GameSessionState, settings: GameClockSettings, fractional_game_minutes: float = 0.0) -> void:
	_state = state
	_settings = settings
	_fractional_game_minutes = clampf(fractional_game_minutes, 0.0, 0.999999)

func advance(real_delta: float) -> ClockAdvanceResult:
	var result := GameClockRules.advance(
		_state.day_number,
		_state.minute_of_day,
		_fractional_game_minutes,
		real_delta * _time_scale,
		_settings
	)
	_state.day_number = result.day_number
	_state.minute_of_day = result.minute_of_day
	_fractional_game_minutes = result.fractional_game_minutes
	return result

func get_phase() -> StringName:
	return GameClockRules.phase_for_minute(_state.minute_of_day, _settings)

func get_fractional_game_minutes() -> float:
	return _fractional_game_minutes

func set_time_scale(multiplier: int) -> void:
	if DEBUG_TIME_SCALES.has(multiplier):
		_time_scale = float(multiplier)
