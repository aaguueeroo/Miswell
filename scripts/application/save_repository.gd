class_name SaveRepository
extends RefCounted

func read_slot(_slot_id: StringName) -> Dictionary:
	return {"ok": false, "exists": false, "error": "Save repository is not implemented."}

func write_slot(_slot_id: StringName, _data: Dictionary) -> Dictionary:
	return {"ok": false, "error": "Save repository is not implemented."}
