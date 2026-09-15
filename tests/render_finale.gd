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
		var observation: StringName = &"leave_blank" if ending == "blank" else &"confirm_platform"
		Fixture.approach(view, observation)
		view._act(observation)
		if ending in ["kitchen", "name"]:
			view._advance()
			view.set_process(false)
			view.director.tick(view.camera, 2.8 if ending == "kitchen" else 1.0)
			await shot(view, "platform-safe" if ending == "kitchen" else "platform-slip")
			if ending == "name":
				view.director.tick(view.camera, 2.0)
				await shot(view, "platform-obscured")
			view.set_process(true)
		Fixture.drain(view)
		Fixture.step(view, &"next", failures)
		if ending == "kitchen":
			await shot(view, "evening-store")
		Fixture.step(view, &"records", failures)
		Fixture.step(view, &"seal" if ending == "blank" else &"verify", failures)
		if ending in ["kitchen", "distance"]:
			Fixture.step(view, &"invite" if ending == "kitchen" else &"no_invite", failures)
		if ending == "kitchen":
			Fixture.approach(view, &"dinner")
			view._act(&"dinner")
			view.set_process(false)
			view.director.tick(view.camera, 1.5)
			await shot(view, "dinner-serving")
			view.director.tick(view.camera, 4.5)
			await shot(view, "dinner-seated")
			view._advance()
			view.director.tick(view.camera, 7.5)
			await shot(view, "dinner-conversation")
			view.set_process(true)
			Fixture.drain(view)
		else:
			Fixture.step(view, &"dinner", failures)
		Fixture.step(view, &"correction", failures)
		Fixture.step(view, &"next", failures)
		Fixture.step(view, &"memorial", failures)
		Fixture.approach(view, &"portrait_join")
		if ending in ["kitchen", "distance"]:
			await shot(view, "station-" + ending)
		if ending == "kitchen":
			view._act(&"portrait_join")
			# Hold an authored instant so slow software-render frames cannot outlive the lamp.
			view.set_process(false)
			view.director.props.tick(0.6, true)
			await shot(view, "camera-timer")
			view.set_process(true)
			Fixture.drain(view)
		else:
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
	if label == "camera-timer" and not view.room.timer_lamp.visible:
		failures.append("Portrait timer must be visible in its capture")
	if label.begins_with("dinner-"):
		var meal: Node3D = view.room.performance
		if not meal.bowl.is_visible_in_tree() or view.room.dining_corner.visible:
			failures.append("Staged meal must replace the exploration corner")
		var frame := Rect2(Vector2.ZERO, Vector2(root.size))
		for person: Node3D in [meal.xu, meal.shiori, meal.lin]:
			for height: float in [0.0, 1.8]:
				if not frame.has_point(view.camera.unproject_position(person.global_position + Vector3.UP * height)):
					failures.append("Dinner actor clipped: " + label)
	if view.shown_chapter == 4 and view.room.lighthouse_roof.is_visible_in_tree():
		var top: Vector2 = view.camera.unproject_position(view.room.lighthouse_roof.global_position + Vector3(0, 0.15, 0))
		if not Rect2(Vector2.ZERO, Vector2(root.size)).has_point(top):
			failures.append("Lighthouse silhouette clipped: " + label)
	if label.begins_with("platform-"):
		var tableau: Node3D = view.room.performance
		if not tableau.is_visible_in_tree() or view.room.lighthouse_roof.is_visible_in_tree():
			failures.append("Observation shot must replace exploration: " + label)
		var frame := Rect2(Vector2.ZERO, Vector2(root.size))
		for point: Vector3 in [Vector3(-3.8, 0.9, -1.6), Vector3(2.5, 0.9, 0.4)]:
			if not frame.has_point(view.camera.unproject_position(tableau.to_global(point))):
				failures.append("Observed platform clipped: " + label)
		if tableau.sister.is_visible_in_tree():
			for height: float in [0.0, 1.8]:
				if not frame.has_point(view.camera.unproject_position(tableau.sister.global_position + Vector3.UP * height)):
					failures.append("Observed sister clipped: " + label)
		elif label != "platform-obscured":
			failures.append("Witnessed sister missing: " + label)
	# Catch dialogue/button overflow on the actual rendered layout, not just PNG existence.
	for control: Control in [view.story_label, view.zone_label, view.next_button, view.replay_button]:
		if control.visible and not Rect2(Vector2.ZERO, Vector2(root.size)).encloses(control.get_global_rect()):
			failures.append("Finale layout overflow: " + label)
	for button: Button in view.action_buttons.values():
		if not Rect2(Vector2.ZERO, Vector2(root.size)).encloses(button.get_global_rect()):
			failures.append("Finale action overflow: " + label)
	var img := root.get_texture().get_image()
	DirAccess.make_dir_recursive_absolute("res://build/previews")
	if img.is_empty() or img.get_size() != Vector2i(1280, 720) or img.save_png("res://build/previews/finale-" + label + ".png") != OK:
		failures.append("Finale screenshot failed: " + label)
