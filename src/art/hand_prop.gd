extends RefCounted
## A serving gesture, independent of the table's evidence and collision geometry.


static func apply(person: Node3D, serving: bool, elapsed: float) -> void:
	var arm := person.get_node_or_null("ArmRight") as Node3D
	if arm == null:
		return
	var bowl := arm.get_node_or_null("HeldBowl") as Node3D
	if bowl == null:
		return
	bowl.visible = serving
	if serving:
		arm.rotation.x = -1.15 * smoothstep(0.0, 0.6, maxf(elapsed, 0.0))
		# Keep the vessel level as the hand rises; the character may still turn.
		bowl.basis = arm.basis.inverse()
