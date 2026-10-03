class_name AnxietyCoordinator
extends RefCounted

var _state: GameState

func _init(state: GameState) -> void:
	_state = state

func tick(delta: float) -> bool:
	return AnxietyRules.tick(_state, delta)
