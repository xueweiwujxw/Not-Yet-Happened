extends Node3D
## A staged family meal in the existing shop. No session or evidence callbacks.

const Art := preload("res://src/art/low_poly.gd")
const Appearance := preload("res://src/art/character_appearance.gd")
const Face := preload("res://src/art/character_expression.gd")
const Walk := preload("res://src/art/person_animator.gd")
const Five := preload("res://src/content/chapter_five.gd")
const BOWL_PLACE := Vector3(0.93, 0.91, 0.25)
var exploration_corner: Node3D
var xu: Node3D
var shiori: Node3D
var lin: Node3D
var bowl: Node3D
var elapsed := 0.0
var active := false
var _line := ""


func _ready() -> void:
	hide()
	var wood := Art.material("957558")
	Art.box(self, Vector3(0, 0.78, 0.55), Vector3(2.4, 0.13, 1.3), wood)
	for x: float in [-0.95, 0.95]:
		for z: float in [0.08, 1.02]:
			Art.box(self, Vector3(x, 0.37, z), Vector3(0.12, 0.74, 0.12), wood)
	xu = _person(Vector3(0, -0.2, -0.9), "8fa68a", &"xu", 0.0)
	shiori = _person(Vector3(1.55, -0.2, 0.55), "b69078", &"shiori", -PI / 2)
	lin = _person(Vector3(-1.55, -0.2, 0.55), "78979a", &"lin_che", PI / 2)
	# A bag beside the stool, rather than clipping through a seated body.
	Appearance.set_present(lin, false)
	Art.box(self, Vector3(-2.05, 0.22, 0.6), Vector3(0.35, 0.44, 0.25), Art.material("647e71"))
	for at: Vector3 in [Vector3(0, 0, -0.9), Vector3(1.55, 0, 0.55), Vector3(-1.55, 0, 0.55)]:
		Art.box(self, at + Vector3(0, 0.36, 0), Vector3(0.56, 0.1, 0.5), wood)
		for x: float in [-0.2, 0.2]:
			Art.box(self, at + Vector3(x, 0.16, 0), Vector3(0.07, 0.32, 0.36), wood)
	for at: Vector3 in [Vector3(-0.9, 0.91, 0.55), Vector3(0, 0.91, 0.05)]:
		_bowl(at)
	bowl = _bowl(BOWL_PLACE)
	Art.cylinder(self, Vector3(0, 0.87, 0.65), 0.27, 0.035, Art.material("d8c9a7"))
	for i: int in range(4):
		Art.sphere(self, Vector3(-0.14 + i * 0.09, 0.91, 0.65), Vector3(0.15, 0.08, 0.17), Art.material("7f9765"))
	for x: float in [-0.6, 0.6]:
		Art.box(self, Vector3(x, 0.87, 0.9), Vector3(0.025, 0.025, 0.42), wood)


func _bowl(at: Vector3) -> Node3D:
	var vessel := Art.cylinder(self, at, 0.09, 0.12, Art.material("eee0bd"), 0.18)
	Art.cylinder(vessel, Vector3(0, 0.062, 0), 0.15, 0.01, Art.material("c6ad73"))
	return vessel


func _person(at: Vector3, shirt: String, profile: StringName, facing: float) -> Node3D:
	var person := Art.person(self, at, shirt)
	Appearance.apply(person, profile)
	person.remove_meta("rest_y")
	person.rotation.y = facing
	# Split the legs at the knees so seated feet point down instead of sticking out.
	for side: String in ["Left", "Right"]:
		var hip := person.get_node("Leg" + side) as Node3D
		for mesh: Node in hip.get_children():
			mesh.free()
		Art.box(hip, Vector3(0, -0.125, 0), Vector3(0.19, 0.25, 0.22), Art.material("4e6668"))
		var knee := Node3D.new()
		knee.name = "Knee"
		knee.position.y = -0.25
		hip.add_child(knee)
		Art.box(knee, Vector3(0, -0.13, 0), Vector3(0.18, 0.26, 0.21), Art.material("4e6668"))
		Art.box(knee, Vector3(0, -0.27, 0.06), Vector3(0.23, 0.12, 0.34), Art.material("e8d8b7"))
	return person


func present(state: Dictionary) -> void:
	var line: String = state["line"] if state["speaking"] else ""
	if line != _line:
		elapsed = 0.0
	_line = line
	active = line in Five.LINES[&"dinner"]
	if not active:
		_show(false)


func tick(delta: float, enabled: bool) -> bool:
	elapsed += maxf(delta, 0.0)
	_show(active and enabled)
	if not visible:
		return false
	var serving: bool = _line == Five.LINES[&"dinner"][0]
	var time := elapsed if serving else 6.0
	var home := smoothstep(2.8, 4.8, time)
	var step_in := smoothstep(0.9, 1.3, time) * (1.0 - smoothstep(2.0, 2.7, time))
	xu.position = Vector3(1.27, 0, -0.95).lerp(Vector3(0, 0, -0.9), home)
	xu.position.z += step_in * 0.4
	xu.rotation = Vector3(0, -PI / 2 * sin(home * PI), 0)
	Walk.apply(xu, home * 14.0 + step_in * 2.0, (home > 0 and home < 1) or (step_in > 0 and step_in < 1))
	_pose_seated(xu, smoothstep(4.8, 5.4, time))
	_pose_seated(shiori, 1.0)
	_pose_seated(lin, 1.0)
	var reach := smoothstep(0.4, 1.3, time) * (1.0 - smoothstep(2.0, 2.7, time))
	var arm := xu.get_node("ArmLeft") as Node3D
	if home == 0:
		arm.rotation.x = -1.55 * reach
	var hand: Vector3 = to_local(arm.to_global(Vector3(0, -0.48, 0)))
	bowl.position = hand.lerp(BOWL_PLACE, smoothstep(1.2, 1.9, time)) if time < 1.9 else BOWL_PLACE
	bowl.rotation = Vector3.ZERO
	var answering: bool = _line == Five.LINES[&"dinner"][1] and elapsed >= 7.0
	Face.apply(shiori, &"warm" if answering or _line == Five.LINES[&"dinner"][2] else &"reserved", elapsed, true)
	Face.apply(xu, &"warm", elapsed + 1.0, true)
	Face.apply(lin, &"neutral", elapsed + 2.0, true)
	if _line == Five.LINES[&"dinner"][2]:
		xu.rotation.x = sin(clampf((elapsed - 0.4) / 1.2, 0, 1) * PI) * 0.07
	return true


func _pose_seated(person: Node3D, weight: float) -> void:
	person.position.y = -0.2 * weight
	for side: String in ["Left", "Right"]:
		var hip := person.get_node("Leg" + side) as Node3D
		hip.rotation.x = lerpf(hip.rotation.x, -PI / 2, weight)
		(hip.get_node("Knee") as Node3D).rotation.x = PI / 2 * weight


func _show(showing: bool) -> void:
	visible = showing
	if is_instance_valid(exploration_corner):
		exploration_corner.visible = not showing
