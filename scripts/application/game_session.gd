class_name GameSession
extends RefCounted

enum SimulationMode { EXPLORATION, ENCOUNTER, BLOCKING_UI, PAUSED }

var state: GameSessionState
var content_catalog: ContentCatalog
var clock: WorldClockCoordinator
var daily_transitions: DailyTransitionCoordinator
var anxiety: AnxietyCoordinator
var exploration: WorldExplorationCoordinator
var story: StoryProgressionCoordinator
var encounters: EncounterCoordinator
var simulation_mode: SimulationMode = SimulationMode.EXPLORATION

func _init(restored_state: GameSessionState = null, fractional_game_minutes: float = 0.0) -> void:
	content_catalog = ContentCatalog.new()
	var clock_settings := content_catalog.get_clock_settings()
	state = restored_state if restored_state != null else SessionStateFactory.create_new_game_state(clock_settings)
	clock = WorldClockCoordinator.new(state, clock_settings, fractional_game_minutes)
	daily_transitions = DailyTransitionCoordinator.new(state)
	anxiety = AnxietyCoordinator.new(state)
	exploration = WorldExplorationCoordinator.new(state, content_catalog)
	story = StoryProgressionCoordinator.new(state, content_catalog)
	encounters = EncounterCoordinator.new(state, content_catalog, story)

func set_simulation_mode(mode: SimulationMode) -> void:
	simulation_mode = mode

func tick(real_delta: float) -> SessionUpdate:
	var midnights := 0
	var anxiety_effect_ended := false
	var requests: Array[EncounterStartRequest] = []
	if simulation_mode == SimulationMode.EXPLORATION:
		anxiety_effect_ended = anxiety.tick(real_delta)
		var result := clock.advance(real_delta)
		midnights = result.midnights_crossed
		if midnights > 0:
			daily_transitions.apply_midnights(midnights)
		requests = story.evaluate_time_events()
	var update := SessionUpdate.new(state.day_number, state.minute_of_day, clock.get_phase(), midnights)
	update.encounter_requests = requests
	update.anxiety_effect_ended = anxiety_effect_ended
	return update

func begin_encounter(request: EncounterStartRequest) -> Dictionary:
	var result := encounters.begin_encounter(request)
	if result.get("ok", false):
		simulation_mode = SimulationMode.ENCOUNTER
	return result

func choose_encounter(choice_id: StringName) -> Dictionary:
	return encounters.choose(choice_id)

func close_encounter_result() -> void:
	encounters.close_result()
	simulation_mode = SimulationMode.EXPLORATION

func resolve_family_follow_up() -> Dictionary:
	if state.has_action_been_used(&"family_follow_up"):
		return {"ok": false, "title": "A quiet moment", "message": "You have already checked in with your family today."}
	return story.resolve_automatic_event(&"family_follow_up", &"player_interaction")
