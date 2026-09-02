extends RefCounted

const MainScene := preload("res://scenes/room.tscn")


func run(root: Node) -> Array[String]:
	var failures: Array[String] = []
	var screen := MainScene.instantiate()
	root.add_child(screen)
	_expect(not screen.call_button.disabled, "call starts enabled", failures)
	screen.call_button.pressed.emit()
	_expect(screen.call_button.disabled, "call disables after use", failures)
	screen.listen_button.pressed.emit()
	_expect(screen.listen_button.disabled, "listen disables after use", failures)
	_expect("unconfirmed" in screen.status_label.text, "UI keeps safety unknown", failures)
	_expect("partially observed" in screen.status_label.text, "UI distinguishes partial observation", failures)
	screen.open_button.pressed.emit()
	_expect(screen.open_button.disabled, "opening ends attempt", failures)
	_expect("dry coat" in screen.story_label.text, "UI renders reunion", failures)
	_expect("confirmed safe" in screen.status_label.text, "UI renders anchored safety", failures)
	screen.restart_button.pressed.emit()
	_expect(not screen.call_button.disabled, "restart restores call", failures)
	_expect(not screen.listen_button.disabled, "restart restores listen", failures)
	_expect(not screen.open_button.disabled, "restart restores open", failures)
	_expect(screen.session.view()["facts"].is_empty(), "restart clears history", failures)
	screen.listen_button.pressed.emit()
	_expect(screen.call_button.disabled, "UI blocks late call", failures)
	screen.free()
	return failures


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("Room UI: " + message)
