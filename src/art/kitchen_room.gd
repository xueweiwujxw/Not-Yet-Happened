extends Node3D
## An open-front architectural diorama: plaster, oak, sage cabinetry and a framed summer sea.

const Art := preload("res://src/art/low_poly.gd")
var lamp: OmniLight3D
var shiori: Node3D
var shen: Node3D
var letter: Node3D
var bulb: MeshInstance3D
var _wood := Art.material("b68256")
var _cream := Art.material("eee0bd")
var _sage := Art.material("8bafa1")
var _dark := Art.material("475c59")


func _ready() -> void:
	_architecture()
	_kitchen()
	_living()
	_lighting()
	shiori = Art.person(self, Vector3(2.3, 0.08, -1.45), "f0dbb7")
	shiori.rotation.y = -0.65
	shen = Art.person(self, Vector3(-3.55, 0.08, 2.7), "7f9194", "ccc4ad")
	shen.rotation.y = 0.6
	shiori.hide()
	shen.hide()
	letter.hide()


func _architecture() -> void:
	Art.box(self, Vector3(0, -0.32, 0), Vector3(10.4, 0.6, 8.0), Art.material("c8ba9b"))
	Art.box(self, Vector3(0, -0.025, 0), Vector3(10, 0.08, 7.6), _wood, true)
	for row: int in range(24):
		for column: int in range(5):
			var shade := Art.material(["c59c6c", "bb8d5d", "cba373", "bd9465"][(row + column * 3) % 4])
			Art.box(self, Vector3(-4.0 + column * 2.0, 0.023, -3.64 + row * 0.315), Vector3(1.975, 0.035, 0.3), shade)
	# Back wall has a real opening, not an image pasted over a solid wall.
	Art.box(self, Vector3(-2.75, 1.8, -3.8), Vector3(4.5, 3.6, 0.18), _cream, true)
	Art.box(self, Vector3(4.6, 1.8, -3.8), Vector3(0.8, 3.6, 0.18), _cream, true)
	Art.box(self, Vector3(1.85, 0.64, -3.8), Vector3(4.7, 1.28, 0.18), _cream, true)
	Art.box(self, Vector3(1.85, 3.35, -3.8), Vector3(4.7, 0.5, 0.18), _cream)
	Art.box(self, Vector3(-5.0, 1.8, 0), Vector3(0.18, 3.6, 7.6), Art.material("dcc7a0"), true)
	for z: float in [-3.72, 3.72]:
		Art.box(self, Vector3(-4.87, 1.8, z), Vector3(0.18, 3.6, 0.18), _wood)
	Art.box(self, Vector3(0, 0.13, -3.66), Vector3(10, 0.22, 0.12), _wood)
	Art.box(self, Vector3(-4.85, 0.13, 0), Vector3(0.12, 0.22, 7.5), _wood)
	Art.box(self, Vector3(-2.7, 3.54, -3.61), Vector3(4.6, 0.16, 0.2), _wood)
	_window()
	# Painted doorway and mail hook on the left, retained as a cutaway wall.
	Art.box(self, Vector3(-4.87, 1.3, 2.3), Vector3(0.12, 2.55, 1.5), _wood)
	Art.box(self, Vector3(-4.78, 1.25, 2.3), Vector3(0.07, 2.38, 1.28), Art.material("79958c"))
	Art.sphere(self, Vector3(-4.7, 1.1, 2.74), Vector3(0.09, 0.09, 0.09), Art.material("bda260"))
	Art.box(self, Vector3(-4.76, 1.5, 0.5), Vector3(0.06, 0.24, 0.17), Art.material("f4e6c9"))
	Art.box(self, Vector3(-4.71, 1.51, 0.5), Vector3(0.02, 0.11, 0.08), _dark)
	Art.box(self, Vector3(-4.76, 1.85, 1.2), Vector3(0.03, 0.47, 0.34), Art.material("f5e9cc"))
	for y: float in [1.98, 1.88, 1.81]:
		Art.box(self, Vector3(-4.74, y, 1.2), Vector3(0.01, 0.012, 0.23), _dark)


func _window() -> void:
	var frame := Art.material("678f91")
	for x: float in [-0.45, 1.85, 4.15]:
		Art.box(self, Vector3(x, 2.2, -3.66), Vector3(0.1, 1.9, 0.19), frame)
	for y: float in [1.28, 2.12, 3.1]:
		Art.box(self, Vector3(1.85, y, -3.66), Vector3(4.75, 0.09, 0.19), frame)
	Art.box(self, Vector3(1.85, 1.23, -3.5), Vector3(4.9, 0.15, 0.55), _wood)
	for x: float in [-0.7, 4.42]:
		Art.box(self, Vector3(x, 2.2, -3.43), Vector3(0.42, 1.91, 0.1), Art.material("aec5b6"))
		for i: int in range(9):
			Art.box(self, Vector3(x, 1.43 + i * 0.18, -3.35), Vector3(0.4, 0.055, 0.1), frame)
	Art.plant(self, Vector3(3.5, 1.31, -3.47), 0.8)
	var sea := Art.material("72aaa8")
	sea.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	Art.box(self, Vector3(0, -0.35, -20), Vector3(60, 0.12, 32), sea)
	var foam := Art.material("b5d3bd")
	foam.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for i: int in range(22):
		Art.box(self, Vector3(-15 + float(i % 6) * 5.5, -0.27, -6 - floorf(float(i) / 6.0) * 3.7), Vector3(2.2 + i % 3, 0.02, 0.07), foam)


