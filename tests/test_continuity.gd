extends RefCounted

const F := preload("res://tests/test_finale_view.gd")

func run(root: Window) -> Array[String]:
	var failures: Array[String] = []
	var view := F.View.new()
	view.session = F.fresh()
	root.add_child(view)
	view.set_process(false)
	view.set_physics_process(false)
	F.drain(view)
	for action: StringName in [&"admission", &"equipment", &"report", &"patrol", &"diagram", &"match_cabinet", &"ask_audio", &"respect", &"next", &"revisit", &"confirm_platform", &"next"]:
		F.step(view, action, failures)
	F.approach(view, &"records")
	view._act(&"records")
	check(view.story_label.text == view.session.view()["line"], "zone updates preserve current dialogue", failures)
	F.drain(view)
	var saved: Dictionary = view.session.save_data()
	var pad := InputEventJoypadButton.new()
	pad.pressed = true
	pad.button_index = JOY_BUTTON_A
	view._input(pad)
	check(view.session.save_data() == saved and view.choice_index == -1, "post-dialogue A is isolated", failures)
	view._process(0.3)
	view._input(pad)
	check(view.session.save_data() == saved and view.choice_index == 0, "first A selects without committing", failures)
	view._input(pad)
	check(view.pending_decision == &"verify" and view.session.save_data() == saved, "second A warns before identity verification", failures)
	view._input(pad)
	check(view.session.save_data() == saved, "rapid A cannot accept confirmation", failures)
	pad.button_index = JOY_BUTTON_B
	view._input(pad)
	check(view.pending_decision.is_empty() and view.session.save_data() == saved, "B cancels without choosing", failures)
	view._process(0.3)
	var key := InputEventKey.new()
	key.pressed = true
	key.physical_keycode = KEY_RIGHT
	view._input(key)
	check(view.choice_index == 1, "arrow selects seal instead of default verify", failures)
	key.physical_keycode = KEY_E
	view._unhandled_input(key)
	check(view.pending_decision == &"seal" and view.session.save_data() == saved, "E requests selected choice", failures)
	key.echo = true
	view._unhandled_input(key)
	check(view.session.save_data() == saved, "held E does not commit", failures)
	key.echo = false
	view._process(0.3)
	view._unhandled_input(key)
	check(view.session.save_data()["events"][-1] == "seal", "deliberate confirmation commits selected action once", failures)
	view.free()
	await review_dinner(root, failures)
	review_platform(root, failures)
	await root.get_tree().create_timer(0.1).timeout
	return failures

func check(ok: bool, message: String, failures: Array[String]) -> void:
	if not ok:
		failures.append("Continuity: " + message)

func dinner_view(root: Window, failures: Array[String]) -> Control:
	var view := F.View.new()
	view.session = F.fresh()
	root.add_child(view)
	view.set_process(false)
	view.set_physics_process(false)
	F.drain(view)
	for action: StringName in [&"admission", &"equipment", &"report", &"patrol", &"diagram", &"match_cabinet", &"ask_audio", &"respect", &"next", &"revisit", &"leave_blank", &"next"]:
		F.step(view, action, failures)
	F.approach(view, &"dinner")
	view._act(&"dinner")
	return view

