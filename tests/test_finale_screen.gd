extends RefCounted

const Scene := preload("res://scenes/main.tscn")
const Fixtures := preload("res://tests/test_finale_session.gd")
const Session := preload("res://src/game/finale_session.gd")
const Store := preload("res://src/game/chapter_save_store.gd")
const Common := preload("res://src/content/chapter_one.gd")


func run(root: Window) -> Array[String]:
	var failures: Array[String] = []
	var directory := "user://finale-tests-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	if DirAccess.make_dir_recursive_absolute(directory) != OK:
		return ["Cannot create isolated finale test directory"]
	var path := directory + "/arc.json"
	var screen := Scene.instantiate()
	root.add_child(screen)
	var nav: RefCounted = screen.finale_navigation
	nav.save_store = Store.new(path, Session)
	var original: RefCounted = screen.session
	nav.load_button.pressed.emit()
	_expect(screen.session == original and nav.screen == null, "failed direct load leaves earlier chapters intact", failures)
	# Walk all six chapters through real controls, not a debug chapter selector.
	_drain(screen)
	for action: StringName in [&"photo", &"portrait", &"letter", &"recording", &"leave"]:
		_press(screen, action, failures)
	screen.second_button.pressed.emit()
	_drain(screen.second_screen)
	for action: StringName in [&"telephone", &"tape", &"enter", &"listen", &"open", &"return", &"leave"]:
		_press(screen.second_screen, action, failures)
	screen.second_screen.finale_button.pressed.emit()
	var arc: Control = nav.screen
	_expect(arc != null and not screen.second_screen.visible, "second chapter enters finale", failures)
	_drain(arc)
	_expect(arc.action_buttons[&"admission"].has_focus(), "first enabled action focused", failures)
	var original_size := root.size
	for dimensions: Vector2i in [Vector2i(1280, 720), Vector2i(640, 480)]:
		root.size = dimensions
		await root.get_tree().process_frame
		await root.get_tree().process_frame
		_expect(arc.size.x <= dimensions.x + 1, "arc fits viewport", failures)
		for button: Button in arc.action_buttons.values():
			_expect(button.size.x <= dimensions.x - 56, "action fits narrow viewport", failures)
	root.size = original_size
	for content: String in ["chapter_three", "chapter_four", "chapter_five", "chapter_six", "finale_content"]:
		var source := FileAccess.get_file_as_string("res://src/content/" + content + ".gd")
		for index: int in range(source.length()):
			if source.unicode_at(index) > 32 and not screen.theme.default_font.has_char(source.unicode_at(index)):
				failures.append("Finale font missing: " + source[index])
				break
	for action: StringName in [&"admission", &"equipment", &"report", &"patrol", &"diagram", &"match_cabinet", &"ask_audio", &"play_anyway", &"next"]:
		_press(arc, action, failures)
	_expect(arc.session.view()["chapter"] == 4 and not arc.action_buttons.has(&"admission"), "chapter transition rebuilds actions", failures)
	_press(arc, &"revisit", failures)
	_press(arc, &"connect_light", failures)
	_press(arc, &"boarding", failures)
	_press(arc, &"lower_ladder", failures)
	arc.action_buttons[&"confirm_platform"].pressed.emit()
	arc.next_button.pressed.emit()
	var saved: Dictionary = arc.session.view()
	arc.save_button.pressed.emit()
	_expect(arc.save_status.text == Common.SAVE_OK, "save pending platform observation", failures)
	arc.back_button.pressed.emit()
	_expect(screen.second_screen.visible, "return to chapter-two record", failures)
	screen.second_screen.finale_button.pressed.emit()
	_expect(nav.screen.session.view() == saved, "resume never rewinds choice", failures)
	arc.back_button.pressed.emit()
	screen.second_screen.restart_button.pressed.emit()
	_expect(nav.screen == null, "new second-chapter attempt discards dependent finale", failures)
	screen.second_back_button.pressed.emit()
	nav.load_button.pressed.emit()
	arc = nav.screen
	_expect(arc.session.view() == saved and arc.next_button.has_focus(), "direct load restores chapter and exact pending line", failures)
	_expect(screen.session.view()["facts"].has(&"portrait"), "deep first-chapter photo restored", failures)
	_expect(screen.second_screen.session.view()["facts"][&"c2_called"] == false, "matching second-chapter choice restored", failures)
	_drain(arc)
	for action: StringName in [&"next", &"records", &"verify", &"invite", &"dinner", &"correction", &"next", &"memorial", &"portrait_join", &"departure"]:
		_press(arc, action, failures)
	_expect(arc.session.view()["facts"][&"ending_id"] == "kitchen", "UI reaches ending without final selection menu", failures)
	_expect(arc.save_button.has_focus(), "completion focuses saving the record", failures)
	arc.save_button.pressed.emit()
	_expect(arc.save_status.text == Common.SAVE_OK, "ending can be saved", failures)
	arc.restart_button.pressed.emit()
	_expect(arc.session.view()["chapter"] == 3, "restart starts third chapter only", failures)
	arc.load_button.pressed.emit()
	_expect(arc.session.view()["completed"], "load restores finished ending without reroll", failures)
	# Reading another arc file must restore the correct earlier records on return, too.
	var alternate := Session.new()
	alternate.start_after(Fixtures.new().previous(true))
	_expect(nav.save_store.save_session(alternate)["ok"], "alternate prologue saved", failures)
	arc.load_button.pressed.emit()
	arc.back_button.pressed.emit()
	_expect(screen.second_screen.session.view()["facts"][&"c2_called"] == true, "in-arc load updates earlier record on return", failures)
	screen.second_screen.finale_button.pressed.emit()
	_test_files(path, arc, failures)
	screen.free()
	for suffix: String in ["", ".bak", ".tmp", ".bak.tmp"]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(path + suffix)
	DirAccess.remove_absolute(directory)
	return failures


