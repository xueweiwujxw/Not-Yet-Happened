extends RefCounted

const Art := preload("res://src/art/low_poly.gd")
const Appearance := preload("res://src/art/character_appearance.gd")
const FacePose := preload("res://src/art/character_expression.gd")
const HandProp := preload("res://src/art/hand_prop.gd")


func run(root: Window) -> Array[String]:
	var failures: Array[String] = []
	var stage := Node3D.new()
	var person := Art.person(stage, Vector3.ZERO, "8fa68a")
	Appearance.apply(person, &"xu")
	var eye := person.get_node("EyeLeft") as Node3D
	var mouth := person.get_node("Mouth") as Node3D
	FacePose.apply(person, &"neutral", 3.9, true)
	check(eye.scale.y < 0.01, "blink closes eye", failures)
	FacePose.apply(person, &"neutral", 4.1, true)
	check(is_equal_approx(eye.scale.y, 0.045), "blink reopens eye", failures)
	FacePose.apply(person, &"reserved", 1.0, true)
	check(eye.scale.y < 0.04 and mouth.scale.x < 1, "reserved expression", failures)
	FacePose.apply(person, &"warm", 1.0, true)
	check(mouth.scale.x > 1 and is_equal_approx(eye.scale.y, 0.045), "warm replaces reserved expression", failures)
	FacePose.apply(person, &"reserved", 3.9, false)
	check(mouth.scale == Vector3.ONE and is_equal_approx(eye.scale.y, 0.045), "motion off resets face even during blink", failures)
	var arm := person.get_node("ArmRight") as Node3D
	var bowl := arm.get_node("HeldBowl") as Node3D
	check(not bowl.visible, "bowl begins hidden", failures)
	HandProp.apply(person, true, 0.3)
	check(bowl.visible and arm.rotation.x < 0 and arm.rotation.x > -1.15, "serving raises hand gradually", failures)
	HandProp.apply(person, true, 1.0)
	check(is_equal_approx(arm.rotation.x + bowl.rotation.x, 0), "bowl stays level", failures)
	arm.rotation.z = 0.2
	HandProp.apply(person, true, 1.0)
	check((arm.basis * bowl.basis).is_equal_approx(Basis.IDENTITY), "compound arm rotation keeps bowl level", failures)
	HandProp.apply(person, false, 1.0)
	check(not bowl.visible, "skip hides hand prop", failures)
	person.hide()
	FacePose.apply(person, &"warm", 1.0, true)
	check(not person.visible, "expression cannot reveal actor", failures)
	FacePose.apply(null, &"warm", 1.0, true)
	stage.free()
	var room := preload("res://src/art/evening_store.gd").new()
	root.add_child(room)
	var director := preload("res://src/art/scene_director.gd").new()
	var avatar := Node3D.new()
	root.add_child(avatar)
	var camera := Camera3D.new()
	root.add_child(camera)
	var lines: Array = preload("res://src/content/chapter_five.gd").LINES[&"dinner"]
	director.stage(room, avatar, true, lines[0])
	director.tick(camera, 1.2)
	var held: Node3D = room.find_children("HeldBowl", "Node3D", true, false)[0]
	check(held.visible, "authored dinner selects serving actor", failures)
	director.enabled = false
	director.tick(camera, 0.1)
	check(not held.visible, "motion off clears serving prop", failures)
	director.enabled = true
	director.stage(room, avatar, true, lines[1])
	director.tick(camera, 1.2)
	check(not held.visible, "next dinner block does not repeat serving", failures)
	room.free()
	avatar.free()
	camera.free()
	return failures


func check(ok: bool, message: String, failures: Array[String]) -> void:
	if not ok:
		failures.append("Character performance: " + message)
