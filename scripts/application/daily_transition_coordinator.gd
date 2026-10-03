class_name DailyTransitionCoordinator
extends RefCounted

var _state: GameSessionState

func _init(state: GameSessionState) -> void:
	_state = state

func apply_midnights(count: int) -> void:
	for _index in range(maxi(0, count)):
		_state.daily_action_ids.clear()
		_state.location_result_text.clear()
		_state.anxiety = maxf(0.0, _state.anxiety - 12.0)
		_state.anxiety_effect_id = &""
		_state.anxiety_effect_seconds = 0.0