func review_dinner(root: Window, failures: Array[String]) -> void:
	for time: float in [1.0, 2.01, 3.0]:
		var view := dinner_view(root, failures)
		view.director.tick(view.camera, time)
		var position: Vector3 = view.room.performance.xu.position
		view._advance()
		view.director.tick(view.camera, 0.016)
		check(view.room.performance.xu.position.distance_to(position) < 0.1, "normal advance preserves serving motion at " + str(time), failures)
		view.free()
	var view := dinner_view(root, failures)
	view.director.tick(view.camera, 1.0)
	var saved: Dictionary = view.session.save_data()
	var live: RefCounted = view.session
	view.voice_button.pressed.emit()
	view.motion_button.pressed.emit()
	var memory: RefCounted = view.presentation
	view.hide()
	view.free()
	var resumed := F.View.new()
	resumed.session = live
	resumed.presentation = memory
	root.add_child(resumed)
	resumed.set_process(false)
	resumed.set_physics_process(false)
	check(not resumed.director.enabled and resumed.voice.muted, "notebook roundtrip preserves camera and voice preferences", failures)
	var loaded: RefCounted = live.restore_save(saved)
	check(memory.progress_key != memory.key(loaded), "loaded session does not inherit a live beat", failures)
	resumed.free()
	view = dinner_view(root, failures)
	view.director.tick(view.camera, 1.0)
	live = view.session
	memory = view.presentation
	var position: Vector3 = view.room.performance.xu.position
	view.voice_button.pressed.emit()
	view.hide()
	view.free()
	resumed = F.View.new()
	resumed.presentation = memory
	resumed.session = live
	root.add_child(resumed)
	resumed.set_process(false)
	resumed.set_physics_process(false)
	await root.get_tree().process_frame
	await root.get_tree().process_frame
	check(resumed.voice.muted and not resumed.voice.output.playing, "reentry preserves voice mute without autoplay", failures)
	check(is_equal_approx(resumed.room.performance.serving_elapsed, 1.0) and resumed.room.performance.xu.position.distance_to(position) < 0.01, "reentry resumes serving instead of repeating it", failures)
	resumed.voice_button.pressed.emit()
	resumed.hide()
	resumed.free()
	resumed = F.View.new()
	resumed.presentation = memory
	resumed.session = live
	root.add_child(resumed)
	resumed.set_process(false)
	resumed.set_physics_process(false)
	await root.get_tree().process_frame
	await root.get_tree().process_frame
	check(not resumed.voice.muted and not resumed.voice.output.playing and resumed.voice.can_replay(), "unmuted reentry waits for explicit replay", failures)
	resumed._replay_voice()
	await root.get_tree().process_frame
	await root.get_tree().process_frame
	check(resumed.voice.output.playing, "explicit replay still works after reentry", failures)
	resumed.free()

func review_platform(root: Window, failures: Array[String]) -> void:
	for safe: bool in [false, true]:
		var view := F.View.new()
		view.session = F.fresh()
		root.add_child(view)
		view.set_process(false)
		view.set_physics_process(false)
		F.drain(view)
		for action: StringName in [&"admission", &"equipment", &"report", &"patrol", &"diagram", &"match_cabinet", &"ask_audio", &"respect", &"next", &"revisit"]:
			F.step(view, action, failures)
		if safe:
			for action: StringName in [&"connect_light", &"boarding", &"lower_ladder"]:
				F.step(view, action, failures)
		F.approach(view, &"confirm_platform")
		view._act(&"confirm_platform")
		view._advance()
		var saved: Dictionary = view.session.save_data()
		view.input_guard = 0
		view._continue()
		check(view.session.save_data() == saved and view.room.performance.sister.visible, "continue reveals key beat without consuming story", failures)
		check(view.room.performance.sister.position.x < -3 if safe else view.room.performance.sister.rotation.z < -0.15, "safe landing or loss of footing is visible", failures)
		view._continue()
		check(view.session.save_data() == saved, "rapid continue cannot eat revealed beat", failures)
		view._process(0.5)
		view._continue()
		check(view.zone_label.text.begins_with("现在") and view._visual.scale == Vector3.ONE, "next deliberate continue returns to present", failures)
		view.free()
		for camera_off: bool in [false, true]:
			var direct := F.View.new()
			direct.session = F.fresh().restore_save(saved)
			root.add_child(direct)
			direct.set_process(false)
			direct.set_physics_process(false)
			if camera_off:
				direct.motion_button.pressed.emit()
				direct._continue()
			else:
				direct.skip_button.pressed.emit()
			check(direct.zone_label.text.begins_with("现在") and not direct.session.view()["facts"].has(&"sister_fate"), "explicit skip and camera off preserve textual result without fate", failures)
			direct.free()
