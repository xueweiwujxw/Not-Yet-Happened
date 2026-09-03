extends RefCounted

const Scene := preload("res://scenes/main.tscn")
const Spatial := preload("res://src/game/kitchen_interactions.gd")
const Session := preload("res://src/game/chapter_session.gd")


func run(root: Window) -> Array[String]:
	var failures: Array[String] = []
	var first := Session.new()
	_expect(Spatial.nearby(Vector3.ZERO, first).is_empty(), "dialogue locks spatial actions", failures)
	_drain(first)
	_expect(Spatial.nearby(Vector3(20, 0, 20), first).is_empty(), "remote interaction rejected", failures)
	_expect(Spatial.constrain(Vector3(100, 1, -100)) == Vector3(4.55, 1, -3.4), "open diorama edge remains bounded", failures)
	var screen := Scene.instantiate()
	root.add_child(screen)
	screen.kitchen_button.pressed.emit()
	var view: Control = screen.kitchen_view
	view.set_physics_process(false)
	_expect(view.session == screen.session, "3D and text use the same session", failures)
	_expect(not view.room.shiori.visible and not view.room.letter.visible, "NPCs and letter hidden before arrival", failures)
	var initial: Dictionary = screen.session.save_data()
	view.frame_camera(true)
	_expect(screen.session.save_data() == initial, "camera is not an observation", failures)
	view._act(&"photo")
	_expect(screen.session.save_data() == initial, "cannot interact during dialogue", failures)
	_drain(screen.session)
	view.refresh()
	view.player.position = Vector3(3.0, 0.1, 1.6)
	view._act(&"photo")
	_expect(screen.session.speaking(), "nearby photo interaction reaches existing dialogue", failures)
	_expect(not screen.session.view()["facts"].has(&"photo_front"), "rendered photo does not pre-confirm evidence", failures)
	_drain(screen.session)
	view.refresh()
	_expect(view.room.shiori.visible and view.room.shen.visible and view.room.letter.visible, "arrival projected from chapter state", failures)
	var visible_state: Dictionary = screen.session.save_data()
	view.player.position = Vector3(0, 0.1, 3.3)
	view._act(&"photo")
	_expect(screen.session.save_data() == visible_state, "out-of-range action cannot bypass proximity", failures)
	view.player.position = Vector3(-4.0, 0.1, 0.6)
	view._act(&"switch")
	_drain(screen.session)
	view.player.position = Vector3(-1.5, 0.1, 1.3)
	view._act(&"repair")
	_drain(screen.session)
	view.player.position = Vector3(-4.0, 0.1, 0.6)
	view._act(&"switch")
	_drain(screen.session)
	view.refresh()
	_expect(view.room.lamp.visible, "working pendant follows repaired/on state", failures)
	# Actual physics ticks: the floor supports the player and the solid counter blocks travel.
	view.player.position = Vector3(-2.5, 0.1, -1.6)
	for count: int in range(45):
		await root.get_tree().physics_frame
		view.player.velocity = Vector3(0, -1, -2.5)
		view.player.move_and_slide()
	_expect(view.player.position.z > -2.3, "cabinet collider blocks player", failures)
	_expect(view.player.position.y > -0.1, "floor collider supports player", failures)
	var font: Font = screen.theme.default_font
	var source := FileAccess.get_file_as_string("res://src/content/kitchen_visual.gd")
	for index: int in range(source.length()):
		if source.unicode_at(index) > 32 and not font.has_char(source.unicode_at(index)):
			failures.append("Kitchen font missing: " + source[index])
			break
	view.back_button.grab_focus()
	var tab := InputEventKey.new()
	tab.physical_keycode = KEY_TAB
	tab.keycode = KEY_TAB
	tab.pressed = true
	root.push_input(tab)
	await root.get_tree().process_frame
	_expect(screen.kitchen_view == null and screen.chapter_scroll.visible, "Tab returns even with a focused GUI button", failures)
	_expect(screen.session.save_data() != initial and screen.session.view()["repaired"], "3D actions persist on return", failures)
	screen.free()
	return failures


func _drain(session: RefCounted) -> void:
	for count: int in range(100):
		if not session.speaking() or not session.advance():
			return


func _expect(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append("Kitchen 3D: " + message)
