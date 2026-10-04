extends Node2D

const CURSOR_ARROW: Texture2D = preload("res://assets/gui/kenney_cursor-pixel-pack/arrow_cursor.png")
const CURSOR_HAND: Texture2D = preload("res://assets/gui/kenney_cursor-pixel-pack/hand_cursor.png")
const BATTLE_SCENE: PackedScene = preload("res://scenes/battle/battle_scene.tscn")
const PROBLEM_GRAPH_SCENE: PackedScene = preload("res://scenes/graph/problem_graph_scene.tscn")
const TRANSITION_SCENE: PackedScene = preload("res://scenes/ui/scene_transition.tscn")
const HOME_INTERIOR: PackedScene = preload("res://scenes/interiors/home_interior.tscn")
const SCHOOL_INTERIOR: PackedScene = preload("res://scenes/interiors/school_interior.tscn")
const SUPERMARKET_INTERIOR: PackedScene = preload("res://scenes/interiors/supermarket_interior.tscn")
const GYM_INTERIOR: PackedScene = preload("res://scenes/interiors/gym_interior.tscn")
const INITIAL_PLAYER_POSITION := Vector2(520.0, 940.0)

@onready var _world_simulation: Node2D = $WorldSimulation
@onready var _village: Node2D = $WorldSimulation/Village
@onready var _player: PlayerActor = $WorldSimulation/Player
@onready var _family: FamilyNpc = $WorldSimulation/Family
@onready var _village_map: VillageMapRoot = $WorldSimulation/Village/CityMap
@onready var _world_lighting: WorldLighting = $WorldSimulation/WorldLighting

var _session: GameSession
var _save_slots: SaveSlotService
var _hud: GameHUD
var _game_audio: GameAudio
var _panel_mode: String = "exploration"
var _location_actors: Array[LocationActor] = []
var _npc_actors: Array[NpcActor] = []
var _current_target: Node2D
var _current_target_id: StringName = &""
var _battle_scene: BattleScene
var _placeholder_battle_active: bool = false
var _problem_graph_scene: ProblemGraphScene
var _pending_save_slot: StringName = &""
var _active_interior: BuildingInterior
var _scene_transition: SceneTransition
var _scene_id: StringName = &"village"
var _transitioning: bool = false

func _enter_tree() -> void:
	# The app and its menus keep processing while the world simulation is paused.
	process_mode = Node.PROCESS_MODE_ALWAYS

func _ready() -> void:
	_on_simulation_mode_changed(GameSession.SimulationMode.PAUSED)
	if not GameHUD.is_mobile_platform():
		Input.set_custom_mouse_cursor(CURSOR_ARROW, Input.CURSOR_ARROW, Vector2(1.0, 1.0))
		Input.set_custom_mouse_cursor(CURSOR_HAND, Input.CURSOR_POINTING_HAND, Vector2(6.0, 1.0))
	_save_slots = SaveSlotService.new()
	_game_audio = GameAudio.new()
	_game_audio.name = "GameAudio"
	add_child(_game_audio)
	for candidate in get_tree().get_nodes_in_group("locations"):
		var location := candidate as LocationActor
		if location != null:
			_location_actors.append(location)
			location.door_crossed.connect(_on_outdoor_door_crossed)
	_collect_npcs()
	_hud = GameHUD.new()
	add_child(_hud)
	_scene_transition = TRANSITION_SCENE.instantiate() as SceneTransition
	add_child(_scene_transition)
	_hud.message_action_requested.connect(_resume_exploration)
	_hud.restart_requested.connect(_restart)
	_hud.new_game_requested.connect(_start_new_game)
	_hud.continue_requested.connect(_show_continue_slots)
	_hud.slot_selected.connect(_on_slot_selected)
	_hud.overwrite_confirmed.connect(_confirm_save_overwrite)
	_hud.back_requested.connect(_on_menu_back)
	_hud.pause_requested.connect(_open_pause_menu)
	_hud.problem_graph_requested.connect(_open_problem_graph)
	_hud.resume_requested.connect(_resume_from_pause)
	_hud.save_requested.connect(_show_save_slots)
	_hud.time_speed_requested.connect(_on_time_speed_requested)
	_hud.ui_click_requested.connect(_game_audio.play_ui_click)
	_hud.ui_hover_requested.connect(_game_audio.play_ui_hover)
	_hud.touch_direction_changed.connect(_player.set_touch_direction)
	_player.interact_requested.connect(_attempt_interact)
	_player.footstep_requested.connect(_play_player_footstep)
	_player.set_controls_enabled(false)
	_world_simulation.visible = false
	_show_welcome()

