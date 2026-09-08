extends RefCounted

const Props := preload("res://src/art/prop_performance.gd")
const Studio := preload("res://src/art/photo_studio.gd")
const Station := preload("res://src/art/farewell_station.gd")
const Three := preload("res://src/content/chapter_three.gd")
const Six := preload("res://src/content/chapter_six.gd")


func run(root: Window) -> Array[String]:
	var failures: Array[String] = []
	var studio := Studio.new()
	root.add_child(studio)
	var props := Props.new()
	var scan := find_prop(studio, &"scanner")
	check(not scan.visible, "scanner starts off", failures)
	props.stage(studio, Three.LINES[&"equipment"][0], true)
	props.tick(0.3, true)
	var first := scan.position.z
	check(scan.visible, "equipment scan shows light", failures)
	props.stage(studio, Three.LINES[&"equipment"][0], true)
	props.tick(0.3, true)
	check(scan.position.z > first and is_equal_approx(props.elapsed, 0.6), "refresh preserves scan travel", failures)
	props.tick(2.0, true)
	check(not scan.visible, "scan completes once without advancing dialogue", failures)
	props.stage(studio, "", false)
	props.stage(studio, Three.LINES[&"equipment"][0], true)
	props.tick(0.1, false)
	check(not scan.visible, "motion opt-out suppresses scan", failures)
	props.tick(0.1, true)
	props.stage(studio, Three.LINES[&"equipment"][1], true)
	check(not scan.visible, "skip cancels immediately before next frame", failures)
	studio.free()
	studio = Studio.new()
	root.add_child(studio)
	props.stage(studio, Three.LINES[&"equipment"][0], true)
	props.tick(0.1, true)
	check(find_prop(studio, &"scanner").visible, "room replacement discards freed prop references", failures)
	studio.free()
	var station := Station.new()
	root.add_child(station)
	var lamp := find_prop(station, &"camera")
	for line: String in [Six.LINES[&"join_together"][0], Six.LINES[&"join_alone"][0]]:
		props.stage(station, line, true)
		props.tick(0.5, true)
		check(lamp.visible, "each chosen photo has a timer cue", failures)
		props.tick(1.5, true)
		check(not lamp.visible, "timer turns off without repeated flashing", failures)
	props.stage(station, Six.LINES[&"decline_together"][0], true)
	props.tick(0.5, true)
	check(not lamp.visible, "declining portrait does not trigger its timer", failures)
	station.free()
	var fixture := preload("res://tests/test_finale_view.gd")
	var view := fixture.View.new()
	view.session = fixture.fresh()
	root.add_child(view)
	view.set_process(false)
	view.set_physics_process(false)
	var before: Dictionary = view.session.save_data()
	view.director.props.stage(view.room, Three.LINES[&"equipment"][0], true)
	view.director.props.tick(3.0, true)
	check(view.session.save_data() == before, "prop completion never commits evidence or advances a line", failures)
	view.free()
	await root.get_tree().create_timer(0.1).timeout
	return failures


func find_prop(room: Node3D, id: StringName) -> Node3D:
	for node: Node in room.find_children("*", "Node3D", true, false):
		if node.get_meta("performance_id", &"") == id:
			return node
	return null


func check(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append("Prop performance: " + message)
