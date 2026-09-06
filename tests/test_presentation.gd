extends RefCounted

const Motion := preload("res://src/game/character_motion.gd")
const Voice := preload("res://src/art/dialogue_voice.gd")
const Art := preload("res://src/art/low_poly.gd")
const Animator := preload("res://src/art/person_animator.gd")
const Fixture := preload("res://tests/test_finale_view.gd")


func run(root: Window) -> Array[String]:
	var failures: Array[String] = []
	var speed := Motion.velocity(Vector2.ZERO, Vector2.RIGHT, 1.0 / 60.0, false)
	check(speed.x > 0 and speed.x < Motion.SPEED, "walk accelerates instead of snapping", failures)
	for fps: int in [30, 60, 120]:
		speed = Vector2.ZERO
		for i: int in range(fps):
			speed = Motion.velocity(speed, Vector2.ONE, 1.0 / fps, false)
		check(is_equal_approx(speed.length(), Motion.SPEED), "speed independent of frame rate", failures)
		for i: int in range(fps):
			speed = Motion.velocity(speed, Vector2.ZERO, 1.0 / fps, false)
		check(speed.is_zero_approx(), "release settles to rest", failures)
	check(Motion.velocity(Vector2.ONE, Vector2.ONE, 0.016, true) == Vector2.ZERO, "dialogue stops drift immediately", failures)
	check(absf(Motion.facing(0, Vector2(1, 0), 0.016)) < 0.12, "turn is bounded", failures)
	check(Motion.facing(0.7, Vector2.ZERO, 1) == 0.7, "standing preserves heading", failures)
	var parent := Node3D.new()
	root.add_child(parent)
	var person := Art.person(parent, Vector3.ZERO, "aabbcc")
	Animator.apply(person, PI / 2, true)
	Animator.blend(person, 0, 0, 1.0 / 60.0)
	check(person.get_node("ArmLeft").rotation.x > 0 and person.get_node("ArmLeft").rotation.x < 0.55, "pose eases to rest", failures)
	parent.free()
	var voice := Voice.new()
	root.add_child(voice)
	var key := Voice.key_for("test line")
	voice.clips = {key: "res://assets/voice/missing.ogg"}
	voice.present("test line", true)
	check(voice.current_key == key and not voice.output.playing, "missing take stays silent", failures)
	voice.present("test line", false)
	check(voice.current_key.is_empty(), "end of dialogue clears voice", failures)
	voice.resolve_stream = func(_path: String) -> AudioStream: return preload("res://src/art/kitchen_audio.gd").synthesize(false)
	voice.present("test line", true)
	check(voice.output.playing, "valid take starts with line", failures)
	var playback: AudioStream = voice.output.stream
	voice.present("test line", true)
	check(voice.output.stream == playback, "refresh does not replace same take", failures)
	playback = null
	voice.present("next line", true)
	check(not voice.output.playing and voice.output.stream == null, "advancing stops previous take even if next is absent", failures)
	voice.clips[key] = "res://assets/voice/../../secrets.ogg"
	voice.present("test line", true)
	check(voice.output.stream == null, "out-of-folder take rejected", failures)
	voice.set_muted(true)
	voice.free()
	var view := Fixture.View.new()
	view.session = Fixture.fresh()
	root.add_child(view)
	view.set_physics_process(false)
	view.set_process(false)
	var saved: Dictionary = view.session.save_data()
	var wide: float = view.camera.size
	for i: int in range(120):
		view.director.tick(view.camera, 1.0 / 60.0)
	check(view.camera.size < wide and view.camera.size >= 10.8, "dialogue gently pushes in", failures)
	view.motion_button.pressed.emit()
	for i: int in range(120):
		view.director.tick(view.camera, 1.0 / 60.0)
	check(view.camera.size > 13.0, "camera motion can be disabled", failures)
	check(view.session.save_data() == saved, "camera does not consume dialogue or observations", failures)
	view.hide()
	check(view.voice.current_key.is_empty(), "hidden scene stops voice", failures)
	view.free()
	await root.get_tree().create_timer(0.1).timeout
	return failures


func check(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append("Presentation: " + message)
