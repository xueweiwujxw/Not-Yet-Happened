extends RefCounted

const Motion := preload("res://src/game/character_motion.gd")
const Voice := preload("res://src/art/dialogue_voice.gd")
const Art := preload("res://src/art/low_poly.gd")
const Animator := preload("res://src/art/person_animator.gd")
const Fixture := preload("res://tests/test_finale_view.gd")


func run(root: Window) -> Array[String]:
	var failures: Array[String] = []
	_review_blocking(root, failures)
	await _review_staging(root, failures)
	await _review_dialogue_layout(root, failures)
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
	await root.get_tree().process_frame
	await root.get_tree().process_frame
	check(voice.output.playing, "valid take starts with line", failures)
	var playback: AudioStream = voice.output.stream
	voice.present("test line", true)
	check(voice.output.stream == playback, "refresh does not replace same take", failures)
	playback = null
	# Let the audio mixer consume the started test take before testing interruption.
	await root.get_tree().create_timer(0.05).timeout
	voice.present("next line", true)
	check(not voice.output.playing and voice.output.stream == null, "advancing stops previous take even if next is absent", failures)
	voice.clips[key] = "res://assets/voice/../../secrets.ogg"
	voice.present("test line", true)
	check(voice.output.stream == null, "out-of-folder take rejected", failures)
	voice.set_muted(true)
	voice.stop()
	voice.set_muted(false)
	voice.clips[key] = "res://assets/voice/missing.ogg"
	voice.present("test line", true)
	voice.present("skipped", true)
	await root.get_tree().process_frame
	await root.get_tree().process_frame
	check(not voice.output.playing, "same-frame skip cancels queued playback", failures)
	voice.free()
	var view := Fixture.View.new()
	view.session = Fixture.fresh()
	root.add_child(view)
	view.set_physics_process(false)
	view.set_process(false)
	var third := preload("res://src/content/chapter_three.gd")
	var voiced: Array = third.OPENING + third.LINES[&"ask_audio"] + [third.LINES[&"respect"][0]]
	for line: String in voiced:
		var take: AudioStream = view.voice._resolve_stream(view.voice.clips.get(Voice.key_for(line), ""))
		check(take != null and take.get_length() > 1.0, "bundled opening voice decodes without editor import", failures)
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


func _review_blocking(root: Window, failures: Array[String]) -> void:
	var stage := Node3D.new()
	root.add_child(stage)
	var avatar := Node3D.new()
	stage.add_child(avatar)
	var room := Node3D.new()
	stage.add_child(room)
	var bystander := Art.person(room, Vector3(0.2, 0, 0), "aabbcc")
	var shiori := Art.person(room, Vector3(4, 0, 0), "aabbcc")
	shiori.set_meta("actor_id", &"shiori")
	var camera := Camera3D.new()
	stage.add_child(camera)
	var director := preload("res://src/art/scene_director.gd").new()
	var refusal: String = preload("res://src/content/chapter_three.gd").LINES[&"ask_audio"][0]
	director.stage(room, avatar, true, refusal)
	check(director.actor == shiori, "authored actor wins over nearer bystander", failures)
	director.tick(camera, 0.4)
	check(shiori.rotation.y == 0, "refusal holds before turning away", failures)
	director.stage(room, avatar, true, refusal)
	check(is_equal_approx(director.elapsed, 0.4), "same-line refresh preserves beat time", failures)
	for i: int in range(600):
		director.tick(camera, 1.0 / 60.0)
	var direction := avatar.global_position - shiori.global_position
	check(absf(angle_difference(shiori.rotation.y, atan2(direction.x, direction.z) - 1.1)) < 0.01, "refusal turns away from listener after stepping back", failures)
	check(bystander.rotation.y == 0, "bystander does not perform another character's beat", failures)
	var respect: String = preload("res://src/content/chapter_three.gd").LINES[&"respect"][0]
	director.stage(room, avatar, true, respect)
	check(director.elapsed == 0, "new line resets beat time", failures)
	check(director.expression_time > 10, "new line does not restart blink clock", failures)
	for i: int in range(360):
		director.tick(camera, 1.0 / 60.0)
	check(absf(angle_difference(shiori.rotation.y, -PI / 2)) < 0.01, "respect restores eye contact", failures)
	shiori.hide()
	director.stage(room, avatar, true, refusal)
	check(director.actor == null and not shiori.visible, "hidden authored actor is not replaced or revealed", failures)
	shiori.show()
	director.stage(room, avatar, true, refusal)
	director.enabled = false
	var heading := shiori.rotation.y
	director.tick(camera, 2.0)
	check(shiori.rotation.y == heading, "camera opt-out also disables authored turns", failures)
	check(is_equal_approx(shiori.get_node("EyeLeft").scale.y, 0.045) and shiori.get_node("Mouth").scale == Vector3.ONE, "camera opt-out restores neutral face", failures)
	director.stage(room, avatar, false, "")
	check(director._cue.is_empty(), "leaving dialogue clears authored cue", failures)
	director.stage(room, avatar, true, "An unauthored line")
	check(director.actor == bystander, "ordinary dialogue retains proximity fallback", failures)
	room.rotation.y = 0.4
	director.enabled = true
	director.stage(room, avatar, true, respect)
	for i: int in range(120):
		director.tick(camera, 1.0 / 60.0)
	var facing: Vector3 = shiori.global_basis.z
	var toward: Vector3 = (avatar.global_position - shiori.global_position).normalized()
	check(facing.dot(toward) > 0.999, "actor facing respects transformed room", failures)
	room.free()
	room = Node3D.new()
	stage.add_child(room)
	director.stage(room, avatar, true, refusal)
	check(director.actor == null and director.elapsed == 0, "room replacement discards old actors and timing", failures)
	stage.free()


