class_name LocationDefinition
extends Resource

@export var location_id: StringName = &""
@export var display_name: String = ""
@export var building_style: StringName = &""
@export_multiline var interaction_prompt: String = ""
@export_multiline var visit_message: String = ""
@export var anxiety_delta: float = 0.0
@export var family_trust_delta: int = 0
@export var interaction_offset: Vector2 = Vector2(0.0, -38.0)
