class_name EncounterDefinition
extends Resource

@export var encounter_id: StringName = &""
@export var title: String = ""
@export_multiline var prompt: String = ""
@export var player_name: String = "You"
@export var opponent_name: String = ""
@export var choices: Array[Resource] = []
