extends RefCounted

const Scene := preload("res://scenes/main.tscn")
const Content := preload("res://src/content/chapter_one.gd")


func run(root: Window) -> Array[String]:
	var failures: Array[String] = []
	var screen := Scene.instantiate()
	root.add_child(screen)
	_expect(screen.next_button.has_focus(), "initial keyboard focus", failures)
	_drain(screen)
	_expect(screen.action_buttons[&"notice"].has_focus(), "focus returns to investigation", failures)
	screen.action_buttons[&"photo"].pressed.emit()
	_expect(screen.next_button.has_focus(), "action focuses dialogue continuation", failures)
	_drain(screen)
	var snapshot: Dictionary = screen.session.view()
	screen.sandbox_button.pressed.emit()
	_expect(not screen.chapter_scroll.visible, "sandbox hides chapter", failures)
	screen.back_button.pressed.emit()
	_expect(screen.chapter_scroll.visible, "return restores chapter", failures)
	_expect(screen.session.view() == snapshot, "sandbox never mutates canon", failures)
	for action: StringName in [&"letter", &"recording", &"leave"]:
		screen.action_buttons[action].pressed.emit()
		_drain(screen)
	_expect(screen.session.view()["completed"], "scene can complete chapter", failures)
	_expect(Content.UNKNOWN in screen.notebook_label.text, "notebook keeps fate unknown", failures)
	_expect(screen.restart_button.has_focus(), "completion focuses restart", failures)
	screen.restart_button.pressed.emit()
	_expect(not screen.session.view()["completed"], "restart clears completion", failures)
	_expect(screen.session.view()["done"].is_empty(), "restart clears progress", failures)
	var font: Font = screen.theme.default_font
	var source := FileAccess.get_file_as_string("res://src/content/chapter_one.gd")
	for index: int in range(source.length()):
		var code := source.unicode_at(index)
		if code > 32 and not font.has_char(code):
			failures.append("Bundled font missing character: " + source[index])
			break
	_expect(FileAccess.file_exists("res://assets/fonts/OFL.txt"), "font license available", failures)
	var original_size := root.size
	for viewport_size: Vector2i in [Vector2i(1280, 720), Vector2i(640, 480)]:
		root.size = viewport_size
		await root.get_tree().process_frame
		await root.get_tree().process_frame
		_expect(screen.chapter_scroll.size.x <= viewport_size.x + 1, "scroll fits viewport width", failures)
		for button: Button in screen.action_buttons.values():
			_expect(button.size.x <= viewport_size.x, "action text fits narrow viewport", failures)
	root.size = original_size
	screen.free()
	return failures


func _drain(screen: Control) -> void:
	for step: int in range(100):
		if not screen.session.speaking():
			return
		screen.next_button.pressed.emit()


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("Chapter UI: " + message)
