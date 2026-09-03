extends RefCounted

const First := preload("res://src/game/chapter_session.gd")
const Second := preload("res://src/game/chapter_two_session.gd")
const Content := preload("res://src/content/chapter_two.gd")
const Scene := preload("res://scenes/main.tscn")
const Store := preload("res://src/game/chapter_save_store.gd")


func run(root: Window) -> Array[String]:
	var failures: Array[String] = []
	_test_routes(failures)
	_test_invalid(failures)
	await _test_ui(root, failures)
	return failures


func _first(portrait: bool = false) -> RefCounted:
	var session := First.new()
	_drain(session)
	for action: StringName in [&"photo", &"recording", &"letter"]:
		session.act(action)
		_drain(session)
	if portrait:
		session.act(&"portrait")
		_drain(session)
	session.act(&"leave")
	_drain(session)
	return session


func _test_routes(failures: Array[String]) -> void:
	for called: bool in [false, true]:
		for listened: bool in [false, true]:
			for portrait: bool in [false, true]:
				var first := _first(portrait)
				var session := Second.new()
				_expect(session.start_after(first), "completed prologue accepted", failures)
				_check_drain(session, failures)
				_expect(not session.act(&"call"), "modern telephone cannot change history", failures)
				_expect(not session.act(&"enter"), "revisit requires both sources", failures)
				var actions: Array = [&"telephone", &"tape", &"enter"] if portrait else [&"tape", &"telephone", &"enter"]
				if called:
					actions.append(&"call")
				if listened:
					actions.append(&"listen")
				actions.append_array([&"open", &"return", &"review", &"review", &"leave"])
				for action: StringName in actions:
					_expect(session.act(action), "legal route action " + action, failures)
					if action == &"call":
						_expect(session.view()["facts"].get(&"c2_called") == true, "chosen call fixed immediately", failures)
						_expect(not session.view()["facts"].has(&"c2_words"), "unread words remain pending", failures)
					if action == &"open":
						_expect(not session.view()["facts"].has(&"c2_escort"), "unread door identity pending", failures)
					_check_drain(session, failures)
					if action == &"listen":
						_expect(not session.can_act(&"call"), "outage closes call", failures)
						_expect(not session.view()["facts"].has(&"c2_escort"), "footsteps do not identify escort", failures)
						_expect(not session.can_act(&"listen"), "cannot replay listening", failures)
					if action == &"return":
						_expect(not session.act(&"enter"), "window cannot reopen", failures)
						_expect(not session.act(&"call"), "cannot change completed call", failures)
					for forbidden: StringName in [&"connect_light", &"lower_ladder", &"repair", &"sister_dead"]:
						_expect(not session.act(forbidden), "future/out-of-window input rejected", failures)
					var facts: Dictionary = session.view()["facts"]
					for key: StringName in first.view()["facts"]:
						_expect(facts[key] == first.view()["facts"][key], "all prologue evidence stable", failures)
					_expect(not facts.has(&"sister_dead") and not facts.has(&"sister_alive"), "no fate inference", failures)
					_expect(not facts.has(&"light_connected") and not facts.has(&"ladder_lowered"), "future preparations unanchored", failures)
				_expect(session.view()["completed"], "every route completes", failures)
				_expect(session.view()["facts"][&"c2_escort"] == ("keeper" if called else "sister"), "authored deterministic escort", failures)
				_expect(session.view()["facts"].has(&"c2_cabinet_known") == called, "call yields information only", failures)
				_expect(not session.act(&"review"), "completed session locked", failures)
				var snapshot := session.view()
				snapshot["facts"][&"children_survived"] = false
				_expect(session.view()["facts"][&"children_survived"], "snapshot isolated", failures)
				var fresh := session.new_attempt()
				_expect(fresh.view()["facts"] == first.view()["facts"], "explicit new attempt preserves prologue only", failures)


func _test_invalid(failures: Array[String]) -> void:
	var session := Second.new()
	_expect(not session.start_after(First.new()), "incomplete prologue refused", failures)
	_expect(not session.act(&"enter") and not session.advance(), "uninitialized session cannot play", failures)
	_expect(session.restore_save(session.save_data()) == null, "uninitialized session cannot save", failures)
	session.start_after(_first())
	_expect(not session.start_after(_first(true)), "cannot replace anchored prologue", failures)
	var original := session.view()
	var cases: Array = [null, {}, [], true]
	for field: String in ["version", "chapter", "prologue", "events"]:
		for value: Variant in [null, true, {}, "bad"]:
			var data := session.save_data()
			data[field] = value
			cases.append(data)
	for event: Variant in ["call", "connect_light", 1, {}, "x".repeat(33)]:
		var data := session.save_data()
		data["events"] = [event]
		cases.append(data)
	var oversized := session.save_data()
	oversized["events"].resize(Second.MAX_SAVE_EVENTS + 1)
	cases.append(oversized)
	var extra := session.save_data()
	extra["facts"] = {"children_survived": false}
	cases.append(extra)
	var incomplete := session.save_data()
	incomplete["prologue"] = First.new().save_data()
	cases.append(incomplete)
	for data: Variant in cases:
		_expect(session.restore_save(data) == null, "invalid replay rejected", failures)
		_expect(session.view() == original, "rejected replay never mutates live attempt", failures)
	var isolated := session.save_data()
	isolated["prologue"]["events"].clear()
	_expect(not session.save_data()["prologue"]["events"].is_empty(), "nested save isolated", failures)
	# Fault injection: a bad authored observation must not consume the final dialogue step.
	_drain(session)
	session.act(&"telephone")
	session.advance()
	session._pending[&"children_survived"] = false
	var before_fault := session.save_data()
	_expect(not session.advance(), "conflicting observation refused", failures)
	_expect(session.save_data() == before_fault and session.speaking(), "failed observation keeps cursor and input log", failures)
	_expect(not session.view()["facts"].has(&"c2_outage_record"), "observation rejected atomically", failures)