func _kitchen() -> void:
	Art.box(self, Vector3(-2.65, 0.55, -2.96), Vector3(4.1, 1.1, 1.15), _sage, true)
	Art.box(self, Vector3(-2.65, 1.16, -2.94), Vector3(4.28, 0.16, 1.27), Art.material("efe5cb"))
	for x: float in [-4.13, -3.15, -2.17, -1.19]:
		Art.box(self, Vector3(x, 0.61, -2.355), Vector3(0.91, 0.88, 0.055), Art.material("9dbba8"))
		Art.box(self, Vector3(x, 0.83, -2.305), Vector3(0.26, 0.045, 0.04), _dark)
	for column: int in range(12):
		for row: int in range(3):
			Art.box(self, Vector3(-4.65 + column * 0.34, 1.43 + row * 0.3, -3.675), Vector3(0.325, 0.285, 0.025), Art.material("e9e3c9" if (row + column) % 4 else "a4bcb0"))
	Art.box(self, Vector3(-1.9, 1.25, -2.96), Vector3(0.94, 0.035, 0.69), _dark)
	Art.box(self, Vector3(-1.9, 1.27, -2.96), Vector3(0.7, 0.025, 0.49), Art.material("aac3bb"))
	Art.cylinder(self, Vector3(-1.88, 1.47, -3.31), 0.035, 0.45, _dark)
	Art.box(self, Vector3(-1.88, 1.68, -3.18), Vector3(0.06, 0.06, 0.28), _dark)
	Art.box(self, Vector3(-3.52, 1.26, -2.94), Vector3(0.95, 0.035, 0.67), _dark)
	for x: float in [-3.77, -3.28]:
		Art.cylinder(self, Vector3(x, 1.285, -2.94), 0.17, 0.025, Art.material("293f41"))
	Art.cylinder(self, Vector3(-3.72, 1.43, -2.94), 0.2, 0.28, Art.material("c98a5b"))
	Art.cylinder(self, Vector3(-3.72, 1.59, -2.94), 0.21, 0.045, _cream, 0.13)
	Art.box(self, Vector3(-2.8, 2.57, -3.35), Vector3(3.3, 0.13, 0.57), _wood)
	for i: int in range(5):
		Art.cylinder(self, Vector3(-4.05 + i * 0.31, 2.81, -3.35), 0.105, 0.35, Art.material(["d6b07b", "b6c6ad", "ede2bd"][i % 3]))
		Art.cylinder(self, Vector3(-4.05 + i * 0.31, 3.0, -3.35), 0.112, 0.045, _wood)
	Art.plant(self, Vector3(-1.45, 2.66, -3.36), 0.7)
	# A small rounded-looking vintage fridge, split panels and contrasting handles.
	Art.box(self, Vector3(-4.2, 0.98, -0.95), Vector3(1.15, 1.96, 1.1), Art.material("d6cc9f"), true)
	Art.box(self, Vector3(-4.2, 1.51, -0.38), Vector3(1.07, 0.8, 0.04), _cream)
	Art.box(self, Vector3(-4.2, 0.56, -0.38), Vector3(1.07, 1.02, 0.04), _cream)
	for y: float in [0.9, 1.6]:
		Art.box(self, Vector3(-3.84, y, -0.33), Vector3(0.055, 0.27, 0.04), _dark)
	Art.plant(self, Vector3(-4.2, 1.98, -0.95), 0.75)


