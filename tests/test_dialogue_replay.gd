extends RefCounted

const Voice := preload("res://src/art/dialogue_voice.gd")
const Three := preload("res://src/content/chapter_three.gd")
const Fixture := preload("res://tests/test_finale_view.gd")


func run(root: Window) -> Array[String]:
	var failures: Array[String] = []
	var voice := Voice.new()
	root.add_child(voice)
	check(not voice.replay(), "no active line cannot replay", failures)
	voice.set_muted(true)
	voice.present(Three.OPENING[0], true)
	check(not voice.can_replay() and not voice.replay(), "muted replay rejected", failures)
	voice.set_muted(false)
	await root.get_tree().process_frame
	await root.get_tree().process_frame
	check(not voice.output.playing and voice.can_replay(), "unmute enables explicit replay without autoplay", failures)
	var key: String = voice.current_key
	var stream: AudioStream = voice.output.stream
	check(voice.replay() and voice.replay(), "repeated clicks accepted without replacing stream", failures)
	await root.get_tree().process_frame
	await root.get_tree().process_frame
	check(voice.output.playing and voice.output.stream == stream and voice.current_key == key, "replay preserves current block and uses one player", failures)
	voice.replay()
	voice.present("unvoiced narration", true)
	await root.get_tree().process_frame
	check(not voice.output.playing and not voice.can_replay(), "skipping cancels queued replay", failures)
	voice.present(Three.OPENING[0], true)
	voice.replay()
	voice.set_muted(true)
	await root.get_tree().process_frame
	check(not voice.output.playing, "muting cancels queued replay", failures)
	voice.set_muted(false)
	voice.replay()
	voice.stop()
	await root.get_tree().process_frame
	check(not voice.output.playing and not voice.can_replay(), "stop cancels queued replay", failures)
	voice.present(Three.OPENING[0], true)
	voice.queue_free()
	check(not voice.replay(), "queued deletion rejects replay", failures)
	var view := Fixture.View.new()
	view.session = Fixture.fresh()
	root.add_child(view)
	view.set_process(false)
	view.set_physics_process(false)
	var saved: Dictionary = view.session.save_data()
	view.director.elapsed = 0.7
	var camera_transform: Transform3D = view.camera.transform
	check(view.replay_button.visible and not view.replay_button.disabled, "voiced block exposes replay", failures)
	view.replay_button.pressed.emit()
	check(view.session.save_data() == saved and view.director.elapsed == 0.7 and view.camera.transform == camera_transform, "replay preserves facts, choices and camera timing", failures)
	view.voice_button.pressed.emit()
	check(view.replay_button.disabled, "mute disables replay button", failures)
	view.voice_button.pressed.emit()
	check(not view.replay_button.disabled, "unmute restores replay button", failures)
	view.hide()
	check(not view.replay_button.visible, "hidden view clears stale replay availability", failures)
	view.replay_button.pressed.emit()
	await root.get_tree().process_frame
	check(not view.voice.output.playing, "hidden view cannot queue replay", failures)
	view.show()
	Fixture.drain(view)
	check(not view.replay_button.visible, "end of dialogue hides replay", failures)
	view.free()
	await root.get_tree().create_timer(0.1).timeout
	return failures


func check(ok: bool, message: String, failures: Array[String]) -> void:
	if not ok:
		failures.append("Dialogue replay: " + message)
