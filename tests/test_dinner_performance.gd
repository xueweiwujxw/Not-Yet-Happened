extends RefCounted

const Fixture := preload("res://tests/test_finale_view.gd")
const Dinner := preload("res://src/art/dinner_performance.gd")


func run(root: Window) -> Array[String]:
	var failures: Array[String] = []
	for respected: bool in [true, false]:
		var view := Fixture.View.new()
		view.session = Fixture.fresh()
		root.add_child(view)
		view.set_process(false)
		view.set_physics_process(false)
		Fixture.drain(view)
		for action: StringName in [&"admission", &"equipment", &"report", &"patrol", &"diagram", &"match_cabinet", &"ask_audio"]:
			Fixture.step(view, action, failures)
		Fixture.step(view, &"respect" if respected else &"play_anyway", failures)
		for action: StringName in [&"next", &"revisit", &"leave_blank", &"next"]:
			Fixture.step(view, action, failures)
		var meal: Node3D = view.room.performance
		view.director.tick(view.camera, 0.1)
		check(not meal.visible and view.room.dining_corner.visible, "exploration keeps original corner", failures)
		Fixture.approach(view, &"dinner")
		view._act(&"dinner")
		var before: Dictionary = view.session.save_data()
		var facts: Dictionary = view.session.view()["facts"]
		view.director.tick(view.camera, 0.8)
		check(meal.visible and not view.room.dining_corner.visible and not view._visual.visible, "meal replaces only exploration diners and avatar", failures)
		check(meal.shiori.is_visible_in_tree(), "authored family conversation includes Shiori in both boundary routes", failures)
		check(not meal.bowl.position.is_equal_approx(Dinner.BOWL_PLACE), "bowl begins in serving hand", failures)
		view.refresh()
		check(is_equal_approx(meal.elapsed, 0.8), "refresh preserves serving time", failures)
		for i: int in range(12):
			view.director.tick(view.camera, 0.1)
			if meal.bowl.position.z + 0.18 > -0.1:
				check(meal.bowl.position.y - 0.06 >= 0.844, "vessel clears the tabletop throughout placement", failures)
		check(meal.bowl.position.is_equal_approx(Dinner.BOWL_PLACE), "bowl reaches table", failures)
		check(meal.bowl.basis.is_equal_approx(Basis.IDENTITY), "serving bowl stays level", failures)
		view.director.tick(view.camera, 4.0)
		check(meal.xu.position.is_equal_approx(Vector3(0, -0.2, -0.9)), "Xu returns to her stool", failures)
		var hip := meal.shiori.get_node("LegLeft") as Node3D
		var knee := hip.get_node("Knee") as Node3D
		check(is_equal_approx(hip.rotation.x, -PI / 2) and is_equal_approx(knee.rotation.x, PI / 2), "seated knees keep lower legs vertical", failures)
		check(view.session.save_data() == before and view.session.view()["facts"] == facts, "completed performance leaves all facts and events untouched", failures)
		view.director.enabled = false
		view.director.tick(view.camera, 0.1)
		check(not meal.visible and view.room.dining_corner.visible and view._visual.visible, "camera off restores exploration", failures)
		view.director.enabled = true
		view.director.tick(view.camera, 0.1)
		check(meal.visible and meal.bowl.position == Dinner.BOWL_PLACE, "reenabling does not restart transfer", failures)
		view._advance()
		view.director.tick(view.camera, 0.1)
		check(meal.bowl.position == Dinner.BOWL_PLACE and meal.xu.position.y < 0, "next line starts after completed serving even when skipped", failures)
		before = view.session.save_data()
		var restored := Fixture.View.new()
		restored.session = view.session.restore_save(before)
		root.add_child(restored)
		restored.set_process(false)
		restored.set_physics_process(false)
		restored.director.tick(restored.camera, 0.1)
		check(restored.room.performance.bowl.position == Dinner.BOWL_PLACE and restored.session.save_data() == before, "load restores conversation without serving twice", failures)
		restored.free()
		view._advance()
		view.director.tick(view.camera, 1.0)
		check(meal.xu.rotation.x > 0, "last block includes a restrained nod", failures)
		Fixture.drain(view)
		check(not meal.visible and view.room.dining_corner.visible, "dialogue completion immediately restores corner", failures)
		view.director.tick(view.camera, 0.1)
		check(view._visual.visible, "exploration avatar returns", failures)
		view.free()
	await root.get_tree().create_timer(0.1).timeout
	return failures


func check(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append("Dinner performance: " + message)
