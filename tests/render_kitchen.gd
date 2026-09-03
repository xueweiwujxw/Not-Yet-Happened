extends SceneTree
## Run with a real OpenGL display (CI uses Xvfb + Mesa), never --headless.

const Main := preload("res://scenes/main.tscn")


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("Kitchen capture requires a rendering display, not the dummy headless driver")
		quit(1)
		return
	root.size = Vector2i(1600, 1000)
	var main := Main.instantiate()
	root.add_child(main)
	_drain(main.session)
	for action: StringName in [&"switch", &"repair", &"switch", &"photo"]:
		main.session.act(action)
		_drain(main.session)
	main.kitchen_button.pressed.emit()
	var view: Control = main.kitchen_view
	view.set_physics_process(false)
	for shot: String in ["kitchen-overview", "kitchen-detail", "kitchen-gameplay", "kitchen-gameplay-default"]:
		var gameplay := shot.begins_with("kitchen-gameplay")
		var expected := Vector2i(1280, 720) if shot.ends_with("default") else Vector2i(1600, 1000)
		root.size = expected
		view.frame_camera(shot == "kitchen-detail", gameplay)
		view.hud.visible = gameplay
		if gameplay:
			view.player.position = Vector3(3.0, 0.1, 1.6)
			view._act(&"photo")
			view.refresh()
		for frame: int in range(5):
			await process_frame
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		if image.is_empty() or image.get_size() != expected:
			printerr("Invalid kitchen screenshot size")
			quit(1)
			return
		DirAccess.make_dir_recursive_absolute("res://build/previews")
		if image.save_png("res://build/previews/" + shot + ".png") != OK:
			quit(1)
			return
		print("Captured ", shot, " at ", image.get_size())
	main.free()
	quit(0)


func _drain(session: RefCounted) -> void:
	while session.speaking():
		session.advance()
