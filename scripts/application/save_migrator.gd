class_name SaveMigrator
extends RefCounted

const CURRENT_SCHEMA_VERSION := 1

func migrate_record(record: Dictionary) -> Dictionary:
	var version := int(record.get("schema_version", 0))
	if version != CURRENT_SCHEMA_VERSION:
		return {"ok": false, "error": "This save uses an unsupported format."}
	return {"ok": true, "data": record}
