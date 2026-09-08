extends RefCounted
## Small authored steps on the existing set. No navigation, facts or dialogue callbacks.

const Animator := preload("res://src/art/person_animator.gd")
var actors: Array[Dictionary] = []
var _room: Node3D


func bind(room: Node3D) -> void:
	if is_instance_valid(_room) and _room == room:
		return
	_room = room
	actors.clear()
	for node: Node in room.find_children("*", "Node3D", true, false):
		if node.has_meta("rest_y"):
			actors.append({"node": node, "home": node.position, "speed": 0.0, "phase": 0.0})


func tick(active: Node3D, cue: Dictionary, elapsed: float, enabled: bool, player: Node3D, delta: float) -> void:
	var dt := clampf(delta, 0.0, 0.05)
	for entry: Dictionary in actors:
		var person: Node3D = entry["node"]
		if not is_instance_valid(person) or not person.is_visible_in_tree():
			continue
		var performing: bool = enabled and person == active and elapsed >= float(cue.get("delay", 0.0))
		var target: Vector3 = entry["home"]
		if performing:
			target += Vector3(cue.get("step", Vector3.ZERO))
		var gap := Vector2(target.x - person.position.x, target.z - person.position.z)
		entry["speed"] = move_toward(float(entry["speed"]), minf(0.65, gap.length() * 3.0), dt * 1.8)
		var step := gap.limit_length(float(entry["speed"]) * dt)
		var next := person.position + Vector3(step.x, 0, step.y)
		if step.is_zero_approx() or _clear(person, next, player):
			person.position = next
		else:
			step = Vector2.ZERO
			entry["speed"] = 0.0
		entry["phase"] = fmod(float(entry["phase"]) + step.length() * 9.0, TAU)
		person.set_meta("staging_walking", step.length() > 0.001)
		if step.length() > 0.001:
			person.rotation.y = rotate_toward(person.rotation.y, atan2(step.x, step.y), dt * 3.0)
		Animator.blend(person, entry["phase"], step.length() / maxf(dt, 0.001) / 0.65, dt)
		# A restrained hand movement, fading away when a line is skipped or motion is off.
		var arm := person.get_node_or_null("ArmRight") as Node3D
		if arm != null:
			var gesture := float(cue.get("gesture", 0.0)) if performing else 0.0
			arm.rotation.z = lerpf(arm.rotation.z, gesture, 1.0 - exp(-5.0 * dt))


func _clear(person: Node3D, next: Vector3, player: Node3D) -> bool:
	var world_next: Vector3 = person.get_parent().to_global(next)
	if is_instance_valid(player):
		var gap := world_next - player.global_position
		if Vector2(gap.x, gap.z).length() < 0.75:
			return false
	var shape := CapsuleShape3D.new()
	shape.radius = 0.24
	shape.height = 1.4
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform.origin = world_next + Vector3(0, 0.85, 0)
	return person.get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()
