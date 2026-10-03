class_name DialogueEncounterCoordinator
extends RefCounted

var _state: GameState
var _content: ContentCatalog
var _day_flow: DayLoopCoordinator
var _active_definition: DialogueDefinition
var _encounter_active: bool = false
var _overthinking_count: int = 0
var _overthinking_text: String = ""

func _init(state: GameState, content: ContentCatalog, day_flow: DayLoopCoordinator) -> void:
	_state = state
	_content = content
	_day_flow = day_flow

func available_slots() -> Array[Dictionary]:
	var all_slots: Array[StringName] = []
	return _day_flow.available_slots(all_slots)

func begin_or_follow_up(slot_index: int) -> Dictionary:
	if _state.day_number == 1 and not _state.family_encounter_seen:
		if _content.get_family_encounter() == null:
			return {
				"kind": "message",
				"title": "The conversation is missing",
				"body": "The family encounter data could not be loaded. Check data/dialogue/family_encounter.tres."
			}
		var schedule := _day_flow.assign_activity(&"family_conversation", "Family conversation", slot_index)
		if not schedule.get("ok", false):
			return {"kind": "message", "title": "Choose another slot", "body": str(schedule.get("message", ""))}
		_active_definition = _content.get_family_encounter()
		_state.family_encounter_seen = true
		_encounter_active = true
		_overthinking_count = 0
		_overthinking_text = ""
		return _build_encounter_view()
	if _state.day_number == 1:
		return {
			"kind": "message",
			"title": "The moment is settled",
			"body": "The family conversation is already in today's plan. Tomorrow will remember how it went."
		}
	if _state.visited_activity_ids.has(&"family_follow_up"):
		return {
			"kind": "message",
			"title": "A quiet moment",
			"body": "You have already checked in with your family today."
		}
	var follow_up_schedule := _day_flow.assign_activity(&"family_follow_up", "Family conversation", slot_index)
	if not follow_up_schedule.get("ok", false):
		return {
			"kind": "message",
			"title": "Choose another slot",
			"body": str(follow_up_schedule.get("message", "That time is unavailable."))
		}
	var message := ""
	var title := ""
	if _state.family_outcome_chosen and _state.family_opportunity_preserved:
		title = "They remember you listened"
		message = "The conversation starts easily. Your family picks up the good news where yesterday left off."
	elif _state.family_outcome_chosen:
		title = "Yesterday is still here"
		message = "There is a pause before anyone speaks. The family remembers how the good moment turned into a complaint."
	else:
		title = "The chance passed"
		message = "Your family is here, but yesterday's opportunity was not in the schedule."
	return {
		"kind": "message",
		"title": title + " · " + str(follow_up_schedule.get("slot_label", "")),
		"body": message + "\n\n" + str(follow_up_schedule.get("message", ""))
	}

func choose(choice_id: StringName) -> Dictionary:
	if not _encounter_active or _active_definition == null:
		return {"ok": false, "message": "There is no active conversation."}
	for resource in _active_definition.choices:
		var choice := resource as DialogueChoiceDefinition
		if choice == null or choice.choice_id != choice_id:
			continue
		if choice.required_effect_id != &"" and choice.required_effect_id != _state.anxiety_effect_id:
			continue
		var anxiety_result := AnxietyRules.apply_delta(_state, choice.anxiety_delta)
		if choice.continues_conversation:
			_overthinking_count += 1
			_overthinking_text = choice.result_message
			return {
				"ok": true,
				"kind": "continue",
				"title": choice.label,
				"message": choice.result_message,
				"effect_activated": anxiety_result.get("effect_activated", false),
				"view": _build_encounter_view()
			}
		RelationshipRules.adjust_family_trust(_state, choice.family_trust_delta)
		if choice.consumes_required_effect:
			AnxietyRules.consume_effect(_state)
		_state.family_outcome_chosen = true
		_state.family_opportunity_preserved = choice.preserves_opportunity
		_state.last_consequence_text = choice.consequence_text
		_encounter_active = false
		var scheduled_period := _day_flow.slot_for_activity(&"family_conversation")
		return {
			"ok": true,
			"kind": "complete",
			"title": choice.label,
			"message": choice.result_message + "\n\nFamily conversation is set for " + scheduled_period + ".",
			"effect_activated": anxiety_result.get("effect_activated", false)
		}
	return {"ok": false, "message": "That reply is no longer available."}

func is_encounter_active() -> bool:
	return _encounter_active

func _build_encounter_view() -> Dictionary:
	var available_choices: Array[Resource] = []
	for resource in _active_definition.choices:
		var choice := resource as DialogueChoiceDefinition
		if choice == null:
			continue
		if choice.required_effect_id != &"" and choice.required_effect_id != _state.anxiety_effect_id:
			continue
		if choice.continues_conversation and (_overthinking_count >= 2 or _state.anxiety_effect_id != &""):
			continue
		available_choices.append(choice)
	var prompt := _active_definition.prompt
	if not _overthinking_text.is_empty():
		prompt = _overthinking_text + "\n\nWhat do you say?"
	return {
		"kind": "choices",
		"title": _active_definition.title,
		"body": prompt,
		"choices": available_choices
	}

