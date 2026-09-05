extends RefCounted

const Scene := preload("res://scenes/main.tscn")
const Spatial := preload("res://src/game/kitchen_interactions.gd")
const Controls := preload("res://src/game/kitchen_controls.gd")
const Animator := preload("res://src/art/person_animator.gd")
const Sound := preload("res://src/art/kitchen_audio.gd")
const Session := preload("res://src/game/chapter_session.gd")


func run(root: Window) -> Array[String]:
	var failures: Array[String] = []
	var first := Session.new()
	_expect(Spatial.nearby(Vector3.ZERO, first).is_empty(), "dialogue locks spatial actions", failures)
	_drain(first)
	_expect(Spatial.nearby(Vector3(20, 0, 20), first).is_empty(), "remote interaction rejected", failures)
	_expect(Spatial.constrain(Vector3(100, 1, -100)) == Vector3(4.55, 1, -3.4), "open diorama edge remains bounded", failures)
	_expect(Controls.movement(Vector2.RIGHT, Vector2(0.1, 0.0)) == Vector2.RIGHT, "stick drift stays below deadzone", failures)
	_expect(is_equal_approx(Controls.movement(Vector2.RIGHT, Vector2.DOWN).length(), 1.0), "combined input is normalized", failures)
	var screen := Scene.instantiate()
	root.add_child(screen)
	screen.kitchen_button.pressed.emit()
	var view: Control = screen.kitchen_view
	view.set_physics_process(false)
	_expect(view.session == screen.session, "3D and text use the same session", failures)
	_expect(not view.room.shiori.visible and not view.room.letter.visible, "NPCs and letter hidden before arrival", failures)
	var initial: Dictionary = screen.session.save_data()
	var wave := Sound.synthesize(true)
	_expect(wave.data == Sound.synthesize(true).data, "audio synthesis is deterministic", failures)
	_expect(wave.data.size() == Sound.RATE * 8 and wave.loop_end == Sound.RATE * 4, "ambience has valid PCM loop bounds", failures)
	_expect(wave.data.decode_s16(0) == 0 and wave.data.decode_s16(wave.data.size() - 2) == 0, "loop endpoints avoid clicks", failures)
	view.mute_button.pressed.emit()
	_expect(view.sound.muted and view.sound.ambience.stream_paused, "mute pauses local audio only", failures)
	view.sound.cue()
	_expect(not view.sound.effects.playing, "muted effects do not start", failures)
	for i: int in range(4):
		view.sound.travel(0.2, true)
	_expect(view.sound.steps == 1, "footsteps follow distance", failures)
	view.sound.travel(0.0, true)
	view.sound.travel(0.2, false)
	_expect(view.sound.distance == 0.0, "idle and airborne motion reset footsteps", failures)
	view.mute_button.pressed.emit()
	_expect(not view.sound.muted and not view.sound.effects.playing, "unmute does not replay old effects", failures)
	_expect(screen.session.save_data() == initial, "audio cannot alter story or save data", failures)
	view.frame_camera(true)
	_expect(screen.session.save_data() == initial, "camera is not an observation", failures)
	view._act(&"photo")
	_expect(screen.session.save_data() == initial, "cannot interact during dialogue", failures)
	_drain(screen.session)
	view.refresh()
	view.player.position = Vector3(3.0, 0.1, 1.6)
	view._refresh_zone(true)
	_expect(view._marker.visible and is_equal_approx(view._marker.position.x, 3.95), "nearby action projects a world marker", failures)
	var gamepad_action := InputEventJoypadButton.new()
	gamepad_action.button_index = JOY_BUTTON_A
	gamepad_action.pressed = true
	view._input(gamepad_action)
	_expect(screen.session.speaking(), "nearby photo interaction reaches existing dialogue", failures)
	_expect(not view._marker.visible, "dialogue hides unavailable interaction marker", failures)
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
	Animator.apply(view._visual, PI / 2.0, true)
	_expect(view._visual.get_node("ArmLeft").rotation.x > 0.5 and view._visual.get_node("ArmRight").rotation.x < -0.5, "walk pose swings named limbs", failures)
	Animator.apply(view._visual, 0.0, false)
	_expect(view._visual.get_node("ArmLeft").rotation.x == 0.0 and view._visual.position.y == 0.0, "idle pose restores rest state", failures)
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
	# Reopen the same session to exercise the equivalent gamepad path.
	screen.kitchen_button.pressed.emit()
	view = screen.kitchen_view
	view.set_physics_process(false)
	view.back_button.grab_focus()
	var gamepad_back := InputEventJoypadButton.new()
	gamepad_back.button_index = JOY_BUTTON_B
	gamepad_back.pressed = true
	root.push_input(gamepad_back)
	await root.get_tree().process_frame
	_expect(screen.kitchen_view == null and screen.chapter_scroll.visible, "gamepad B returns even with a focused GUI button", failures)
	screen.free()
	# AudioServer retires stopped playback on its next mix tick, not the scene free call.
	await root.get_tree().create_timer(0.1).timeout
	return failures


func _drain(session: RefCounted) -> void:
	for count: int in range(100):
		if not session.speaking() or not session.advance():
			return


func _expect(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append("Kitchen 3D: " + message)
