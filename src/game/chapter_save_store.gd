extends RefCounted
## Single manual slot, staged writes and one last-known-valid backup.
## File paths are injected for tests; gameplay always uses user://, never the executable folder.

const Session := preload("res://src/game/chapter_session.gd")
const MAX_BYTES := 262144
const DEFAULT_PATH := "user://chapter-one.json"

var _path: String


func _init(path: String = DEFAULT_PATH) -> void:
	_path = path


func save_session(session: Session) -> Dictionary:
	if session == null:
		return _failure("invalid")
	var data := session.save_data()
	if session.restore_save(data) == null:
		return _failure("invalid")
	var serialized := JSON.stringify(data)
	if serialized.to_utf8_buffer().size() > MAX_BYTES:
		return _failure("too_large")
	var current := _read(_path)
	if current["error"] == "version":
		return current
	if not current["ok"]:
		var backup := _read(_path + ".bak")
		if backup["error"] == "version":
			return backup
	var pending_path := _path + ".tmp"
	var file := FileAccess.open(pending_path, FileAccess.WRITE)
	if file == null:
		return _failure("write")
	file.store_string(serialized)
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK or not _read(pending_path)["ok"]:
		return _failure("write")
	# Keep the current valid slot safe until the new file has been fully written and checked.
	if current["ok"]:
		var backup_pending := _path + ".bak.tmp"
		if DirAccess.copy_absolute(_path, backup_pending) != OK:
			return _failure("write")
		if DirAccess.rename_absolute(backup_pending, _path + ".bak") != OK:
			return _failure("write")
	if DirAccess.rename_absolute(pending_path, _path) != OK:
		return _failure("write")
	return {"ok": true, "error": ""}


func load_session() -> Dictionary:
	var primary := _read(_path)
	if primary["ok"]:
		primary["recovered"] = false
		return primary
	# Do not silently downgrade a save written by a different story/schema revision.
	if primary["error"] == "version":
		return primary
	var backup := _read(_path + ".bak")
	if backup["error"] == "version":
		return backup
	if backup["ok"]:
		backup["recovered"] = true
		return backup
	return primary


func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return _failure("missing")
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return _failure("read")
	if file.get_length() > MAX_BYTES:
		file.close()
		return _failure("too_large")
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(text) != OK or not json.data is Dictionary:
		return _failure("invalid")
	var data: Dictionary = json.data
	if data.has("version") and data["version"] != Session.SAVE_VERSION:
		return _failure("version")
	if data.has("chapter") and data["chapter"] != Session.CONTENT_REVISION:
		return _failure("version")
	var restored := Session.new().restore_save(data)
	if restored == null:
		return _failure("invalid")
	return {"ok": true, "error": "", "session": restored}


func _failure(reason: String) -> Dictionary:
	return {"ok": false, "error": reason}
