class_name RelationshipRules
extends RefCounted

static func adjust_family_trust(state: GameState, delta: int) -> int:
	state.family_trust = clampi(state.family_trust + delta, -3, 3)
	return state.family_trust
