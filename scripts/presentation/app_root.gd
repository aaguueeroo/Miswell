extends Node2D

const CURSOR_ARROW: Texture2D = preload("res://assets/gui/kenney_cursor-pixel-pack/arrow_cursor.png")
const CURSOR_HAND: Texture2D = preload("res://assets/gui/kenney_cursor-pixel-pack/hand_cursor.png")
const BATTLE_SCENE: PackedScene = preload("res://scenes/battle/battle_scene.tscn")
const INITIAL_PLAYER_POSITION := Vector2(520.0, 940.0)

@onready var _player: PlayerActor = $Player
@onready var _family: FamilyNpc = $Family
@onready var _village: Node2D = $Village
@onready var _village_map: VillageMapRoot = $Village/CityMap

var _session: GameSession
var _save_slots: SaveSlotService
var _hud: GameHUD
var _game_audio: GameAudio
var _panel_mode: String = "exploration"
var _location_actors: Array[LocationActor] = []
var _current_target: Node2D
var _current_target_id: StringName = &""
var _battle_scene: BattleScene
var _pending_save_slot: StringName = &""

func _ready() -> void:
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
	_hud = GameHUD.new()
	add_child(_hud)
	_hud.message_action_requested.connect(_resume_exploration)
	_hud.restart_requested.connect(_restart)
	_hud.new_game_requested.connect(_start_new_game)
	_hud.continue_requested.connect(_show_continue_slots)
	_hud.slot_selected.connect(_on_slot_selected)
	_hud.overwrite_confirmed.connect(_confirm_save_overwrite)
	_hud.back_requested.connect(_on_menu_back)
	_hud.pause_requested.connect(_open_pause_menu)
	_hud.resume_requested.connect(_resume_from_pause)
	_hud.save_requested.connect(_show_save_slots)
	_hud.ui_click_requested.connect(_game_audio.play_ui_click)
	_hud.ui_hover_requested.connect(_game_audio.play_ui_hover)
	_hud.touch_direction_changed.connect(_player.set_touch_direction)
	_player.interact_requested.connect(_attempt_interact)
	_player.footstep_requested.connect(_play_player_footstep)
	_player.set_controls_enabled(false)
	_player.visible = false
	_family.visible = false
	_village.visible = false
	_show_welcome()

func _process(delta: float) -> void:
	if _session == null:
		return
	var update := _session.tick(delta)
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
		if not is_instance_valid(location) or location.definition == null:
			continue
		var distance := _player.global_position.distance_to(location.get_interaction_anchor())
		if distance <= nearest_distance:
			nearest = location
			nearest_distance = distance
	var family_distance := _player.global_position.distance_to(_family.get_interaction_anchor())
	if family_distance <= VillageMapConfig.INTERACTION_RADIUS and family_distance <= nearest_distance:
		nearest = _family
	_current_target = nearest
	if _current_target == _family:
		_current_target_id = &"family"
	elif _current_target is LocationActor:
		var location := _current_target as LocationActor
		_current_target_id = location.definition.location_id if location.definition != null else &""
	else:
		_current_target_id = &""

func _can_interact_with_current_target() -> bool:
	if _current_target == null:
		return false
	if _current_target_id == &"home":
		return true
	if _current_target_id == &"family":
		if _session.state.day_number == 1:
			return _session.story.is_event_available(&"family_good_news", &"player_interaction")
		return _session.story.is_event_available(&"family_follow_up", &"family_interaction")
	return not _session.state.has_action_been_used(_current_target_id)

func _get_current_interaction_anchor() -> Vector2:
	if _current_target == _family:
		return _family.get_interaction_anchor()
	if _current_target is LocationActor:
		return (_current_target as LocationActor).get_interaction_anchor()
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
	_game_audio.play_footstep(_village_map.get_footstep_surface(feet_position))

func _attempt_interact() -> void:
	if _panel_mode != "exploration":
		return
	_refresh_current_target()
	if _current_target == null:
		return
	_game_audio.play_ui_click()
	if _current_target_id == &"home":
		_show_message("Home", "A familiar place to pause. The day continues when you return to exploring.")
		return
	if _current_target_id == &"family":
		if _session.state.day_number == 1:
			_start_encounter(EncounterStartRequest.new(&"family_good_news", &"family_good_news", &"family", &"player_interaction"))
			return
		var follow_up := _session.resolve_family_follow_up()
		if follow_up.get("ok", false):
			_show_message(str(follow_up.get("title", "A quiet moment")), str(follow_up.get("message", "")))
		else:
			_show_message(str(follow_up.get("title", "A quiet moment")), str(follow_up.get("message", "You have already checked in with your family today.")))
		return
	var result := _session.exploration.visit_location(_current_target_id)
	_update_status()
	_show_message(str(result.get("title", "Place unavailable")), str(result.get("message", "This place does not have activity data.")))

func _start_encounter(request: EncounterStartRequest) -> void:
	var result := _session.begin_encounter(request)
	if not result.get("ok", false):
		_hud.set_notice(str(result.get("message", "That encounter is unavailable.")))
		return
	_battle_scene = BATTLE_SCENE.instantiate() as BattleScene
	_battle_scene.choice_selected.connect(_on_battle_choice)
	_battle_scene.close_requested.connect(_on_battle_closed)
	_battle_scene.ui_click_requested.connect(_game_audio.play_ui_click)
	_battle_scene.ui_hover_requested.connect(_game_audio.play_ui_hover)
	add_child(_battle_scene)
	_battle_scene.show_encounter(result.get("view", {}))
	_panel_mode = "encounter"
	_player.set_controls_enabled(false)
	_hud.show_exploration()
	_hud.set_pause_control_visible(false)
	_update_context_action()

func _on_battle_choice(choice_id: StringName) -> void:
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
	_session.close_encounter_result()
	_player.set_controls_enabled(true)
	_show_exploration()

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
	_session = GameSession.new()
	_player.global_position = INITIAL_PLAYER_POSITION
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
		if StringName(result.get("scene_id", &"village")) != &"village":
			_hud.show_slot_selection(_save_slots.list_slots(), false, "This save belongs to an unavailable area.")
			return
		var restored_session := result.get("session") as GameSession
		if restored_session == null:
			_hud.show_slot_selection(_save_slots.list_slots(), false, "This save could not be restored.")
			return
		_session = restored_session
		_player.global_position = result.get("player_position", INITIAL_PLAYER_POSITION)
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
		"scene_id": "village",
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
	_village.visible = visible
	_family.visible = visible
	_player.visible = visible

func _show_exploration() -> void:
	_panel_mode = "exploration"
	_session.set_simulation_mode(GameSession.SimulationMode.EXPLORATION)
	_refresh_current_target()
	_hud.show_exploration()
	_update_status()
	_update_context_action()

func _update_status(_update: SessionUpdate = null) -> void:
	_hud.update_clock(_session.state.day_number, _session.state.minute_of_day, _session.clock.get_phase())
	_hud.update_status(_session.state)
