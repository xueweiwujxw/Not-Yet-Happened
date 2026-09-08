extends RefCounted
## Decorative equipment cues. Never creates evidence or advances a session.

const Three := preload("res://src/content/chapter_three.gd")
const Six := preload("res://src/content/chapter_six.gd")
var _room: Node3D
var _line := ""
var elapsed := 0.0
var _props: Array[Dictionary] = []
var _kind := &""


func stage(room: Node3D, text: String, speaking: bool) -> void:
	if not is_instance_valid(_room) or _room != room:
		_room = room
		_props.clear()
		_line = ""
		for node: Node in room.find_children("*", "Node3D", true, false):
			if node.has_meta("performance_id"):
				_props.append({"node": node, "home": node.position})
	var line := text if speaking else ""
	if line != _line:
		elapsed = 0.0
	_line = line
	_kind = &""
	if line == Three.LINES[&"equipment"][0]:
		_kind = &"scanner"
	elif line in Six.LINES[&"join_together"] or line in Six.LINES[&"join_alone"]:
		_kind = &"camera"
	# Immediately clear the preceding cue, including when no render frame occurs between skips.
	for entry: Dictionary in _props:
		var node: Node3D = entry["node"]
		if is_instance_valid(node) and node.get_meta("performance_id") != _kind:
			node.hide()


func tick(delta: float, enabled: bool) -> void:
	elapsed += maxf(delta, 0.0)
	for entry: Dictionary in _props:
		var node: Node3D = entry["node"]
		if not is_instance_valid(node):
			continue
		var active: bool = enabled and node.get_meta("performance_id") == _kind
		if _kind == &"scanner" and active:
			node.visible = elapsed < 2.4
			node.position = entry["home"] + Vector3(0, 0, lerpf(-0.25, 0.25, clampf(elapsed / 2.4, 0, 1)))
		elif _kind == &"camera" and active:
			# A small steady timer lamp, not a screen flash or an extra shutter observation.
			node.visible = elapsed < 1.8
		else:
			node.hide()
