extends RefCounted

const Session := preload("res://src/game/finale_session.gd")
const Fixture := preload("res://tests/test_finale_session.gd")
const View := preload("res://src/ui/finale_view.gd")
const Spatial := preload("res://src/game/finale_interactions.gd")
const Main := preload("res://scenes/main.tscn")


static func fresh() -> RefCounted:
	var session := Session.new()
	session.start_after(Fixture.new().previous(false))
	return session


static func drain(view: Control) -> void:
	for i: int in range(128):
		if not view.session.speaking():
			return
		view._advance()


static func approach(view: Control, action: StringName) -> void:
	for zone: Dictionary in Spatial.ZONES[view.session.view()["chapter"]]:
		if action in zone["actions"]:
			var at: Vector2 = zone["at"]
			view.player.position = Vector3(at.x, 0.08, at.y)
			view.refresh()
			return


static func step(view: Control, action: StringName, failures: Array[String]) -> void:
	approach(view, action)
	if not view.action_buttons.has(action):
		failures.append("Finale 3D: unreachable action " + action)
		return
	var before: Dictionary = view.session.save_data()
	view.action_buttons[action].pressed.emit()
	if view.session.save_data() == before:
		failures.append("Finale 3D: rejected visible action " + action)
	drain(view)


func run(root: Window) -> Array[String]:
	var failures: Array[String] = []
	for ending: String in ["kitchen", "distance", "name", "blank"]:
		var view := View.new()
		view.session = fresh()
		root.add_child(view)
		view.set_physics_process(false)
		drain(view)
		var before: Dictionary = view.session.save_data()
		view._act(&"admission")
		_expect(view.session.save_data() == before, "remote action ignored", failures)
		for action: StringName in [&"admission", &"equipment", &"stretcher", &"report", &"patrol", &"diagram", &"match_cabinet", &"forgive", &"ask_audio"]:
			step(view, action, failures)
		step(view, &"play_anyway" if ending == "distance" else &"respect", failures)
		_expect(view.room.shiori.visible == (ending != "distance"), "boundary controls studio presence", failures)
		var old_room: WeakRef = weakref(view.room)
		step(view, &"next", failures)
		_expect(old_room.get_ref() == null and view.shown_chapter == 4, "transition disposes previous set", failures)
		step(view, &"revisit", failures)
		_expect(not view.room.backup.visible and is_equal_approx(view._visual.scale.x, 0.7), "historical window starts unprepared", failures)
		if ending in ["kitchen", "distance"]:
			approach(view, &"connect_light")
			view._act(&"connect_light")
			_expect(not view.room.backup.visible, "pending light is not committed art", failures)
			# Every mid-dialogue restore uses the same scene state, without consuming input.
			var restored: RefCounted = Session.new().restore_save(view.session.save_data())
			_expect(restored != null and restored.view() == view.session.view(), "pending action round trip", failures)
			drain(view)
			_expect(view.room.backup.visible, "committed backup visible", failures)
		step(view, &"boarding", failures)
		if ending in ["kitchen", "distance"]:
			step(view, &"lower_ladder", failures)
			_expect(is_equal_approx(view.room.ladder.rotation.x, PI), "committed ladder lowered", failures)
		step(view, &"leave_blank" if ending == "blank" else &"confirm_platform", failures)
		_expect(not view.session.view()["facts"].has(&"sister_fate"), "platform rendering does not invent fate", failures)
		_expect(view._visual.scale.x == 1.0, "closed window restores present avatar", failures)
		step(view, &"next", failures)
		step(view, &"records", failures)
		step(view, &"seal" if ending == "blank" else &"verify", failures)
		_expect(view.room.seal.visible == (ending == "blank"), "sealed folder follows committed choice", failures)
		if ending in ["kitchen", "distance"]:
			step(view, &"invite" if ending == "kitchen" else &"no_invite", failures)
		step(view, &"dinner", failures)
		step(view, &"correction", failures)
		_expect(view.room.correction.visible, "correction retained next to original", failures)
		step(view, &"next", failures)
		_expect(view.shown_chapter == 6 and not view.room.inscription.visible, "memorial starts unsigned", failures)
		step(view, &"memorial", failures)
		_expect(view.room.inscription.visible and view.room.shiori.visible == (ending != "distance"), "farewell respects evidence and relationship", failures)
		step(view, &"portrait_decline" if ending == "blank" else &"portrait_join", failures)
		step(view, &"departure", failures)
		_expect(view.session.view()["facts"].get(&"ending_id") == ending, "3D reaches ending " + ending, failures)
		_expect(view.action_buttons.is_empty(), "finished scene has no repeat choices", failures)
		view.free()
	await root.get_tree().create_timer(0.1).timeout
	await _navigation(root, failures)
	return failures


func _navigation(root: Window, failures: Array[String]) -> void:
	var host := Main.instantiate()
	root.add_child(host)
	host._show_second(Fixture.new().previous())
	host.finale_navigation.enter()
	var screen: Control = host.finale_navigation.screen
	var saved: Dictionary = screen.session.save_data()
	screen.spatial_button.pressed.emit()
	var view: Control = screen.spatial_view
	_expect(view.session == screen.session and not screen.scroll.visible, "same session injected", failures)
	view.hide()
	var event := InputEventJoypadButton.new()
	event.button_index = JOY_BUTTON_A
	event.pressed = true
	view._input(event)
	_expect(screen.session.save_data() == saved, "hidden view ignores controller", failures)
	view.show()
	view.return_requested.emit()
	_expect(screen.spatial_view == null and screen.scroll.visible and screen.session.save_data() == saved, "return preserves pending line", failures)
	await root.get_tree().process_frame
	screen.spatial_button.pressed.emit()
	host.finale_navigation.return_to_records()
	_expect(screen.spatial_view == null and host.second_screen.visible, "earlier records dispose 3D", failures)
	host.finale_navigation.enter()
	screen.spatial_button.pressed.emit()
	var old_session: RefCounted = screen.session
	screen._restart()
	_expect(screen.spatial_view == null and screen.session != old_session, "restart disposes stale session view", failures)
	host.free()
	await root.get_tree().create_timer(0.1).timeout


func _expect(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append("Finale 3D: " + message)
