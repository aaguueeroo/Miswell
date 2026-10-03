extends Node2D

@onready var _player: PlayerActor = $Player
@onready var _family: FamilyNpc = $Family

var _session: GameSession
var _hud: GameHUD
var _panel_mode: String = "exploration"
var _location_actors: Array[LocationActor] = []
var _current_target: Node2D
var _current_target_id: StringName = &""
var _pending_target_id: StringName = &""
var _pending_is_family: bool = false

func _ready() -> void:
	_session = GameSession.new()
	for candidate in get_tree().get_nodes_in_group("locations"):
		var location := candidate as LocationActor
		if location != null:
			_location_actors.append(location)
	_hud = GameHUD.new()
	add_child(_hud)
	_hud.choice_selected.connect(_choose_dialogue)
	_hud.message_action_requested.connect(_resume_exploration)
	_hud.restart_requested.connect(_restart)
	_hud.slot_selected.connect(_select_slot)
	_hud.slot_picker_cancelled.connect(_cancel_slot_picker)
	_hud.touch_direction_changed.connect(_player.set_touch_direction)
	_player.interact_requested.connect(_attempt_interact)
	_refresh_current_target()
	_show_exploration()

func _process(delta: float) -> void:
	if _session == null:
		return
	if _panel_mode == "exploration" and not _session.dialogue.is_encounter_active():
		if _session.anxiety.tick(delta):
			_hud.set_notice("Anxious focus passed. The moment settles.")
		_refresh_current_target()
		_update_context_action()
		_update_status()

func _unhandled_input(event: InputEvent) -> void:
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
			return not _session.state.family_outcome_chosen
		return not _session.state.visited_activity_ids.has(&"family_follow_up")
	return not _session.state.visited_activity_ids.has(_current_target_id)

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
		_hud.set_context_action("", Vector2.ZERO, false)
		return
	var caption := "E  ·  TALK"
	if _current_target_id == &"home":
		caption = "E  ·  GO HOME"
	elif _current_target is LocationActor:
		var location := _current_target as LocationActor
		if location.definition != null:
			match location.definition.location_id:
				&"school":
					caption = "E  ·  SCHOOL"
				&"supermarket":
					caption = "E  ·  SHOP"
				&"gym":
					caption = "E  ·  GYM"
	var anchor_screen := _world_to_screen(_get_current_interaction_anchor())
	_hud.set_context_action(caption, anchor_screen, true)

func _attempt_interact() -> void:
	if _panel_mode != "exploration":
		return
	_refresh_current_target()
	if _current_target == null:
		return
	if _current_target_id == &"home":
		_end_day()
		return
	_pending_target_id = _current_target_id
	_pending_is_family = _current_target_id == &"family"
	var slots: Array[Dictionary]
	var title := ""
	var prompt := ""
	if _pending_is_family:
		if _session.state.day_number == 1 and _session.state.family_outcome_chosen:
			_show_message("The moment is settled", "The family conversation is already part of today's plan. Tomorrow will remember how it went.")
			return
		if _session.state.day_number > 1 and _session.state.visited_activity_ids.has(&"family_follow_up"):
			_show_message("A quiet moment", "You have already checked in with your family today.")
			return
		slots = _session.dialogue.available_slots()
		title = "Plan the family conversation"
		prompt = "Choose when this conversation fits into your day."
	else:
		var definition := _session.exploration.get_location(_pending_target_id)
		if definition == null:
			_show_message("Place unavailable", "This place does not have activity data.")
			return
		if _session.state.visited_activity_ids.has(_pending_target_id):
			_show_message(definition.display_name + " is already planned", "You have already added this place to today's schedule.")
			return
		slots = _session.exploration.get_available_slots(_pending_target_id)
		title = "Plan " + definition.display_name
		prompt = definition.interaction_prompt + " Choose an open time."
	if slots.is_empty():
		_hud.set_notice("No open time slots remain for this place.")
		return
	_panel_mode = "slot_picker"
	_player.set_controls_enabled(false)
	_hud.show_slot_picker(title, prompt, slots)

func _select_slot(slot_index: int) -> void:
	if _panel_mode != "slot_picker":
		return
	if _pending_is_family:
		var view := _session.dialogue.begin_or_follow_up(slot_index)
		_update_status()
		if view.get("kind", "") == "choices":
			_panel_mode = "dialogue"
			_hud.show_dialogue(view)
			return
		_show_message(str(view.get("title", "Conversation")), str(view.get("body", "")))
		return
	var result := _session.exploration.visit_location(_pending_target_id, slot_index)
	_update_status()
	if result.get("kind", "") == "home":
		_end_day()
		return
	_show_message(str(result.get("title", "The plan changes")), str(result.get("message", "")))

func _cancel_slot_picker() -> void:
	if _panel_mode != "slot_picker":
		return
	_pending_target_id = &""
	_pending_is_family = false
	_player.set_controls_enabled(true)
	_show_exploration()

func _choose_dialogue(choice_id: StringName) -> void:
	var result := _session.dialogue.choose(choice_id)
	if not result.get("ok", false):
		_hud.set_notice(str(result.get("message", "That reply is unavailable.")))
		return
	_update_status()
	if result.get("kind", "") == "continue":
		if result.get("effect_activated", false):
			_hud.set_notice("Anxious focus has taken hold. A new reply is available.")
		_hud.show_dialogue(result.get("view", {}))
		return
	_show_message(str(result.get("title", "The moment changes")), str(result.get("message", "")))

func _end_day() -> void:
	if _panel_mode != "exploration":
		return
	var result := _session.day_flow.finish_day()
	_update_status()
	if result.get("complete", false):
		_panel_mode = "finished"
		_player.set_controls_enabled(false)
		_hud.show_finished(str(result.get("title", "Complete")), str(result.get("message", "")))
		return
	_show_message(str(result.get("title", "The next morning")), str(result.get("message", "")))

func _show_message(title: String, message: String) -> void:
	_panel_mode = "message"
	_player.set_controls_enabled(false)
	_hud.show_message(title, message)

func _resume_exploration() -> void:
	if _panel_mode != "message":
		return
	_pending_target_id = &""
	_pending_is_family = false
	_player.set_controls_enabled(true)
	_show_exploration()

func _restart() -> void:
	_session = GameSession.new()
	_player.global_position = Vector2(520.0, 940.0)
	_player.set_controls_enabled(true)
	_pending_target_id = &""
	_pending_is_family = false
	_refresh_current_target()
	_show_exploration()

func _show_exploration() -> void:
	_panel_mode = "exploration"
	_refresh_current_target()
	_hud.show_exploration()
	_update_status()
	_update_context_action()

func _update_status() -> void:
	_hud.update_status(_session.state, _session.day_flow.status_text(), _session.day_flow.timeline_view())

