class_name DialogueDefinition
extends Resource

@export var dialogue_id: StringName = &""
@export var title: String = ""
@export_multiline var prompt: String = ""
@export var choices: Array[Resource] = []
