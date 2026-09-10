extends RefCounted
## Original, collision-free silhouettes layered over the existing limb rig.

const Art := preload("res://src/art/low_poly.gd")
const PROFILES := [&"lin_che", &"shiori", &"shen", &"xu"]


static func apply(person: Node3D, profile: StringName) -> void:
	if profile not in PROFILES or person.has_node("Appearance"):
		return
	var details := Node3D.new()
	details.name = "Appearance"
	details.set_meta("profile", profile)
	person.add_child(details)
	match profile:
		&"lin_che":
			_traveller(details)
		&"shiori":
			_shiori(details)
		&"shen":
			_shen(details)
		&"xu":
			_apron(details)


static func set_present(person: Node3D, present: bool) -> void:
	var bag := person.get_node_or_null("Appearance/TravelBag") as Node3D
	if bag != null:
		bag.visible = present


static func _traveller(parent: Node3D) -> void:
	var linen := Art.material("eee1c1")
	for side: float in [-1, 1]:
		var collar := Art.box(parent, Vector3(side * 0.09, 1.12, 0.21), Vector3(0.12, 0.07, 0.09), linen)
		collar.rotation.z = side * 0.35
	var bag := Node3D.new()
	bag.name = "TravelBag"
	parent.add_child(bag)
	Art.box(bag, Vector3(-0.13, 0.81, -0.3), Vector3(0.43, 0.46, 0.22), Art.material("647e71"))
	Art.box(bag, Vector3(-0.13, 0.89, -0.425), Vector3(0.33, 0.18, 0.035), Art.material("789181"))
	var strap := Art.box(bag, Vector3(-0.13, 0.89, 0.275), Vector3(0.055, 0.57, 0.025), Art.material("655743"))
	strap.rotation.z = -0.3


static func _shiori(parent: Node3D) -> void:
	var hair := Art.material("41433e")
	Art.sphere(parent, Vector3(0, 1.32, -0.14), Vector3(0.55, 0.48, 0.34), hair)
	for side: float in [-1, 1]:
		Art.box(parent, Vector3(side * 0.23, 1.36, 0.015), Vector3(0.1, 0.32, 0.21), hair)
	var ribbon := Art.material("d3b880")
	for side: float in [-1, 1]:
		var bow := Art.sphere(parent, Vector3(-0.29, 1.37 + side * 0.06, 0.07), Vector3(0.08, 0.16, 0.12), ribbon)
		bow.rotation.z = side * 0.4
	Art.box(parent, Vector3(0, 1.105, 0.215), Vector3(0.34, 0.065, 0.09), Art.material("e0d9bd"))


static func _shen(parent: Node3D) -> void:
	Art.sphere(parent, Vector3(0, 1.48, -0.29), Vector3(0.3, 0.3, 0.26), Art.material("c4beb0"))
	var frame := Art.material("655e51")
	for side: float in [-1, 1]:
		var lens := MeshInstance3D.new()
		var ring := TorusMesh.new()
		ring.inner_radius = 0.051
		ring.outer_radius = 0.065
		ring.rings = 12
		ring.ring_segments = 6
		lens.mesh = ring
		lens.material_override = frame
		lens.position = Vector3(side * 0.105, 1.4, 0.245)
		lens.rotation.x = PI / 2
		parent.add_child(lens)
		Art.box(parent, Vector3(side * 0.2, 1.4, 0.14), Vector3(0.015, 0.015, 0.22), frame)
	Art.box(parent, Vector3(0, 1.4, 0.25), Vector3(0.085, 0.014, 0.014), frame)


static func _apron(parent: Node3D) -> void:
	var linen := Art.material("ddceb0")
	Art.box(parent, Vector3(0, 0.78, 0.29), Vector3(0.43, 0.56, 0.035), linen)
	for side: float in [-1, 1]:
		Art.box(parent, Vector3(side * 0.13, 1.075, 0.24), Vector3(0.035, 0.18, 0.025), linen)
	Art.box(parent, Vector3(0, 0.67, 0.318), Vector3(0.25, 0.15, 0.02), Art.material("bda887"))
