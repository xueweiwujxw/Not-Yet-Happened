extends Node3D
## Shared cutaway dimensions and original props; each chapter supplies its own set.

const Art := preload("res://src/art/low_poly.gd")
const Details := preload("res://src/art/coastal_details.gd")
var sun: DirectionalLight3D
var environment: WorldEnvironment


func foundation(floor_color: String, sky: String, indoors: bool = true) -> void:
	Art.box(self, Vector3(0, -0.2, 0), Vector3(10, 0.4, 7.6), Art.material(floor_color), true)
	if indoors:
		Art.box(self, Vector3(0, 1.65, -3.8), Vector3(10, 3.3, 0.15), Art.material("c6cec0"), true)
		Art.box(self, Vector3(-5, 1.65, 0), Vector3(0.15, 3.3, 7.6), Art.material("abbcaf"), true)
	for x: int in range(10):
		Art.box(self, Vector3(-4.5 + x, 0.015, 0), Vector3(0.02, 0.01, 7.5), Art.material("8a9690"))
	add_child(Details.new())
	environment = WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color(sky)
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("b0c8cc")
	environment.environment.ambient_light_energy = 0.55
	add_child(environment)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -30, 0)
	sun.light_color = Color("ffe8c3")
	sun.light_energy = 0.75
	sun.shadow_enabled = true
	add_child(sun)


func desk(at: Vector3, width: float = 2.0) -> void:
	Art.box(self, at + Vector3(0, 0.85, 0), Vector3(width, 0.14, 0.8), Art.material("97785c"), true)
	for x: float in [-width * 0.4, width * 0.4]:
		Art.box(self, at + Vector3(x, 0.4, 0), Vector3(0.12, 0.8, 0.65), Art.material("526360"), true)


func paper(at: Vector3, color: String = "f0dfb7") -> MeshInstance3D:
	return Art.box(self, at, Vector3(0.65, 0.025, 0.45), Art.material(color))


func notice(at: Vector3, pages: int = 2) -> void:
	Art.box(self, at, Vector3(2.1, 1.15, 0.1), Art.material("876b50"))
	for i: int in range(pages):
		Art.box(self, at + Vector3(-0.5 + i * 0.85, 0, 0.07), Vector3(0.55, 0.83, 0.02), Art.material("efe0bd"))


func lamp(at: Vector3) -> OmniLight3D:
	Art.cylinder(self, at, 0.3, 0.16, Art.material("e5bb72"), 0.17)
	var light := OmniLight3D.new()
	light.position = at - Vector3(0, 0.2, 0)
	light.light_color = Color("ffdc98")
	light.light_energy = 0.7
	light.omni_range = 5
	add_child(light)
	return light


func exit_mat() -> void:
	Art.box(self, Vector3(-2.4, 0.04, 2.8), Vector3(1.5, 0.06, 0.8), Art.material("ac885e"))


func sync_state(_state: Dictionary) -> void:
	pass
