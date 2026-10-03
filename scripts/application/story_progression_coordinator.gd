class_name StoryProgressionCoordinator
extends RefCounted

var _state: GameSessionState
var _content: ContentCatalog
var _problem_graph: ProblemGraphCoordinator

func _init(state: GameSessionState, content: ContentCatalog, problem_graph: ProblemGraphCoordinator) -> void:
	_state = state
	_content = content
	_problem_graph = problem_graph

func is_event_available(event_id: StringName, source: StringName) -> bool:
	var event := _content.get_event(event_id)
	if event == null or event.trigger_source != source or not _source_matches_policy(event, source) or not _is_in_window(event):
		return false
	if not event.repeatable and _state.has_completed_event(event_id):
		return false
	if event.repeatable and _state.has_completed_event_today(event_id):
		return false
	if event.daily_action_id != &"" and _state.has_action_been_used(event.daily_action_id):
		return false
	for condition_resource in event.conditions:
		var condition := condition_resource as StoryConditionDefinition
		if condition == null or not _condition_is_met(condition):
			return false
	return true

func apply_outcome(event_id: StringName, outcome_id: StringName) -> bool:
	var event := _content.get_event(event_id)
	if event == null or not is_event_available(event_id, event.trigger_source):
		return false
	var outcome := _find_outcome(event, outcome_id)
	if outcome == null or not _all_conditions_met(outcome.conditions):
		return false
	for effect_resource in outcome.effects:
		var effect := effect_resource as StoryEffectDefinition
		if effect == null or not _effect_is_valid(effect):
			return false
	for effect_resource in outcome.effects:
		_apply_effect(effect_resource as StoryEffectDefinition)
	_state.outcome_journal.append(StoryOutcomeRecord.new(event_id, outcome_id, _state.day_number, _state.minute_of_day))
	if event.daily_action_id != &"":
		_state.record_daily_action(event.daily_action_id)
	_state.pending_event_ids.erase(event_id)
	return true

func resolve_automatic_event(event_id: StringName, source: StringName) -> Dictionary:
	if not is_event_available(event_id, source):
		return {"ok": false, "message": "That event is not available."}
	var event := _content.get_event(event_id)
	for outcome_resource in event.outcomes:
		var outcome := outcome_resource as StoryOutcomeDefinition
		if outcome != null and _all_conditions_met(outcome.conditions) and apply_outcome(event_id, outcome.outcome_id):
			return {
				"ok": true,
				"kind": "complete",
				"title": outcome.title,
				"message": outcome.result_message,
				"outcome_id": outcome.outcome_id
			}
	return {"ok": false, "message": "No available result is defined for that event."}

func evaluate_time_events() -> Array[EncounterStartRequest]:
	var requests: Array[EncounterStartRequest] = []
	for event in _content.get_time_triggered_events():
		if event == null or _state.pending_event_ids.has(event.event_id):
			continue
		if not is_event_available(event.event_id, event.trigger_source):
			continue
		if _absolute_minute() < _event_minute(event.opens_on_day, event.trigger_at_minute):
			continue
		_state.pending_event_ids.append(event.event_id)
		requests.append(EncounterStartRequest.new(event.event_id, event.encounter_id, event.initiator_id, event.trigger_source))
	return requests

func _find_outcome(event: StoryEventDefinition, outcome_id: StringName) -> StoryOutcomeDefinition:
	for resource in event.outcomes:
		var outcome := resource as StoryOutcomeDefinition
		if outcome != null and outcome.outcome_id == outcome_id:
			return outcome
	return null

func _is_in_window(event: StoryEventDefinition) -> bool:
	var now := _absolute_minute()
	var opens := _event_minute(event.opens_on_day, event.opens_at_minute)
	if now < opens:
		return false
	if event.closes_on_day >= 1 and now >= _event_minute(event.closes_on_day, event.closes_at_minute):
		return false
	return true

