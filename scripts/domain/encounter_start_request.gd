class_name EncounterStartRequest
extends RefCounted

var event_id: StringName
var encounter_id: StringName
var initiator_id: StringName
var trigger_source: StringName

func _init(p_event: StringName = &"", p_encounter: StringName = &"", p_initiator: StringName = &"", p_source: StringName = &"") -> void:
	event_id = p_event
	encounter_id = p_encounter
	initiator_id = p_initiator
	trigger_source = p_source