func _test_files(path: String, arc: Control, failures: Array[String]) -> void:
	var payload: Dictionary = arc.session.save_data()
	_write(path, "{broken")
	arc.load_button.pressed.emit()
	_expect(arc.save_status.text == Common.LOAD_BACKUP, "corrupt arc file recovers prior valid backup", failures)
	var old: RefCounted = arc.session
	for depth: int in range(3):
		var future := payload.duplicate(true)
		var header := future
		for index: int in range(depth):
			header = header["prologue"]
		header["chapter"] = "future-chapter"
		_write(path, JSON.stringify(future))
		arc.load_button.pressed.emit()
		_expect(arc.session == old and arc.save_status.text == Common.SAVE_ERRORS["version"], "all nested revisions block load", failures)
		arc.save_button.pressed.emit()
		_expect(arc.save_status.text == Common.SAVE_ERRORS["version"], "all nested revisions block overwrite", failures)
		_expect(FileAccess.get_file_as_string(path) == JSON.stringify(future), "unsupported file untouched", failures)
	_write(path, JSON.stringify(payload))
	DirAccess.make_dir_absolute(path + ".tmp")
	arc.save_button.pressed.emit()
	_expect(arc.save_status.text == Common.SAVE_ERRORS["write"], "write failure surfaced", failures)
	_expect(FileAccess.get_file_as_string(path) == JSON.stringify(payload), "write failure preserves primary", failures)
	DirAccess.remove_absolute(path + ".tmp")


func _write(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func _press(screen: Control, action: StringName, failures: Array[String]) -> void:
	_expect(screen.action_buttons.has(action) and not screen.action_buttons[action].disabled, "available UI action: " + action, failures)
	if screen.action_buttons.has(action):
		screen.action_buttons[action].pressed.emit()
	_drain(screen)


func _drain(screen: Control) -> void:
	for count: int in range(128):
		if not screen.session.speaking():
			return
		screen.next_button.pressed.emit()


func _expect(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append("Finale UI: " + message)