func _living() -> void:
	Art.box(self, Vector3(0.85, 0.052, 0.7), Vector3(3.7, 0.025, 3.25), Art.material("cb9073"))
	for z: float in [-0.76, -0.61, 2.01, 2.16]:
		Art.box(self, Vector3(0.85, 0.068, z), Vector3(3.6, 0.012, 0.075), Art.material("edcd99"))
	Art.box(self, Vector3(0.65, 0.95, 0.1), Vector3(2.5, 0.16, 1.5), _wood, true)
	for x: float in [-0.35, 1.65]:
		for z: float in [-0.45, 0.65]:
			Art.box(self, Vector3(x, 0.45, z), Vector3(0.13, 0.9, 0.13), _dark, true)
	Art.box(self, Vector3(0.67, 1.045, 0.1), Vector3(0.75, 0.018, 1.49), Art.material("dfc99e"))
	for z: float in [-0.9, 1.22]:
		_chair(Vector3(0.65, 0.1, z), 0.0 if z > 0 else PI)
	_radio(Vector3(-0.04, 1.06, 0.05))
	letter = Node3D.new()
	letter.position = Vector3(1.2, 1.045, 0.16)
	add_child(letter)
	Art.box(letter, Vector3.ZERO, Vector3(0.47, 0.015, 0.3), Art.material("f4e9ca")).rotation.y = -0.2
	for z: float in [-0.075, -0.025, 0.025]:
		Art.box(letter, Vector3(0, 0.01, z), Vector3(0.3, 0.008, 0.009), Art.material("a4997c"))
	Art.cylinder(self, Vector3(1.38, 1.16, -0.4), 0.12, 0.24, Art.material("c57554"))
	Art.cylinder(self, Vector3(1.38, 1.285, -0.4), 0.09, 0.012, Art.material("665646"))
	# Photo sideboard with a stylized physical photograph, books and a bowl of citrus.
	Art.box(self, Vector3(3.95, 0.52, 1.6), Vector3(1.18, 1.04, 2.05), _sage, true)
	Art.box(self, Vector3(3.95, 1.09, 1.6), Vector3(1.3, 0.11, 2.16), _wood)
	Art.box(self, Vector3(3.98, 1.46, 1.06), Vector3(0.7, 0.61, 0.09), _dark)
	Art.box(self, Vector3(3.98, 1.46, 1.117), Vector3(0.57, 0.49, 0.015), Art.material("e8cb96"))
	for x: float in [3.84, 3.99, 4.14]:
		Art.sphere(self, Vector3(x, 1.51, 1.133), Vector3(0.09, 0.11, 0.02), Art.material("728b83"))
	Art.cylinder(self, Vector3(3.93, 1.2, 2.1), 0.28, 0.12, _cream, 0.35)
	for i: int in range(4):
		Art.sphere(self, Vector3(3.8 + (i % 2) * 0.2, 1.32, 1.96 + floorf(i / 2.0) * 0.2), Vector3.ONE * 0.2, Art.material("dca252"))
	Art.plant(self, Vector3(3.9, 0.07, -2.2), 1.5)
	# Pendant kept high enough to read the scene underneath it.
	Art.cylinder(self, Vector3(0.6, 3.32, 0.1), 0.015, 0.7, _dark)
	Art.cylinder(self, Vector3(0.6, 2.91, 0.1), 0.48, 0.26, Art.material("c57952"), 0.15)
	bulb = Art.sphere(self, Vector3(0.6, 2.74, 0.1), Vector3(0.2, 0.15, 0.2), _cream)


func _chair(at: Vector3, angle: float) -> void:
	var chair := Node3D.new()
	chair.position = at
	chair.rotation.y = angle
	add_child(chair)
	Art.box(chair, Vector3(0, 0.49, 0), Vector3(0.67, 0.12, 0.65), _wood, true)
	for x: float in [-0.25, 0.25]:
		for z: float in [-0.22, 0.22]:
			Art.box(chair, Vector3(x, 0.22, z), Vector3(0.07, 0.46, 0.07), _dark)
	Art.box(chair, Vector3(0, 0.94, 0.28), Vector3(0.67, 0.5, 0.09), _wood)


func _radio(at: Vector3) -> void:
	Art.box(self, at + Vector3(0, 0.17, 0), Vector3(0.65, 0.34, 0.27), Art.material("526f6a"))
	Art.box(self, at + Vector3(-0.11, 0.18, 0.15), Vector3(0.29, 0.21, 0.02), _dark)
	for i: int in range(5):
		Art.box(self, at + Vector3(-0.11, 0.1 + i * 0.035, 0.17), Vector3(0.25, 0.009, 0.02), Art.material("bcb492"))
	Art.sphere(self, at + Vector3(0.21, 0.13, 0.16), Vector3.ONE * 0.08, _cream)
	Art.box(self, at + Vector3(0.18, 0.25, 0.16), Vector3(0.15, 0.05, 0.025), _cream)


func _lighting() -> void:
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("e6d6b9")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("c7d9d1")
	settings.ambient_light_energy = 0.3
	settings.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	environment.environment = settings
	add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-38, -35, 0)
	sun.light_color = Color("fff0d6")
	sun.light_energy = 0.7
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 45
	add_child(sun)
	lamp = OmniLight3D.new()
	lamp.position = Vector3(0.6, 2.65, 0.1)
	lamp.omni_range = 5.0
	lamp.light_color = Color("ffd899")
	lamp.light_energy = 0.3
	add_child(lamp)


func sync_state(state: Dictionary) -> void:
	shiori.visible = state["people_present"]
	shen.visible = state["people_present"]
	letter.visible = state["people_present"]
	lamp.visible = state["repaired"] and state["lamp"] == preload("res://src/content/chapter_one.gd").LAMP_ON
	bulb.material_override = Art.material("fff0be" if lamp.visible else "aaa994")
