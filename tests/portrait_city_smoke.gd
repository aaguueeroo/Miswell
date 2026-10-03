extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var failures: Array[String] = []
	var packed := load("res://scenes/main.tscn") as PackedScene
	var scene: Node = packed.instantiate()
	root.add_child(scene)
	await process_frame
	await physics_frame

	var player := scene.get_node("Player") as PlayerActor
	var camera := scene.get_node_or_null("Player/Camera2D") as Camera2D
	_check(camera != null and camera.enabled, "player camera is active", failures)
	_check(VillageMapConfig.WORLD_SIZE.x > 540.0 and VillageMapConfig.WORLD_SIZE.y > 960.0, "town exceeds the portrait viewport", failures)
	player.global_position = Vector2(1000.0, 1500.0)
	await physics_frame
	_check(player.global_position.x > 900.0 and player.global_position.y > 1300.0, "movement is clamped to the map, not the screen", failures)

	var hud: GameHUD
	for child in scene.get_children():
		if child is GameHUD:
			hud = child as GameHUD
	_check(hud != null, "game HUD exists", failures)
	if hud != null:
		var bottom_panel := hud.get("_bottom_panel") as Control
		_check(not bottom_panel.visible, "exploration has no persistent bottom panel", failures)
		var school := scene.get_node("Village/School") as LocationActor
		player.global_position = school.get_interaction_anchor() + Vector2(0.0, 100.0)
		await process_frame
		await process_frame
		var context_prompt := hud.get("_context_action") as Control
		_check(context_prompt.visible == (not GameHUD.is_mobile_platform()), "desktop E prompt appears only in range", failures)
		var school_door_screen := scene.get_viewport().get_canvas_transform() * school.get_interaction_anchor()
		scene.call("_try_mobile_tap", school_door_screen + Vector2(0.0, 63.0))
		_check(hud.get_panel_mode() == "exploration", "taps outside the door hotspot do nothing", failures)
		scene.call("_try_mobile_tap", school_door_screen)
		_check(hud.get_panel_mode() == "slot_picker", "tapping a reachable door opens its action", failures)
		scene.call("_cancel_slot_picker")
		player.global_position = Vector2(60.0, 60.0)
		await process_frame
		await process_frame
		_check(not context_prompt.visible, "context prompt hides out of range", failures)

	var session := GameSession.new()
	var initial_view := session.dialogue.begin_or_follow_up(0)
	_check(initial_view.get("kind", "") == "choices", "family encounter opens after scheduling", failures)
	var first_thought := session.dialogue.choose(&"overthink")
	_check(first_thought.get("kind", "") == "continue" and session.dialogue.is_encounter_active(), "overthinking stays inside the conversation", failures)
	var second_thought := session.dialogue.choose(&"overthink")
	_check(second_thought.get("effect_activated", false), "repeated overthinking activates anxious focus", failures)
	var choices: Array = second_thought.get("view", {}).get("choices", [])
	var threat_reply_available := false
	for choice_resource in choices:
		var choice := choice_resource as DialogueChoiceDefinition
		if choice != null and choice.choice_id == &"threat_focus":
			threat_reply_available = true
	_check(threat_reply_available, "anxious focus reveals the conditional reply", failures)
	var final_reply := session.dialogue.choose(&"support")
	_check(final_reply.get("ok", false) and not session.dialogue.is_encounter_active(), "conversation choice completes the encounter", failures)

	if failures.is_empty():
		print("PASS: portrait city camera, contextual actions, hidden footer, and conversation flow")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check(condition: bool, label: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(label)
