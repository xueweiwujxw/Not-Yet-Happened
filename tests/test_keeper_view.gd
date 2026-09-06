extends RefCounted

const First := preload("res://src/game/chapter_session.gd")
const Second := preload("res://src/game/chapter_two_session.gd")
const Main := preload("res://scenes/main.tscn")


static func session() -> RefCounted:
	var first := First.new()
	drain(first)
	for action: StringName in [&"photo", &"recording", &"letter", &"leave"]:
		first.act(action)
		drain(first)
	var result := Second.new()
	result.start_after(first)
	return result


static func drain(value: RefCounted) -> void:
	for i: int in range(100):
		if not value.speaking() or not value.advance():
			return


func run(root: Window) -> Array[String]:
	var failures: Array[String] = []
	for called: bool in [false, true]:
		var screen := Main.instantiate()
		screen.is_second = true
		screen.session = session()
		root.add_child(screen)
		screen.kitchen_button.pressed.emit()
		var view: Control = screen.kitchen_view
		view.set_physics_process(false)
		var before: Dictionary = screen.session.save_data()
		view.frame_camera(true)
		view.refresh()
		_expect(screen.session.save_data() == before and view.session == screen.session, "view/camera preserve session", failures)
		_expect(not view.room.escort.visible and not view.room.waiting_child.visible, "no unobserved identity leak", failures)
		drain(screen.session)
		var actions: Array[StringName] = [&"telephone", &"tape", &"enter"]
		if called:
			actions.append(&"call")
		actions.append_array([&"listen", &"open", &"return", &"leave"])
		for action: StringName in actions:
			view.player.position = Vector3(4.4, 0.1, 3.3)
			before = screen.session.save_data()
			view._act(action)
			_expect(before == screen.session.save_data(), "remote action rejected", failures)
			var at := Vector3(2.5, 0.1, -1.6)
			if action in [&"telephone", &"call"]:
				at = Vector3(-3.4, 0.1, -1.2)
			elif action in [&"tape", &"enter"]:
				at = Vector3(-0.7, 0.1, -1.2)
			elif action == &"leave":
				at = Vector3(-3.8, 0.1, 2.5)
			view.player.position = at
			view._act(action)
			_expect(screen.session.speaking(), "spatial action accepted: " + action, failures)
			if action == &"open":
				_expect(not view.room.waiting_child.visible and view.room.door.rotation.y == 0, "pending observation does not reveal doorway", failures)
			drain(screen.session)
			view.refresh()
			if action == &"listen":
				_expect(not view.room.lamp.visible and not view.room.escort.visible, "outage is not identity evidence", failures)
			if action == &"open":
				_expect(view.room.waiting_child.visible and view.room.escort.visible == called, "confirmed route projected", failures)
			if action == &"return":
				_expect(not view.room.waiting_child.visible and not screen.session.can_act(&"enter"), "return cannot reopen history", failures)
		_expect(screen.session.view()["completed"], "3D route completes", failures)
		screen.kitchen_view.back_button.pressed.emit()
		await root.get_tree().process_frame
		_expect(screen.kitchen_view == null and screen.chapter_scroll.visible, "notebook return", failures)
		screen.free()
	# Exercise real nested chapter navigation, not only a standalone second screen.
	var parent := Main.instantiate()
	parent.session = First.new().restore_save(session().save_data()["prologue"])
	root.add_child(parent)
	parent._enter_second()
	parent.second_screen.kitchen_button.pressed.emit()
	var nested: Control = parent.second_screen.kitchen_view
	nested.set_physics_process(false)
	var saved: Dictionary = nested.session.save_data()
	parent.second_screen.hide()
	var key := InputEventJoypadButton.new()
	key.button_index = JOY_BUTTON_A
	key.pressed = true
	nested._input(key)
	_expect(nested.session.save_data() == saved, "hidden nested view ignores input", failures)
	parent.second_screen.show()
	parent._return_first()
	await root.get_tree().process_frame
	_expect(parent.second_screen.kitchen_view == null and parent.chapter_scroll.visible, "cross-chapter return removes camera/view", failures)
	parent.free()
	await root.get_tree().create_timer(0.1).timeout
	return failures


func _expect(ok: bool, message: String, failures: Array[String]) -> void:
	if not ok:
		failures.append("Keeper 3D: " + message)
