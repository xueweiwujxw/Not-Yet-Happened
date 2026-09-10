extends RefCounted

const Art := preload("res://src/art/low_poly.gd")
const Appearance := preload("res://src/art/character_appearance.gd")
const Animator := preload("res://src/art/person_animator.gd")


func run() -> Array[String]:
	var failures: Array[String] = []
	var stage := Node3D.new()
	for profile: StringName in Appearance.PROFILES:
		var person := Art.person(stage, Vector3(1, 0.1, 2), "d49a70")
		person.hide()
		person.rotation.y = 0.7
		var original := person.transform
		var rest_height: float = person.get_meta("rest_y")
		Appearance.apply(person, profile)
		var details := person.get_node("Appearance")
		_expect(details.get_meta("profile") == profile, "profile applied", failures)
		_expect(person.transform == original and not person.visible, "appearance preserves transform and visibility", failures)
		_expect(person.get_meta("rest_y") == rest_height, "rest height preserved", failures)
		_expect(details.find_children("*", "CollisionObject3D", true, false).is_empty(), "decoration adds no physics bodies", failures)
		var count := person.get_child_count()
		Appearance.apply(person, profile)
		_expect(person.get_child_count() == count and person.get_node("Appearance") == details, "repeat apply does not duplicate geometry", failures)
		Animator.apply(person, PI / 2, true)
		_expect(person.get_node("ArmLeft").rotation.x > 0.5, "decorated rig still walks", failures)
		Appearance.set_present(person, false)
		if profile == &"lin_che":
			_expect(not person.get_node("Appearance/TravelBag").visible, "child hides bag", failures)
		Appearance.set_present(person, true)
		if profile == &"lin_che":
			_expect(person.get_node("Appearance/TravelBag").visible, "present restores bag", failures)
	var unknown := Art.person(stage, Vector3.ZERO, "d49a70")
	Appearance.apply(unknown, &"unknown")
	Appearance.set_present(unknown, false)
	_expect(not unknown.has_node("Appearance"), "unknown profile leaves base rig intact", failures)
	stage.free()
	return failures


func _expect(ok: bool, message: String, failures: Array[String]) -> void:
	if not ok:
		failures.append("Character appearance: " + message)
