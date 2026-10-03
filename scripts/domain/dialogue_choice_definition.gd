class_name DialogueChoiceDefinition
extends Resource

@export var choice_id: StringName = &""
@export var label: String = ""
@export_multiline var description: String = ""
@export_multiline var result_message: String = ""
@export_multiline var consequence_text: String = ""
@export var family_trust_delta: int = 0
@export var anxiety_delta: float = 0.0
@export var preserves_opportunity: bool = true
@export var required_effect_id: StringName = &""
@export var consumes_required_effect: bool = false
@export var continues_conversation: bool = false