func _test_ui(root: Window, failures: Array[String]) -> void:
	var directory := "user://chapter-two-tests-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	if DirAccess.make_dir_recursive_absolute(directory) != OK:
		failures.append("Cannot create isolated chapter-two fixture directory")
		return
	var path := directory + "/second.json"
	var screen := Scene.instantiate()
	screen.second_store = Store.new(path, Second)
	root.add_child(screen)
	_expect(screen.second_button.disabled, "chapter progression gated", failures)
	var original: RefCounted = screen.session
	screen.load_second_button.pressed.emit()
	_expect(screen.session == original, "failed chapter load leaves active progress intact", failures)
	screen.session = _first(true)
	screen._refresh()
	screen.second_button.pressed.emit()
	var second: Control = screen.second_screen
	_expect(second != null and not screen.chapter_scroll.visible, "chapter two entered", failures)
	var original_size := root.size
	for viewport_size: Vector2i in [Vector2i(1280, 720), Vector2i(640, 480)]:
		root.size = viewport_size
		await root.get_tree().process_frame
		await root.get_tree().process_frame
		_expect(second.size.x <= viewport_size.x + 1, "second screen fits viewport", failures)
		for button: Button in second.action_buttons.values():
			_expect(button.size.x <= viewport_size.x - 56, "second action fits narrow viewport", failures)
	root.size = original_size
	var font: Font = screen.theme.default_font
	var source := FileAccess.get_file_as_string("res://src/content/chapter_two.gd")
	for index: int in range(source.length()):
		if source.unicode_at(index) > 32 and not font.has_char(source.unicode_at(index)):
			failures.append("Second-chapter font missing: " + source[index])
			break
	_drain_ui(second)
	_expect(second.action_buttons[&"telephone"].has_focus(), "focus returns to first legal action", failures)
	for action: StringName in [&"telephone", &"tape", &"enter", &"listen"]:
		second.action_buttons[action].pressed.emit()
		_drain_ui(second)
	second.action_buttons[&"open"].pressed.emit()
	second.next_button.pressed.emit()
	var saved: Dictionary = second.session.view()
	second.save_button.pressed.emit()
	_expect(second.save_status.text == Content.SAVE_OK, "second chapter file saved", failures)
	_expect(not Store.new(path).save_session(second.session)["ok"], "store rejects wrong session type", failures)
	_expect(Store.new(path).load_session()["error"] == "version", "first loader rejects second file", failures)
	second.sandbox_button.pressed.emit()
	second.back_button.pressed.emit()
	_expect(second.session.view() == saved, "sandbox does not mutate canon chapter two", failures)
	screen.second_back_button.pressed.emit()
	screen.second_button.pressed.emit()
	_expect(screen.second_screen.session.view() == saved, "chapter back/resume does not reopen window", failures)
	screen.second_back_button.pressed.emit()
	screen.restart_button.pressed.emit()
	_expect(screen.second_screen == null, "new first attempt discards dependent live chapter", failures)
	screen.load_second_button.pressed.emit()
	second = screen.second_screen
	_expect(second.session.view() == saved, "direct chapter-two load restores exact pending line", failures)
	_expect(screen.session.view()["facts"].has(&"portrait"), "direct load restores prologue optional photo", failures)
	_expect(second.action_buttons[&"call"].disabled, "load cannot reopen expired call", failures)
	_drain_ui(second)
	for action: StringName in [&"return", &"review", &"leave"]:
		second.action_buttons[action].pressed.emit()
		_drain_ui(second)
	_expect(second.session.view()["completed"], "UI completes second chapter", failures)
	# Nested first-chapter revisions need the same no-downgrade protection as the outer header.
	var file_data: Dictionary = second.session.save_data()
	file_data["prologue"]["chapter"] = "future-kitchen"
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(file_data))
	file.close()
	var prior: RefCounted = second.session
	second.load_button.pressed.emit()
	_expect(second.session == prior, "incompatible prologue leaves live chapter intact", failures)
	_expect(second.save_status.text == Content.SAVE_ERRORS["version"], "nested revision reported as incompatible", failures)
	_expect(screen.second_store.save_session(prior)["error"] == "version", "cannot overwrite incompatible prologue", failures)
	_expect(FileAccess.get_file_as_string(path) == JSON.stringify(file_data), "incompatible nested file unchanged", failures)
	screen.free()
	for suffix: String in ["", ".bak", ".tmp", ".bak.tmp"]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(path + suffix)
	DirAccess.remove_absolute(directory)


func _check_drain(session: RefCounted, failures: Array[String]) -> void:
	while true:
		var restored: RefCounted = session.restore_save(JSON.parse_string(JSON.stringify(session.save_data())))
		_expect(restored != null, "every step survives JSON replay", failures)
		if restored != null:
			_expect(restored.view() == session.view(), "exact facts, phase and pending line restored", failures)
		if not session.speaking():
			return
		session.advance()


func _drain(session: RefCounted) -> void:
	while session.speaking():
		session.advance()


func _drain_ui(screen: Control) -> void:
	while screen.session.speaking():
		screen.next_button.pressed.emit()


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("Chapter two: " + message)
