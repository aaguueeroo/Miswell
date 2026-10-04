class_name StoryEffectDefinition
extends Resource

enum EffectKind { ADJUST_RELATIONSHIP, ADJUST_ANXIETY, SET_BOOLEAN_FACT, CONSUME_ANXIETY_EFFECT, UNLOCK_PROBLEM_GRAPH_NODE }

@export var kind: EffectKind = EffectKind.SET_BOOLEAN_FACT
@export var target_id: StringName = &""
@export var amount: float = 0.0
@export var fact_id: StringName = &""
@export var boolean_value: bool = false
@export var graph_node_id: StringName = &""

static func from_document(data: Dictionary) -> StoryEffectDefinition:
	var result := StoryEffectDefinition.new()
	match str(data.get("kind", "")):
		"adjust_relationship":
			result.kind = EffectKind.ADJUST_RELATIONSHIP
			result.target_id = StringName(str(data.get("target_id", "")))
			result.amount = float(data.get("amount", 0.0))
			if result.target_id == &"" or not is_finite(result.amount):
				return null
		"adjust_anxiety":
			result.kind = EffectKind.ADJUST_ANXIETY
			result.amount = float(data.get("amount", 0.0))
			if not is_finite(result.amount):
				return null
		"set_boolean_fact":
			result.kind = EffectKind.SET_BOOLEAN_FACT
			result.fact_id = StringName(str(data.get("fact_id", "")))
			result.boolean_value = bool(data.get("boolean_value", false))
			if result.fact_id == &"":
				return null
		"consume_anxiety_effect":
			result.kind = EffectKind.CONSUME_ANXIETY_EFFECT
		"unlock_problem_graph_node":
			result.kind = EffectKind.UNLOCK_PROBLEM_GRAPH_NODE
			result.graph_node_id = StringName(str(data.get("graph_node_id", "")))
			if result.graph_node_id == &"":
				return null
		_:
			return null
	return result
