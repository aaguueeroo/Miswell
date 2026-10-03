class_name AnxietyRules
extends RefCounted

const THRESHOLD: float = 65.0
const EFFECT_DURATION_SECONDS: float = 25.0

static func apply_delta(state: GameSessionState, delta: float) -> Dictionary:
	state.anxiety = clampf(state.anxiety + delta, 0.0, 100.0)
	var effect_activated := false
	if state.anxiety >= THRESHOLD and state.anxiety_effect_id == &"":
		state.anxiety_effect_id = &"threat_focus"
		state.anxiety_effect_seconds = EFFECT_DURATION_SECONDS
		state.anxiety = 42.0
		effect_activated = true
	return {
		"effect_activated": effect_activated,
		"anxiety": state.anxiety
	}

static func tick(state: GameSessionState, delta: float) -> bool:
	if state.anxiety_effect_id == &"":
		return false
	state.anxiety_effect_seconds = maxf(0.0, state.anxiety_effect_seconds - delta)
	if state.anxiety_effect_seconds <= 0.0:
		state.anxiety_effect_id = &""
		state.anxiety = maxf(0.0, state.anxiety - 12.0)
		return true
	return false

static func consume_effect(state: GameSessionState) -> bool:
	if state.anxiety_effect_id == &"":
		return false
	state.anxiety_effect_id = &""
	state.anxiety_effect_seconds = 0.0
	state.anxiety = maxf(0.0, state.anxiety - 15.0)
	return true