func _source_matches_policy(event: StoryEventDefinition, source: StringName) -> bool:
	match event.start_policy:
		StoryEventDefinition.StartPolicy.PLAYER_INTERACTION:
			return source == &"player_interaction"
		StoryEventDefinition.StartPolicy.NPC_INTERACTION:
			return source == &"npc_interaction"
		StoryEventDefinition.StartPolicy.TIME_TRIGGERED:
			return source == &"time_trigger"
		StoryEventDefinition.StartPolicy.STORY_TRIGGERED:
			return source == &"story_trigger"
	return false

func _event_minute(day: int, minute: int) -> int:
	return maxi(1, day) * 1440 + clampi(minute, 0, 1439)

func _absolute_minute() -> int:
	return _state.day_number * 1440 + _state.minute_of_day

func _all_conditions_met(conditions: Array[Resource]) -> bool:
	for resource in conditions:
		var condition := resource as StoryConditionDefinition
		if condition == null or not _condition_is_met(condition):
			return false
	return true

func _condition_is_met(condition: StoryConditionDefinition) -> bool:
	match condition.kind:
		StoryConditionDefinition.ConditionKind.FACT_EXISTS:
			return _state.story_facts.has(condition.fact_id)
		StoryConditionDefinition.ConditionKind.FACT_EQUALS_BOOL:
			return _state.story_facts.has(condition.fact_id) and bool(_state.story_facts[condition.fact_id]) == condition.expected_bool
		StoryConditionDefinition.ConditionKind.OUTCOME_COMPLETED:
			return _state.has_completed_outcome(condition.event_id, condition.outcome_id)
		StoryConditionDefinition.ConditionKind.DAY_RANGE:
			return _state.day_number >= condition.minimum_day and _state.day_number <= condition.maximum_day
		StoryConditionDefinition.ConditionKind.TIME_RANGE:
			if condition.start_minute <= condition.end_minute:
				return _state.minute_of_day >= condition.start_minute and _state.minute_of_day < condition.end_minute
			return _state.minute_of_day >= condition.start_minute or _state.minute_of_day < condition.end_minute
		StoryConditionDefinition.ConditionKind.LIFE_STAGE_EQUALS:
			return _state.life_stage_id == condition.life_stage_id
		StoryConditionDefinition.ConditionKind.ALL_OF:
			return _all_conditions_met(condition.conditions)
		StoryConditionDefinition.ConditionKind.ANY_OF:
			for resource in condition.conditions:
				var nested := resource as StoryConditionDefinition
				if nested != null and _condition_is_met(nested):
					return true
			return false
	return false

func _effect_is_valid(effect: StoryEffectDefinition) -> bool:
	match effect.kind:
		StoryEffectDefinition.EffectKind.ADJUST_RELATIONSHIP:
			return effect.target_id != &""
		StoryEffectDefinition.EffectKind.SET_BOOLEAN_FACT:
			return effect.fact_id != &""
		StoryEffectDefinition.EffectKind.UNLOCK_PROBLEM_GRAPH_NODE:
			return _problem_graph.can_unlock_node(effect.graph_node_id)
		_:
			return true

func _apply_effect(effect: StoryEffectDefinition) -> void:
	match effect.kind:
		StoryEffectDefinition.EffectKind.ADJUST_RELATIONSHIP:
			RelationshipRules.adjust(_state, effect.target_id, roundi(effect.amount))
		StoryEffectDefinition.EffectKind.ADJUST_ANXIETY:
			AnxietyRules.apply_delta(_state, effect.amount)
		StoryEffectDefinition.EffectKind.SET_BOOLEAN_FACT:
			_state.story_facts[effect.fact_id] = effect.boolean_value
		StoryEffectDefinition.EffectKind.CONSUME_ANXIETY_EFFECT:
			AnxietyRules.consume_effect(_state)
		StoryEffectDefinition.EffectKind.UNLOCK_PROBLEM_GRAPH_NODE:
			_problem_graph.unlock_node_from_story(effect.graph_node_id)
