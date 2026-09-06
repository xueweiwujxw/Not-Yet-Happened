extends SceneTree
## Fixed-frame real-engine reel: opening push-in, player walk/turn, dialogue blocking.

const Main := preload("res://scenes/main.tscn")
const Fixture := preload("res://tests/test_finale_view.gd")


func _initialize() -> void:
	call_deferred("_record")


func _record() -> void:
	if DisplayServer.get_name() == "headless":
		quit(1)
		return
	root.size = Vector2i(1280, 720)
	Engine.physics_ticks_per_second = 30
	var host := Main.instantiate()
	root.add_child(host)
	host._show_second(Fixture.Fixture.new().previous(false))
	host.finale_navigation.enter()
	var screen: Control = host.finale_navigation.screen
	screen.spatial_button.pressed.emit()
	var view: Control = screen.spatial_view
	view.set_physics_process(false)
	for frame: int in range(560):
		await physics_frame
		if frame == 90:
			view._advance()
		if frame == 270:
			Fixture.drain(view)
		if frame >= 280 and frame < 360:
			view.move_player(Vector2(-1, 0), 1.0 / 30.0)
		elif frame >= 360 and frame < 420:
			view.move_player(Vector2(1, -0.3), 1.0 / 30.0)
		else:
			view.move_player(Vector2.ZERO, 1.0 / 30.0)
		view._refresh_zone()
		if frame == 460:
			Fixture.approach(view, &"ask_audio")
			# Admission is a prerequisite; perform it through the existing session and return.
			Fixture.step(view, &"admission", [])
			Fixture.approach(view, &"ask_audio")
			view._act(&"ask_audio")
			view.fade_in()
		if frame in [60, 350, 530]:
			await RenderingServer.frame_post_draw
			var img := root.get_texture().get_image()
			if img.save_png("res://build/previews/cinematic-%d.png" % frame) != OK:
				quit(1)
				return
	host.free()
	await create_timer(0.1).timeout
	quit(0)
