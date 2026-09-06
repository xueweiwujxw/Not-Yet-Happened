extends SceneTree

const Main := preload("res://scenes/main.tscn")
const Fixture := preload("res://tests/test_keeper_view.gd")


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("Keeper capture needs a real rendering display")
		quit(1)
		return
	root.size = Vector2i(1280, 720)
	var host := Main.instantiate()
	host.session = Fixture.First.new().restore_save(Fixture.session().save_data()["prologue"])
	root.add_child(host)
	host._enter_second()
	var main: Control = host.second_screen
	main.kitchen_button.pressed.emit()
	var view: Control = main.kitchen_view
	view.set_physics_process(false)
	Fixture.drain(main.session)
	for shot: String in ["keeper-present", "keeper-outage", "keeper-observed"]:
		if shot == "keeper-outage":
			for action: StringName in [&"telephone", &"tape", &"enter", &"call", &"listen"]:
				main.session.act(action)
				Fixture.drain(main.session)
		elif shot == "keeper-observed":
			main.session.act(&"open")
			Fixture.drain(main.session)
		view.player.position = Vector3(2, 0.1, -1.4)
		view.refresh()
		for frame: int in range(5):
			await process_frame
		await RenderingServer.frame_post_draw
		var img := root.get_texture().get_image()
		DirAccess.make_dir_recursive_absolute("res://build/previews")
		if img.is_empty() or img.get_size() != Vector2i(1280, 720) or img.save_png("res://build/previews/" + shot + ".png") != OK:
			quit(1)
			return
	host.free()
	await create_timer(0.1).timeout
	quit(0)
