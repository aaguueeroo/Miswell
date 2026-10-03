class_name SessionStateFactory
extends RefCounted

static func create_new_game_state(settings: GameClockSettings) -> GameSessionState:
	var state := GameSessionState.new()
	if settings != null and settings.is_valid():
		state.day_number = settings.start_day_number
		state.minute_of_day = settings.start_minute_of_day
	return state
