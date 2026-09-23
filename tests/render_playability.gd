extends SceneTree
## Capture the shipping entry and its input affordances, not an alternate mockup.

const Entry := preload("res://scenes/game.tscn")
const Fixture := preload("res://tests/test_finale_view.gd")


func _initialize() -> void:
	call_deferred("capture")


func capture() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("Playability capture requires a rendering display")
		quit(1)
		return
	root.size = Vector2i(1280, 720)
	var game := Entry.instantiate()
	root.add_child(game)
	game.kitchen_view.set_physics_process(false)
	await shot("entry")
	Fixture.drain(game.kitchen_view)
	await shot("exploration")
	var view: Control = game.kitchen_view
	view.player.position = Vector3(3.95, 0.1, 1.6)
	view.refresh()
	view._trigger_primary_action()
	Fixture.drain(view)
	view.player.position = Vector3(2.3, 0.1, -1.45)
	view.refresh()
	view._cycle_choice(1)
	view._cycle_choice(1)
	await shot("choices")
	game._hide_kitchen()
	game._show_second(preload("res://tests/test_finale_session.gd").new().previous().new_attempt())
	view = game.second_screen.kitchen_view
	view.set_physics_process(false)
	Fixture.drain(view)
	for action: StringName in [&"telephone", &"tape", &"enter"]:
		view.session.act(action)
		Fixture.drain(view)
	view.player.position = Vector3(2.5, 0.1, -1.6)
	view.refresh()
	view._act(&"listen")
	await shot("consequence")
	game.free()
	await create_timer(0.2).timeout
	quit(0)


func shot(id: String) -> void:
	for frame: int in range(8):
		await process_frame
	await RenderingServer.frame_post_draw
	var screenshot := root.get_texture().get_image()
	DirAccess.make_dir_recursive_absolute("res://build/previews")
	if screenshot.is_empty() or screenshot.save_png("res://build/previews/playability-" + id + ".png") != OK:
		printerr("Failed to capture " + id)
		quit(1)
	print("Captured playability-", id)