func _review_staging(root: Window, failures: Array[String]) -> void:
	var stage := Node3D.new()
	root.add_child(stage)
	var player := Node3D.new()
	stage.add_child(player)
	player.position = Vector3(10, 0, 10)
	var actor := Art.person(stage, Vector3.ZERO, "aabbcc")
	var driver := preload("res://src/art/actor_staging.gd").new()
	driver.bind(stage)
	var cue := {"step": Vector3(0, 0, 1), "gesture": -0.3}
	for fps: int in [30, 60, 120]:
		actor.position = Vector3.ZERO
		for i: int in range(fps * 6):
			driver.tick(actor, cue, 1, true, player, 1.0 / fps)
		check(absf(actor.position.z - 1) < 0.01, "staged step reaches mark at each frame rate", failures)
	var before := actor.position
	driver.tick(null, {}, 0, false, player, 1.0 / 60.0)
	check(actor.position.distance_to(before) < 0.02, "skip cancels step without teleporting home", failures)
	for i: int in range(360):
		driver.tick(null, {}, 0, false, player, 1.0 / 60.0)
	check(absf(actor.position.z) < 0.01 and absf(actor.get_node("ArmRight").rotation.z) < 0.01, "cancel settles position and gesture", failures)
	actor.hide()
	before = actor.position
	driver.tick(actor, cue, 1, true, player, 1)
	check(actor.position == before and not actor.visible, "staging never moves or reveals hidden actor", failures)
	actor.show()
	player.position = Vector3(0, 0, 0.9)
	for i: int in range(180):
		driver.tick(actor, cue, 1, true, player, 1.0 / 60.0)
	check(actor.position.z <= 0.151, "staged actor leaves clearance around player", failures)
	player.position = Vector3(10, 0, 10)
	actor.position = Vector3.ZERO
	Art.box(stage, Vector3(0, 0.8, 0.5), Vector3(2, 1.5, 0.2), Art.material("aabbcc"), true)
	await root.get_tree().physics_frame
	await root.get_tree().physics_frame
	for i: int in range(180):
		driver.tick(actor, cue, 1, true, player, 1.0 / 60.0)
	check(actor.position.z < 0.2, "staged step stops before solid scenery", failures)
	stage.free()


func _review_dialogue_layout(root: Window, failures: Array[String]) -> void:
	var original_size := root.size
	root.size = Vector2i(1280, 720)
	var view := Fixture.View.new()
	view.session = Fixture.fresh()
	root.add_child(view)
	view.set_process(false)
	view.set_physics_process(false)
	view.voice.set_muted(true)
	view.story_label.text = preload("res://src/content/chapter_three.gd").LINES[&"respect"][0]
	await root.get_tree().process_frame
	await root.get_tree().process_frame
	var panel: Control = view.story_label.get_parent().get_parent()
	check(panel.get_global_rect().end.y <= root.size.y - 21, "three-line dialogue preserves bottom margin", failures)
	view.free()
	root.size = original_size
	await root.get_tree().create_timer(0.1).timeout
