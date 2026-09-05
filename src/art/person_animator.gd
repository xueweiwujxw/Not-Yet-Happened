extends RefCounted
## Small procedural walk cycle for the named limbs produced by LowPoly.person().


static func apply(person: Node3D, phase: float, moving: bool) -> void:
	var swing := sin(phase) * 0.55 if moving else 0.0
	var bounce := absf(sin(phase)) * 0.035 if moving else 0.0
	person.position.y = float(person.get_meta("rest_y", person.position.y)) + bounce
	_pose_limb(person, "ArmLeft", swing)
	_pose_limb(person, "ArmRight", -swing)
	_pose_limb(person, "LegLeft", -swing * 0.45)
	_pose_limb(person, "LegRight", swing * 0.45)


static func _pose_limb(person: Node3D, limb_name: String, angle: float) -> void:
	var limb := person.get_node_or_null(limb_name) as Node3D
	if limb != null:
		limb.rotation.x = angle
