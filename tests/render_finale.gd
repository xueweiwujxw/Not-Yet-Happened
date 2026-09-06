extends SceneTree
## Real rendering of legally played scenes, including pending evidence and all four endings.

const Main := preload("res://scenes/main.tscn")
const Fixture := preload("res://tests/test_finale_view.gd")
var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("Finale capture needs a real rendering display")
		quit(1)
		return
	root.size = Vector2i(1280, 720)
	for ending: String in ["kitchen", "distance", "name", "blank"]:
		var host := Main.instantiate()
		root.add_child(host)
		host._show_second(Fixture.Fixture.new().previous(false))
		host.finale_navigation.enter()
		var screen: Control = host.finale_navigation.screen
		screen.spatial_button.pressed.emit()
		var view: Control = screen.spatial_view
		view.set_physics_process(false)
		Fixture.drain(view)
		if ending == "kitchen":
			await shot(view, "studio")
		for action: StringName in [&"admission", &"equipment", &"report", &"patrol", &"diagram", &"match_cabinet", &"ask_audio"]:
			Fixture.step(view, action, failures)
		Fixture.step(view, &"play_anyway" if ending == "distance" else &"respect", failures)
		Fixture.step(view, &"next", failures)
		Fixture.step(view, &"revisit", failures)
		if ending == "kitchen":
			Fixture.approach(view, &"confirm_platform")
			await shot(view, "pier-warning")
		if ending in ["kitchen", "distance"]:
			Fixture.step(view, &"connect_light", failures)
		Fixture.step(view, &"boarding", failures)
		if ending in ["kitchen", "distance"]:
			Fixture.approach(view, &"lower_ladder")
			view._act(&"lower_ladder")
			if ending == "kitchen":
				await shot(view, "ladder-pending")
			Fixture.drain(view)
			if ending == "kitchen":
				await shot(view, "ladder-lowered")
		Fixture.step(view, &"leave_blank" if ending == "blank" else &"confirm_platform", failures)
		Fixture.step(view, &"next", failures)
		if ending == "kitchen":
			await shot(view, "evening-store")
		Fixture.step(view, &"records", failures)
		Fixture.step(view, &"seal" if ending == "blank" else &"verify", failures)
		if ending in ["kitchen", "distance"]:
			Fixture.step(view, &"invite" if ending == "kitchen" else &"no_invite", failures)
		Fixture.step(view, &"dinner", failures)
		Fixture.step(view, &"correction", failures)
		Fixture.step(view, &"next", failures)
		Fixture.step(view, &"memorial", failures)
		Fixture.approach(view, &"portrait_join")
		if ending in ["kitchen", "distance"]:
			await shot(view, "station-" + ending)
		Fixture.step(view, &"portrait_decline" if ending == "blank" else &"portrait_join", failures)
		Fixture.step(view, &"departure", failures)
		await shot(view, "ending-" + ending)
		host.free()
		await create_timer(0.1).timeout
	for failure: String in failures:
		printerr(failure)
	quit(0 if failures.is_empty() else 1)


func shot(view: Control, label: String) -> void:
	await create_timer(0.8).timeout
	for frame: int in range(5):
		await process_frame
	await RenderingServer.frame_post_draw
	if view.shown_chapter == 4:
		var top: Vector2 = view.camera.unproject_position(view.room.lighthouse_roof.global_position + Vector3(0, 0.15, 0))
		if not Rect2(Vector2.ZERO, Vector2(root.size)).has_point(top):
			failures.append("Lighthouse silhouette clipped: " + label)
	# Catch dialogue/button overflow on the actual rendered layout, not just PNG existence.
	for control: Control in [view.story_label, view.zone_label, view.next_button]:
		if control.visible and not Rect2(Vector2.ZERO, Vector2(root.size)).encloses(control.get_global_rect()):
			failures.append("Finale layout overflow: " + label)
	for button: Button in view.action_buttons.values():
		if not Rect2(Vector2.ZERO, Vector2(root.size)).encloses(button.get_global_rect()):
			failures.append("Finale action overflow: " + label)
	var img := root.get_texture().get_image()
	DirAccess.make_dir_recursive_absolute("res://build/previews")
	if img.is_empty() or img.get_size() != Vector2i(1280, 720) or img.save_png("res://build/previews/finale-" + label + ".png") != OK:
		failures.append("Finale screenshot failed: " + label)
