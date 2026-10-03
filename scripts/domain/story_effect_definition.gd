class_name StoryEffectDefinition
extends Resource

enum EffectKind { ADJUST_RELATIONSHIP, ADJUST_ANXIETY, SET_BOOLEAN_FACT, CONSUME_ANXIETY_EFFECT }

@export var kind: EffectKind = EffectKind.SET_BOOLEAN_FACT
@export var target_id: StringName = &""
@export var amount: float = 0.0
@export var fact_id: StringName = &""
@export var boolean_value: bool = false
