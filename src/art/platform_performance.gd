extends Node3D
## A boat-side view of the authored observation, never a simulation of unseen history.

const Art := preload("res://src/art/low_poly.gd")
const Four := preload("res://src/content/chapter_four.gd")
const Walk := preload("res://src/art/person_animator.gd")
var sister: Node3D
var route: Node3D
var lamp: OmniLight3D
var bulb: MeshInstance3D
var rain: Node3D
var spray: Node3D
var elapsed := 0.0
var active := false
var _line := ""
var _safe := false
var _movement := false
var _surroundings: Array[Dictionary] = []


func _ready() -> void:
	hide()
	var sea := Art.material("526e78")
	Art.box(self, Vector3(0, -0.15, 0), Vector3(10, 0.25, 7.6), sea)
	Art.box(self, Vector3(0, 0.45, -0.6), Vector3(5, 0.9, 2), Art.material("85938e"))
	# The foreground gunwale establishes the player's already-authored boat viewpoint.
	Art.box(self, Vector3(0, 0.35, 2.8), Vector3(6, 0.2, 0.2), Art.material("a99677"))
	Art.box(self, Vector3(0, 0.15, 3.15), Vector3(6, 0.3, 0.65), Art.material("586469"))
	route = Node3D.new()
	add_child(route)
	Art.box(route, Vector3(-3.15, 0.18, -0.6), Vector3(1.3, 0.35, 1.5), Art.material("85938e"))
	for i: int in range(6):
		Art.box(route, Vector3(-2.35 - i * 0.2, 0.88 - i * 0.12, -0.6), Vector3(0.25, 0.07, 0.85), Art.material("bcc4b7"))
	lamp = OmniLight3D.new()
	lamp.position = Vector3(-1.5, 2.8, -0.6)
	lamp.light_color = Color("ffdb95")
	lamp.light_energy = 1.2
	lamp.omni_range = 5
	add_child(lamp)
	Art.cylinder(self, Vector3(-1.9, 1.8, -1.2), 0.05, 1.8, Art.material("4b6367"))
	bulb = Art.cylinder(self, Vector3(-1.9, 2.7, -1.2), 0.23, 0.14, Art.material("dfc68e"))
	sister = Art.person(self, Vector3(0.8, 0.92, -0.6), "c9ad78")
	Art.sphere(sister, Vector3(0, 1.33, -0.17), Vector3(0.59, 0.64, 0.36), Art.material("41433e"))
	# This figure belongs to the observation shot, not proximity dialogue staging.
	sister.remove_meta("rest_y")
	rain = Node3D.new()
	add_child(rain)
	var mist := Art.material("81979c")
	spray = Node3D.new()
	add_child(spray)
	for i: int in range(7):
		Art.sphere(spray, Vector3(-3 + i, 0.9, 0.9), Vector3(2, 3.8, 0.6), mist)
	for i: int in range(32):
		var streak := Art.box(rain, Vector3(-4.5 + (i % 8) * 1.25, 0.5 + (i / 8) * 0.6, 0.8 + (i % 3) * 0.4), Vector3(0.018, 0.42, 0.018), mist)
		streak.rotation.z = -0.35


func present(state: Dictionary) -> void:
	var line: String = state["line"] if state["speaking"] else ""
	if line != _line:
		elapsed = 0.0
	_line = line
	# The current authored observation is already being shown in subtitles. Pending facts
	# stay pending until the session completes that dialogue, exactly as before this shot.
	active = line in [Four.LINES[&"safe"][0], Four.LINES[&"safe"][1], Four.LINES[&"fall"][0], Four.LINES[&"fall"][1]]
	_safe = line in Four.LINES[&"safe"]
	_movement = line == Four.LINES[&"safe"][1] or line == Four.LINES[&"fall"][1]
	lamp.visible = state["facts"].get(&"backup_connected", false)
	bulb.material_override = Art.material("dfc68e" if lamp.visible else "596b70")
	route.visible = state["facts"].get(&"ladder_lowered", false)
	if not active:
		_show_shot(false)


func tick(delta: float, enabled: bool) -> bool:
	elapsed += maxf(delta, 0.0)
	_show_shot(active and enabled)
	if not visible:
		return false
	var travel := smoothstep(0.4, 3.4, elapsed) if _movement else 0.0
	spray.visible = not _safe and _movement and elapsed > 1.2
	spray.scale.y = maxf(0.001, smoothstep(1.2, 2.0, elapsed))
	sister.visible = _movement and (_safe or elapsed < 2.0)
	sister.rotation = Vector3.ZERO
	sister.position = Vector3(0.8, 0.92, -0.6)
	if _safe:
		sister.position.x = lerpf(0.8, -3.1, travel)
		sister.position.y = 0.92 - smoothstep(0.73, 1.0, travel) * 0.6
		sister.rotation.y = -PI / 2
		var height := sister.position.y
		Walk.apply(sister, travel * 24.0, travel > 0.0 and travel < 1.0)
		sister.position.y = height
	else:
		# Only the loss of footing is visible. Never draw impact, a body or a rescue.
		sister.position.x += smoothstep(0.4, 1.8, elapsed) * 1.5
		sister.rotation.z = -smoothstep(0.8, 1.8, elapsed) * 0.45
	rain.position.x = fmod(elapsed * 0.25, 0.8)
	rain.position.y = -fmod(elapsed * 0.8, 0.6)
	return true


func _show_shot(showing: bool) -> void:
	if showing and not visible:
		_surroundings.clear()
		for node: Node in get_parent().get_children():
			if node is Node3D and node != self and not node is Light3D:
				_surroundings.append({"node": node, "visible": node.visible})
				node.hide()
	elif not showing and visible:
		for entry: Dictionary in _surroundings:
			if is_instance_valid(entry["node"]):
				entry["node"].visible = entry["visible"]
		_surroundings.clear()
	visible = showing