func _process(delta: float) -> void:
	if _session == null:
		return
	var update := _session.tick(delta)
	_update_world_lighting()
	if update.encounter_requests.size() > 0 and _session.simulation_mode == GameSession.SimulationMode.EXPLORATION:
		_start_encounter(update.encounter_requests[0])
		return
	if update.anxiety_effect_ended:
		_hud.set_notice("Anxious focus passed. The moment settles.")
	if _panel_mode == "exploration":
		_refresh_current_target()
		_update_context_action()
	_update_status(update)

func _unhandled_input(event: InputEvent) -> void:
	if _transitioning:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_G and _panel_mode == "exploration":
		_open_problem_graph()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		match _panel_mode:
			"exploration":
				_open_pause_menu()
			"pause":
				_resume_from_pause()
			"continue_slots":
				_show_welcome()
			"save_slots":
				_open_pause_menu()
			"overwrite_confirmation":
				_show_save_slots()
			"problem_graph":
				_close_problem_graph()
			_:
				return
		get_viewport().set_input_as_handled()
		return
	if not GameHUD.is_mobile_platform() or _panel_mode != "exploration":
		return
	if event is InputEventScreenTouch and event.pressed:
		_try_mobile_tap(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_try_mobile_tap(event.position)

func _try_mobile_tap(screen_position: Vector2) -> void:
	if not _can_interact_with_current_target():
		return
	var anchor_screen := _world_to_screen(_get_current_interaction_anchor())
	if screen_position.distance_to(anchor_screen) <= 62.0:
		_attempt_interact()
		get_viewport().set_input_as_handled()

func _refresh_current_target() -> void:
	var nearest: Node2D
	var nearest_distance := VillageMapConfig.INTERACTION_RADIUS + 1.0
	for location in _location_actors:
		if not is_instance_valid(location) or not location.is_visible_in_tree() or location.definition == null:
			continue
		var distance := _player.global_position.distance_to(location.get_interaction_anchor())
		if distance <= nearest_distance:
			nearest = location
			nearest_distance = distance
	for npc in _npc_actors:
		if not is_instance_valid(npc) or not npc.is_visible_in_tree():
			continue
		var npc_distance := _player.global_position.distance_to(npc.get_interaction_anchor())
		if npc_distance <= nearest_distance:
			nearest = npc
			nearest_distance = npc_distance
	if _active_interior != null:
		for action in _active_interior.get_action_spots():
			if action.location_id != &"home" and _session.state.has_action_been_used(action.location_id):
				continue
			var action_distance := _player.global_position.distance_to(action.get_interaction_anchor())
			if action_distance <= nearest_distance:
				nearest = action
				nearest_distance = action_distance
	_current_target = nearest
	if _current_target is NpcActor:
		_current_target_id = (_current_target as NpcActor).story_actor_id
	elif _current_target is LocationActor:
		var location := _current_target as LocationActor
		_current_target_id = location.definition.location_id if location.definition != null else &""
	elif _current_target is InteriorAction:
		_current_target_id = (_current_target as InteriorAction).location_id
	else:
		_current_target_id = &""

func _can_interact_with_current_target() -> bool:
	if _current_target == null or _transitioning:
		return false
	if _current_target is LocationActor or _current_target is NpcActor:
		return true
	if _current_target_id == &"home":
		return true
	return not _session.state.has_action_been_used(_current_target_id)

func _get_current_interaction_anchor() -> Vector2:
	if _current_target is NpcActor:
		return (_current_target as NpcActor).get_interaction_anchor()
	if _current_target is LocationActor:
		return (_current_target as LocationActor).get_interaction_anchor()
	if _current_target is InteriorAction:
		return (_current_target as InteriorAction).get_interaction_anchor()
	return _player.global_position

func _world_to_screen(world_position: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform() * world_position

func _update_context_action() -> void:
	if not _can_interact_with_current_target() or _panel_mode != "exploration":
		_hud.set_context_action(Vector2.ZERO, false)
		return
	var anchor_screen := _world_to_screen(_get_current_interaction_anchor())
	_hud.set_context_action(anchor_screen, true)

func _play_player_footstep() -> void:
	var feet_position := _player.global_position + Vector2(0.0, 12.0)
	if _active_interior != null:
		_game_audio.play_footstep(_active_interior.get_footstep_surface(feet_position))
	else:
		_game_audio.play_footstep(_village_map.get_footstep_surface(feet_position))

func _attempt_interact() -> void:
	if _panel_mode != "exploration" or _transitioning:
		return
	_refresh_current_target()
	if _current_target == null:
		return
	_game_audio.play_ui_click()
	if _current_target is LocationActor:
		_begin_enter_interior(_current_target_id)
		return
	if _current_target is NpcActor:
		var npc := _current_target as NpcActor
		if npc.opens_battle_ui_on_interaction:
			_start_placeholder_conversation(npc)
		else:
			_show_message(npc.display_name, npc.dialogue_text)
		return
	if _current_target_id == &"home":
		_show_message("Home", "A familiar place to pause. The day continues when you return to exploring.")
		return
	var result := _session.exploration.visit_location(_current_target_id)
	_update_status()
	_show_message(str(result.get("title", "Place unavailable")), str(result.get("message", "This place does not have activity data.")))

func _collect_npcs() -> void:
	_npc_actors.clear()
	for candidate in get_tree().get_nodes_in_group("npcs"):
		var npc := candidate as NpcActor
		if npc != null:
			_npc_actors.append(npc)

func _interior_scene_for(building_id: StringName) -> PackedScene:
	match building_id:
		&"home":
			return HOME_INTERIOR
		&"school":
			return SCHOOL_INTERIOR
		&"supermarket":
			return SUPERMARKET_INTERIOR
		&"gym":
			return GYM_INTERIOR
	return null

func _location_for(building_id: StringName) -> LocationActor:
	for location in _location_actors:
		if is_instance_valid(location) and location.definition != null and location.definition.location_id == building_id:
			return location
	return null

func _on_outdoor_door_crossed(building_id: StringName) -> void:
	_begin_enter_interior(building_id)

func _begin_enter_interior(building_id: StringName) -> void:
	if _transitioning or _panel_mode != "exploration" or _scene_id != &"village":
		return
	if _interior_scene_for(building_id) == null:
		return
	var location := _location_for(building_id)
	var title: String = location.definition.display_name if location != null else String(building_id).capitalize()
	_transitioning = true
	_session.set_simulation_mode(GameSession.SimulationMode.BLOCKING_UI)
	_player.set_controls_enabled(false)
	_hud.set_context_action(Vector2.ZERO, false)
	await _scene_transition.fade_through(title, _set_area.bind(building_id, Vector2.ZERO, false))
	_transitioning = false
	_session.set_simulation_mode(GameSession.SimulationMode.EXPLORATION)
	_player.set_controls_enabled(true)
	_refresh_current_target()
	_update_context_action()

func _begin_exit_interior(building_id: StringName) -> void:
	if _transitioning or _panel_mode != "exploration" or _scene_id != building_id:
		return
	var location := _location_for(building_id)
	var return_position: Vector2 = location.global_position + Vector2(0.0, 48.0) if location != null else INITIAL_PLAYER_POSITION
	_transitioning = true
	_session.set_simulation_mode(GameSession.SimulationMode.BLOCKING_UI)
	_player.set_controls_enabled(false)
	_hud.set_context_action(Vector2.ZERO, false)
	await _scene_transition.fade_through("Village", _set_area.bind(&"village", return_position, true))
	_transitioning = false
	_session.set_simulation_mode(GameSession.SimulationMode.EXPLORATION)
	_player.set_controls_enabled(true)
	_refresh_current_target()
	_update_context_action()

func _set_area(area_id: StringName, position: Vector2, use_saved_position: bool) -> void:
	if _active_interior != null:
		_world_simulation.remove_child(_active_interior)
		_active_interior.queue_free()
		_active_interior = null
	_scene_id = area_id
	if area_id == &"village":
		_village.visible = true
		_family.visible = true
		_world_lighting.visible = true
		_player.teleport_to(position if use_saved_position else INITIAL_PLAYER_POSITION, VillageMapConfig.WORLD_SIZE)
	else:
		var scene := _interior_scene_for(area_id)
		if scene == null:
			push_error("Unknown interior: " + String(area_id))
			_set_area(&"village", INITIAL_PLAYER_POSITION, true)
			return
		_active_interior = scene.instantiate() as BuildingInterior
		_world_simulation.add_child(_active_interior)
		_world_simulation.move_child(_active_interior, 0)
		_active_interior.exit_requested.connect(_begin_exit_interior)
		_village.visible = false
		_family.visible = false
		_world_lighting.visible = false
		_player.teleport_to(position if use_saved_position else _active_interior.entry_position, _active_interior.world_size)
	_collect_npcs()
	_current_target = null
	_current_target_id = &""

func _start_encounter(request: EncounterStartRequest) -> void:
	var result := _session.begin_encounter(request)
	if not result.get("ok", false):
		_hud.set_notice(str(result.get("message", "That encounter is unavailable.")))
		return
	_placeholder_battle_active = false
	_show_battle_ui(result.get("view", {}), false, _portrait_for_initiator(request.initiator_id))

func _start_placeholder_conversation(npc: NpcActor) -> void:
	_placeholder_battle_active = true
	_session.set_simulation_mode(GameSession.SimulationMode.ENCOUNTER)
	_show_battle_ui({
		"title": "A conversation",
		"opponent_name": npc.display_name,
		"player_name": "You",
		"body": npc.dialogue_text
	}, true, npc.portrait_texture)

func _portrait_for_initiator(initiator_id: StringName) -> Texture2D:
	if _current_target is NpcActor:
		var current_npc := _current_target as NpcActor
		if current_npc.story_actor_id == initiator_id and current_npc.portrait_texture != null:
			return current_npc.portrait_texture
	if initiator_id == _family.story_actor_id:
		return _family.portrait_texture
	for npc in _npc_actors:
		if is_instance_valid(npc) and npc.story_actor_id == initiator_id:
			return npc.portrait_texture
	return null

func _show_battle_ui(view: Dictionary, is_placeholder: bool, opponent_portrait: Texture2D) -> void:
	_battle_scene = BATTLE_SCENE.instantiate() as BattleScene
	_battle_scene.choice_selected.connect(_on_battle_choice)
	_battle_scene.close_requested.connect(_on_battle_closed)
	_battle_scene.ui_click_requested.connect(_game_audio.play_ui_click)
	_battle_scene.ui_hover_requested.connect(_game_audio.play_ui_hover)
	add_child(_battle_scene)
	if is_placeholder:
		_battle_scene.show_placeholder_conversation(view, opponent_portrait)
	else:
		_battle_scene.show_encounter(view, opponent_portrait)
	_panel_mode = "encounter"
	_player.set_controls_enabled(false)
	_hud.show_exploration()
	_hud.set_pause_control_visible(false)
	_hud.set_graph_control_visible(false)
	_update_context_action()

func _on_battle_choice(choice_id: StringName) -> void:
	if _placeholder_battle_active:
		_on_battle_closed()
		return
	var result := _session.choose_encounter(choice_id)
	if not result.get("ok", false):
		_hud.set_notice(str(result.get("message", "That reply is unavailable.")))
		return
	_battle_scene.show_result(str(result.get("title", "The moment changes")), str(result.get("message", "")))
	_update_status()

func _on_battle_closed() -> void:
	if _battle_scene != null and is_instance_valid(_battle_scene):
		_battle_scene.queue_free()
	_battle_scene = null
	if _placeholder_battle_active:
		_placeholder_battle_active = false
		_session.set_simulation_mode(GameSession.SimulationMode.EXPLORATION)
	else:
		_session.close_encounter_result()
	_player.set_controls_enabled(true)
	_show_exploration()

func _open_problem_graph() -> void:
	if _session == null or _panel_mode != "exploration":
		return
	_problem_graph_scene = PROBLEM_GRAPH_SCENE.instantiate() as ProblemGraphScene
	_problem_graph_scene.close_requested.connect(_close_problem_graph)
	_problem_graph_scene.debug_completion_requested.connect(_debug_complete_problem_graph_node)
	_problem_graph_scene.ui_click_requested.connect(_game_audio.play_ui_click)
	_problem_graph_scene.ui_hover_requested.connect(_game_audio.play_ui_hover)
	add_child(_problem_graph_scene)
	_problem_graph_scene.present(_session.problem_graph.get_nodes(), _session.problem_graph.get_completed_node_ids())
	_panel_mode = "problem_graph"
	_session.set_simulation_mode(GameSession.SimulationMode.BLOCKING_UI)
	_player.set_controls_enabled(false)
	_hud.set_graph_control_visible(false)
	_hud.set_context_action(Vector2.ZERO, false)

func _close_problem_graph() -> void:
	if _panel_mode != "problem_graph":
		return
	if _problem_graph_scene != null and is_instance_valid(_problem_graph_scene):
		_problem_graph_scene.queue_free()
	_problem_graph_scene = null
	_player.set_controls_enabled(true)
	_show_exploration()

func _debug_complete_problem_graph_node(node_id: StringName) -> void:
	if _session == null or _problem_graph_scene == null:
		return
	if not _session.problem_graph.debug_complete_node(node_id):
		_hud.set_notice("That graph node could not be completed.")
		return
	_problem_graph_scene.refresh_completed_nodes(_session.problem_graph.get_completed_node_ids())

func _show_message(title: String, message: String) -> void:
	_panel_mode = "message"
	_session.set_simulation_mode(GameSession.SimulationMode.BLOCKING_UI)
	_player.set_controls_enabled(false)
	_hud.show_message(title, message)

func _resume_exploration() -> void:
	if _panel_mode != "message":
		return
	_session.set_simulation_mode(GameSession.SimulationMode.EXPLORATION)
	_player.set_controls_enabled(true)
	_show_exploration()

func _restart() -> void:
	_start_new_game()

func _start_new_game() -> void:
	if _battle_scene != null and is_instance_valid(_battle_scene):
		_battle_scene.queue_free()
	_battle_scene = null
	_set_session(GameSession.new())
	_set_area(&"village", INITIAL_PLAYER_POSITION, true)
	_set_world_visible(true)
	_player.set_controls_enabled(true)
	_refresh_current_target()
	_show_exploration()

func _show_welcome() -> void:
	_panel_mode = "welcome"
	if _session != null:
		_session.set_simulation_mode(GameSession.SimulationMode.PAUSED)
	_player.set_controls_enabled(false)
	_set_world_visible(false)
	var has_saves := false
	for slot in _save_slots.list_slots():
		if bool(slot.get("occupied", false)) and bool(slot.get("valid", false)):
			has_saves = true
			break
	_hud.show_welcome(has_saves)

func _show_continue_slots() -> void:
	_panel_mode = "continue_slots"
	_hud.show_slot_selection(_save_slots.list_slots(), false)

func _show_save_slots() -> void:
	if _session == null or not ["pause", "save_slots", "overwrite_confirmation"].has(_panel_mode):
		return
	_panel_mode = "save_slots"
	_hud.show_slot_selection(_save_slots.list_slots(), true)

func _on_slot_selected(slot_id: StringName) -> void:
	if _panel_mode == "continue_slots":
		var result := _save_slots.load_slot(slot_id)
		if not result.get("ok", false):
			_hud.show_slot_selection(_save_slots.list_slots(), false, str(result.get("error", "This save could not be loaded.")))
			return
		var saved_area: StringName = StringName(result.get("scene_id", &"village"))
		if saved_area != &"village" and _interior_scene_for(saved_area) == null:
			_hud.show_slot_selection(_save_slots.list_slots(), false, "This save belongs to an unavailable area.")
			return
		var restored_session := result.get("session") as GameSession
		if restored_session == null:
			_hud.show_slot_selection(_save_slots.list_slots(), false, "This save could not be restored.")
			return
		_set_session(restored_session)
		_set_area(saved_area, result.get("player_position", INITIAL_PLAYER_POSITION), true)
		_set_world_visible(true)
		_player.set_controls_enabled(true)
		_refresh_current_target()
		_show_exploration()
		return
	if _panel_mode != "save_slots":
		return
	_pending_save_slot = slot_id
	var selected_summary: Dictionary = {}
	for slot in _save_slots.list_slots():
		if slot.get("slot_id", &"") == slot_id:
			selected_summary = slot
			break
	if bool(selected_summary.get("occupied", false)):
		_panel_mode = "overwrite_confirmation"
		_hud.show_overwrite_confirmation(str(selected_summary.get("display_name", "this slot")))
		return
	_save_to_pending_slot(false)

func _confirm_save_overwrite() -> void:
	if _panel_mode != "overwrite_confirmation":
		return
	_save_to_pending_slot(true)

func _save_to_pending_slot(confirm_overwrite: bool) -> void:
	var result := _save_slots.save_slot(_pending_save_slot, _session, {
		"scene_id": String(_scene_id),
		"player_position": _player.global_position
	}, confirm_overwrite)
	if not result.get("ok", false):
		var error_text := str(result.get("error", "The game could not be saved."))
		_panel_mode = "pause"
		_hud.show_pause(error_text)
		return
	var slot_name := str(result.get("metadata", {}).get("display_name", "Save Slot"))
	_pending_save_slot = &""
	_panel_mode = "pause"
	_hud.show_pause("Saved to %s." % slot_name)

func _on_menu_back() -> void:
	match _panel_mode:
		"continue_slots":
			_show_welcome()
		"save_slots":
			_open_pause_menu()
		"overwrite_confirmation":
			_show_save_slots()

func _open_pause_menu() -> void:
	if _session == null or not ["exploration", "save_slots"].has(_panel_mode):
		return
	_panel_mode = "pause"
	_session.set_simulation_mode(GameSession.SimulationMode.PAUSED)
	_player.set_controls_enabled(false)
	_hud.show_pause()

func _resume_from_pause() -> void:
	if _panel_mode != "pause":
		return
	_player.set_controls_enabled(true)
	_show_exploration()

func _set_world_visible(visible: bool) -> void:
	_world_simulation.visible = visible

func _set_session(session: GameSession) -> void:
	if _session != null and _session.simulation_mode_changed.is_connected(_on_simulation_mode_changed):
		_session.simulation_mode_changed.disconnect(_on_simulation_mode_changed)
	_session = session
	_hud.set_debug_time_speed(1)
	if _session == null:
		_on_simulation_mode_changed(GameSession.SimulationMode.PAUSED)
		return
	_session.simulation_mode_changed.connect(_on_simulation_mode_changed)
	_on_simulation_mode_changed(_session.simulation_mode)
	_update_world_lighting()

func _on_time_speed_requested(multiplier: int) -> void:
	if _session == null:
		return
	_session.clock.set_time_scale(multiplier)
	_hud.set_debug_time_speed(multiplier)

func _update_world_lighting() -> void:
	if _session == null:
		return
	_world_lighting.apply_time_of_day(
		float(_session.state.minute_of_day) + _session.clock.get_fractional_game_minutes()
	)

func _on_simulation_mode_changed(mode: int) -> void:
	get_tree().paused = mode != GameSession.SimulationMode.EXPLORATION

func _show_exploration() -> void:
	_panel_mode = "exploration"
	_session.set_simulation_mode(GameSession.SimulationMode.EXPLORATION)
	_refresh_current_target()
	_hud.show_exploration()
	_hud.set_graph_control_visible(true)
	_update_status()
	_update_context_action()

func _update_status(_update: SessionUpdate = null) -> void:
	_hud.update_clock(_session.state.day_number, _session.state.minute_of_day, _session.clock.get_phase())
	_hud.update_status(_session.state)
