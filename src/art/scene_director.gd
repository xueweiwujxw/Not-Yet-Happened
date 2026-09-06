extends RefCounted
## Presentation-only camera blocking. Never advances dialogue or writes world facts.

const Blocking := preload("res://src/art/dialogue_blocking.gd")

var enabled := true
var talking := false
var focus := Vector3.ZERO
var elapsed := 0.0
var actor: Node3D
var player: Node3D
var player_visual: Node3D
var _line := ""
var _room: Node3D
var _cue: Dictionary = {}


func stage(room: Node3D, avatar: Node3D, speaking: bool, text: String = "") -> void:
	if text != _line or not is_instance_valid(_room) or room != _room or speaking != talking:
		elapsed = 0.0
	_line = text
	_room = room
	_cue = Blocking.cue(text) if speaking else {}
	player = avatar
	talking = speaking
	actor = null
	var nearest := 3.5
	for node: Node in room.find_children("*", "Node3D", true, false):
		if node.has_meta("rest_y") and node.is_visible_in_tree():
			if not _cue.is_empty():
				if node.get_meta("actor_id", &"") == _cue["actor"]:
					actor = node
					break
				continue
			var gap: float = node.global_position.distance_to(avatar.global_position)
			if gap < nearest:
				actor = node
				nearest = gap
	focus = avatar.global_position
	if actor != null:
		focus = (focus + actor.global_position) * 0.5
	# Keep the cutaway's interactive area inside the established screen composition.
	focus = Vector3(clampf(focus.x, -1.7, 1.7), 0.7, clampf(focus.z, -1.3, 0.8))


func tick(camera: Camera3D, delta: float) -> void:
	elapsed += delta
	var close: bool = enabled and talking
	var aim := focus if close else Vector3(0, 0.6, 0)
	var offset := Vector3(11, 10, 14)
	var weight := 1.0 - exp(-3.0 * delta)
	camera.global_position = camera.global_position.lerp(aim + offset, weight)
	camera.size = lerpf(camera.size, 10.8 if close else 13.2, weight)
	camera.v_offset = lerpf(camera.v_offset, -0.85, weight)
	camera.look_at(camera.global_position - offset)
	if close and elapsed >= float(_cue.get("delay", 0.0)) and is_instance_valid(actor) and is_instance_valid(player) and actor.is_visible_in_tree():
		var direction := player.global_position - actor.global_position
		if Vector2(direction.x, direction.z).length() > 0.1:
			var local_direction: Vector3 = actor.get_parent().global_basis.inverse() * direction
			actor.rotation.y = rotate_toward(actor.rotation.y, atan2(local_direction.x, local_direction.z) + float(_cue.get("turn", 0.0)), delta * 1.8)
			if is_instance_valid(player_visual):
				var player_direction: Vector3 = player_visual.get_parent().global_basis.inverse() * -direction
				player_visual.rotation.y = rotate_toward(player_visual.rotation.y, atan2(player_direction.x, player_direction.z), delta * 2.5)
