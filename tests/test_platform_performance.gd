extends RefCounted

const Fixture := preload("res://tests/test_finale_view.gd")


func run(root: Window) -> Array[String]:
	var failures: Array[String] = []
	for outcome: String in ["safe", "fall", "light-only", "ladder-only", "blank"]:
		var view := Fixture.View.new()
		view.session = Fixture.fresh()
		root.add_child(view)
		view.set_process(false)
		view.set_physics_process(false)
		Fixture.drain(view)
		for action: StringName in [&"admission", &"equipment", &"report", &"patrol", &"diagram", &"match_cabinet", &"ask_audio", &"respect", &"next", &"revisit"]:
			Fixture.step(view, action, failures)
		var shot: Node3D = view.room.performance
		view.director.tick(view.camera, 0.1)
		check(not shot.visible, "exploration never reveals the platform", failures)
		if outcome in ["safe", "light-only"]:
			Fixture.step(view, &"connect_light", failures)
		if outcome in ["safe", "ladder-only"]:
			Fixture.step(view, &"boarding", failures)
			Fixture.step(view, &"lower_ladder", failures)
		var action: StringName = &"leave_blank" if outcome == "blank" else &"confirm_platform"
		Fixture.approach(view, action)
		view._act(action)
		var before: Dictionary = view.session.save_data()
		view.director.tick(view.camera, 0.5)
		check(shot.visible == (outcome != "blank"), "only explicit observation enables shot", failures)
		check(not shot.sister.is_visible_in_tree(), "establishing line does not reveal the sister early", failures)
		check(view.session.save_data() == before, "shot never advances pending observation", failures)
		view._advance()
		before = view.session.save_data()
		view.director.tick(view.camera, 0.6)
		if outcome != "blank":
			check(shot.sister.is_visible_in_tree(), "movement line reveals witnessed sister", failures)
			check(shot.lamp.visible == (outcome in ["safe", "light-only"]), "shot preserves lighting preparation", failures)
			check(shot.route.visible == (outcome in ["safe", "ladder-only"]), "shot preserves ladder preparation", failures)
			check(not view._visual.visible, "boat viewpoint hides exploration avatar", failures)
			view.refresh()
			check(is_equal_approx(shot.elapsed, 0.6), "refresh preserves shot time", failures)
			view.director.tick(view.camera, 4.0)
			check(shot.sister.visible == (outcome == "safe"), "fall continuation remains obscured", failures)
			check(shot.spray.visible == (outcome != "safe"), "spray covers unknown aftermath", failures)
			check(not view.session.view()["facts"].has(&"sister_fate"), "neither shot asserts later fate", failures)
			check(view.session.save_data() == before, "animation completion leaves save untouched", failures)
			var restored := Fixture.View.new()
			restored.session = view.session.restore_save(before)
			root.add_child(restored)
			restored.set_process(false)
			restored.set_physics_process(false)
			restored.director.tick(restored.camera, 0.6)
			check(restored.room.performance.visible and restored.room.performance.sister.visible, "loading pending observation restores its shot", failures)
			check(restored.session.save_data() == before, "loading shot adds no story events", failures)
			restored.free()
			view.director.enabled = false
			view.director.tick(view.camera, 0.1)
			check(not shot.visible and view._visual.visible, "camera off restores exploration composition", failures)
			view.director.enabled = true
			view.director.tick(view.camera, 0.1)
			check(shot.visible, "reenabling restores current shot", failures)
			view._advance()
			check(not shot.visible, "present-day line cancels immediately", failures)
		Fixture.drain(view)
		view.director.tick(view.camera, 0.1)
		check(not shot.visible and view._visual.visible, "dialogue end restores scene", failures)
		Fixture.step(view, &"next", failures)
		view.director.tick(view.camera, 0.1)
		check(view._visual.visible, "next chapter retains visible avatar", failures)
		view.free()
	await root.get_tree().create_timer(0.1).timeout
	return failures


func check(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append("Platform performance: " + message)
