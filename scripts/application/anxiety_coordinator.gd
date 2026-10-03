class_name AnxietyCoordinator
extends RefCounted

var _state: GameSessionState

func _init(state: GameSessionState) -> void:
	_state = state

func tick(delta: float) -> bool:
	return AnxietyRules.tick(_state, delta)
