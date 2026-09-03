extends RefCounted

const Session := preload("res://src/game/chapter_session.gd")
const Store := preload("res://src/game/chapter_save_store.gd")
const Scene := preload("res://scenes/main.tscn")
const Content := preload("res://src/content/chapter_one.gd")


func run(root: Node) -> Array[String]:
	var failures: Array[String] = []
	_test_round_trips(failures)
	_test_invalid_data(failures)
	var directory := "user://save-tests-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	if DirAccess.make_dir_recursive_absolute(directory) != OK:
		return ["Cannot create isolated save-test directory"]
	var path := directory + "/slot.json"
	_test_files(path, failures)
	_clean_files(path)
	_test_ui(root, path, failures)
	_clean_files(path)
	DirAccess.remove_absolute(directory)
	return failures


func _test_round_trips(failures: Array[String]) -> void:
	for route: Array in [
		[&"photo", &"letter", &"recording", &"leave"],
		[&"switch", &"repair", &"switch", &"recording", &"eat", &"portrait", &"photo", &"letter", &"leave"],
	]:
		var session := Session.new()
		_check_and_drain(session, failures)
		for action: StringName in route:
			_expect(session.act(action), "route action valid", failures)
			_check_and_drain(session, failures)
		_expect(session.view()["completed"], "route finishes after restored dialogue", failures)
		_expect(not session.act(&"notice"), "finished chapter rejects extra input", failures)
		_check_round_trip(session, failures)


func _check_and_drain(session: RefCounted, failures: Array[String]) -> void:
	_check_round_trip(session, failures)
	while session.speaking():
		session.advance()
		_check_round_trip(session, failures)


func _check_round_trip(session: RefCounted, failures: Array[String]) -> void:
	var payload: Variant = JSON.parse_string(JSON.stringify(session.save_data()))
	var restored: RefCounted = session.restore_save(payload)
	_expect(restored != null, "JSON round trip accepted", failures)
	if restored == null:
		return
	_expect(restored.view() == session.view(), "restore exact line, pending evidence and facts", failures)
	_expect(restored.save_data() == session.save_data(), "restore exact legal action history", failures)
	if restored.speaking():
		var control: RefCounted = session.restore_save(payload)
		restored.advance()
		control.advance()
		_expect(restored.view() == control.view(), "restored continuation deterministic", failures)


func _test_invalid_data(failures: Array[String]) -> void:
	var session := Session.new()
	var before := session.view()
	var invalid: Array = [null, [], {}, {"version": 1, "chapter": Session.CONTENT_REVISION, "events": ["photo"]}]
	for field: String in ["version", "chapter", "events"]:
		for value: Variant in [null, true, {}, "invalid"]:
			var data := session.save_data()
			data[field] = value
			invalid.append(data)
	for event: Variant in ["unknown", 42, {}, "x".repeat(33)]:
		var data := session.save_data()
		data["events"] = [event]
		invalid.append(data)
	var oversized := session.save_data()
	oversized["events"] = []
	oversized["events"].resize(Session.MAX_SAVE_EVENTS + 1)
	invalid.append(oversized)
	var injected := session.save_data()
	injected["facts"] = {"sister_dead": true}
	invalid.append(injected)
	for data: Variant in invalid:
		_expect(session.restore_save(data) == null, "invalid input rejected", failures)
		_expect(session.view() == before, "failed restore preserves live session", failures)
	var exported := session.save_data()
	exported["events"].append("advance")
	_expect(session.save_data()["events"].is_empty(), "save snapshot isolated", failures)
	session.act(&"photo") # Rejected during the opening dialogue.
	_expect(session.save_data()["events"].is_empty(), "rejected actions never persisted", failures)


func _test_files(path: String, failures: Array[String]) -> void:
	var store := Store.new(path)
	_expect(not store.load_session()["ok"], "missing save is recoverable error", failures)
	var first := Session.new()
	_expect(store.save_session(first)["ok"], "create manual slot", failures)
	for field: String in ["version", "chapter"]:
		var bad_header := first.save_data()
		bad_header[field] = {}
		_write(path, JSON.stringify(bad_header))
		_expect(not store.load_session()["ok"], "reject wrong-type file headers without runtime errors", failures)
	_write(path, JSON.stringify(first.save_data()))
	first.advance()
	_expect(store.save_session(first)["ok"], "replace slot and create backup", failures)
	var result := store.load_session()
	_expect(result["ok"] and not result["recovered"], "load primary", failures)
	if result["ok"]:
		_expect(result["session"].view() == first.view(), "primary has latest progress", failures)
	_write(path, "{broken")
	result = store.load_session()
	_expect(result["ok"] and result.get("recovered", false), "corrupt primary recovers backup", failures)
	if result["ok"]:
		_expect(result["session"].view() == Session.new().view(), "backup contains previous slot", failures)
	_expect(store.save_session(first)["ok"], "saving after corruption repairs primary", failures)
	_write(path, "x".repeat(Store.MAX_BYTES + 1))
	_expect(store.load_session().get("recovered", false), "oversized primary uses valid backup", failures)
	var future := first.save_data()
	future["version"] = 999
	_write(path, JSON.stringify(future))
	_expect(store.load_session()["error"] == "version", "do not downgrade future save", failures)
	_expect(store.save_session(first)["error"] == "version", "do not overwrite future save", failures)
	_expect(FileAccess.get_file_as_string(path) == JSON.stringify(future), "future save unchanged", failures)
	_write(path, JSON.stringify(first.save_data()))
	var original := FileAccess.get_file_as_string(path)
	DirAccess.make_dir_absolute(path + ".tmp")
	_expect(store.save_session(first)["error"] == "write", "staging failure reported", failures)
	_expect(FileAccess.get_file_as_string(path) == original, "write failure preserves primary", failures)
	DirAccess.remove_absolute(path + ".tmp")
	DirAccess.remove_absolute(path)
	_write(path + ".bak", JSON.stringify(future))
	_expect(store.load_session()["error"] == "version", "report incompatible backup when primary missing", failures)
	_expect(store.save_session(first)["error"] == "version", "protect incompatible backup from downgrade", failures)


func _test_ui(root: Node, path: String, failures: Array[String]) -> void:
	var screen := Scene.instantiate()
	screen.save_store = Store.new(path)
	root.add_child(screen)
	screen.next_button.pressed.emit()
	var saved: Dictionary = screen.session.view()
	screen.save_button.pressed.emit()
	_expect(screen.save_status.text == Content.SAVE_OK, "UI reports saved state", failures)
	screen.next_button.pressed.emit()
	screen.load_button.pressed.emit()
	_expect(screen.session.view() == saved, "UI restores interrupted dialogue", failures)
	_expect(screen.next_button.has_focus(), "restored dialogue receives focus", failures)
	screen.restart_button.pressed.emit()
	screen.load_button.pressed.emit()
	_expect(screen.session.view() == saved, "restart does not delete disk slot", failures)
	_write(path, "null")
	var original: RefCounted = screen.session
	screen.load_button.pressed.emit()
	_expect(screen.session == original, "failed load keeps same live session", failures)
	_expect(screen.save_status.text == Content.SAVE_ERRORS["invalid"], "UI reports corrupt file", failures)
	screen.free()


func _write(path: String, content: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(content)
	file.close()


func _clean_files(path: String) -> void:
	for suffix: String in ["", ".tmp", ".bak", ".bak.tmp"]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(path + suffix)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("Saves: " + message)
