class_name GameSession
extends RefCounted

var state: GameState
var content_catalog: ContentCatalog
var dialogue: DialogueEncounterCoordinator
var day_flow: DayLoopCoordinator
var anxiety: AnxietyCoordinator
var exploration: WorldExplorationCoordinator

func _init() -> void:
	state = GameState.new()
	content_catalog = ContentCatalog.new()
	day_flow = DayLoopCoordinator.new(state)
	dialogue = DialogueEncounterCoordinator.new(state, content_catalog, day_flow)
	anxiety = AnxietyCoordinator.new(state)
	exploration = WorldExplorationCoordinator.new(state, content_catalog, day_flow)
