class_name RelationshipRules
extends RefCounted

static func adjust(state: GameSessionState, relationship_id: StringName, delta: int) -> int:
	var current := int(state.relationship_values.get(relationship_id, 0))
	var updated := clampi(current + delta, -3, 3)
	state.relationship_values[relationship_id] = updated
	return updated

static func value_for(state: GameSessionState, relationship_id: StringName) -> int:
	return int(state.relationship_values.get(relationship_id, 0))
