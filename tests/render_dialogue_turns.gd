extends SceneTree

const Entry := preload("res://scenes/game.tscn")
const First := preload("res://src/content/chapter_one.gd")
const Fixture := preload("res://tests/test_finale_view.gd")


func _initialize() -> void:
	call_deferred("capture")


func capture() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("Dialogue capture requires a rendering display")
		quit(1)
		return
	root.size = Vector2i(1280, 720)
	var game := Entry.instantiate()
	root.add_child(game)
	var view: Control = game.kitchen_view
	view.set_physics_process(false)
	view.voice.set_muted(true)
	Fixture.drain(view)
	view.player.position = Vector3(3.95, 0.1, 1.6)
	view._act(&"photo")
	for i: int in range(30):
		if view.session.view()["line"] == First.ARRIVAL[1]:
			break
		view._advance()
	if view.session.view()["line"] != First.ARRIVAL[1]:
		printerr("Missing arrival fixture")
		quit(1)
		return
	for i: int in range(3):
		for frame: int in range(8):
			await process_frame
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		DirAccess.make_dir_recursive_absolute("res://build/previews")
		if image.is_empty() or image.save_png("res://build/previews/dialogue-turn-%d.png" % i) != OK:
			quit(1)
			return
		print("Captured dialogue turn ", i, " / ", view.speaker_label.text)
		view._trigger_primary_action()
	game.free()
	await create_timer(0.2).timeout
	quit(0)
