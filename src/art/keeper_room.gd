extends Node3D
## Cutaway keeper office. The door stays visually closed until its evidence is committed.

const Art := preload("res://src/art/low_poly.gd")
const Session := preload("res://src/game/chapter_two_session.gd")
var door: Node3D
var escort: Node3D
var waiting_child: Node3D
var sun: DirectionalLight3D
var lamp: OmniLight3D
var _phase := -1


func _ready() -> void:
	var wood := Art.material("8b7058")
	var plaster := Art.material("b9c8bd")
	var dark := Art.material("3e5358")
	Art.box(self, Vector3(0, -0.2, 0), Vector3(10.2, 0.4, 7.8), wood, true)
	Art.box(self, Vector3(2.5, -0.2, -4.8), Vector3(3.2, 0.4, 2.3), wood)
	for x: int in range(10):
		for z: int in range(8):
			Art.box(self, Vector3(-4.5 + x, 0.012, -3.3 + z * 0.94), Vector3(0.98, 0.025, 0.92), Art.material("87978f" if (x + z) % 2 else "96a49a"))
	Art.box(self, Vector3(-5, 1.8, 0), Vector3(0.15, 3.6, 7.6), plaster, true)
	Art.box(self, Vector3(-1.8, 1.8, -3.8), Vector3(6.4, 3.6, 0.15), plaster, true)
	Art.box(self, Vector3(4.3, 1.8, -3.8), Vector3(1.4, 3.6, 0.15), plaster, true)
	Art.box(self, Vector3(2.5, 3.3, -3.8), Vector3(2.2, 0.6, 0.15), plaster)
	# Blocking threshold prevents walking into an unobserved/cutaway area.
	Art.box(self, Vector3(2.5, 0.3, -3.65), Vector3(2.2, 0.6, 0.25), wood, true)
	door = Node3D.new()
	door.position = Vector3(1.4, 0, -3.7)
	add_child(door)
	Art.box(door, Vector3(1.05, 1.45, 0), Vector3(2.1, 2.9, 0.12), dark)
	Art.sphere(door, Vector3(1.8, 1.25, 0.1), Vector3.ONE * 0.12, Art.material("c5ad73"))
	# Desk, black telephone and open notebook.
	Art.box(self, Vector3(-2.2, 0.92, -2.0), Vector3(4.7, 0.18, 1.3), wood, true)
	for x: float in [-4.1, -0.3]:
		Art.box(self, Vector3(x, 0.45, -2), Vector3(0.25, 0.9, 1.1), dark, true)
	Art.box(self, Vector3(-3.4, 1.08, -1.8), Vector3(0.75, 0.18, 0.5), dark)
	Art.cylinder(self, Vector3(-3.4, 1.2, -1.72), 0.18, 0.04, Art.material("b8ac85"))
	Art.box(self, Vector3(-3.4, 1.29, -1.97), Vector3(0.87, 0.14, 0.18), dark)
	Art.box(self, Vector3(-2.1, 1.025, -1.8), Vector3(0.75, 0.02, 0.48), Art.material("eddfb7"))
	for i: int in range(4):
		Art.box(self, Vector3(-2.1, 1.04, -1.97 + i * 0.1), Vector3(0.5, 0.01, 0.012), wood)
	Art.box(self, Vector3(-0.7, 1.14, -1.8), Vector3(0.73, 0.26, 0.48), Art.material("a77954"))
	for x: float in [-0.9, -0.5]:
		Art.cylinder(self, Vector3(x, 1.28, -1.8), 0.12, 0.03, dark)
	# Noticeboard, clock and locked supply cabinet: decor, never usable preparations.
	Art.box(self, Vector3(-2.6, 2.35, -3.65), Vector3(2.9, 1.2, 0.08), wood)
	for x: float in [-3.35, -2.55, -1.75]:
		Art.box(self, Vector3(x, 2.35, -3.58), Vector3(0.57, 0.85, 0.02), Art.material("e5dabc"))
	var clock := Art.cylinder(self, Vector3(0, 2.65, -3.6), 0.37, 0.09, dark)
	clock.rotation.x = PI / 2
	Art.box(self, Vector3(0, 2.77, -3.52), Vector3(0.025, 0.23, 0.02), plaster)
	Art.box(self, Vector3(0.1, 2.65, -3.52), Vector3(0.2, 0.025, 0.02), plaster)
	Art.box(self, Vector3(-4.35, 1, 0.75), Vector3(1.05, 2, 1.2), dark, true)
	Art.box(self, Vector3(-4.35, 1, 1.37), Vector3(0.8, 1.7, 0.04), Art.material("71867f"))
	Art.plant(self, Vector3(-4.3, 2, 0.75), 0.7)
	Art.box(self, Vector3(3.8, 0.5, 1.7), Vector3(1.6, 0.15, 0.8), wood, true)
	for x: float in [3.2, 4.4]:
		Art.box(self, Vector3(x, 0.25, 1.7), Vector3(0.1, 0.5, 0.65), dark)
	Art.box(self, Vector3(0, -0.3, -15), Vector3(50, 0.1, 22), Art.material("60868c"))
	waiting_child = Art.person(self, Vector3(2.8, 0, -4.7), "c8ad8a")
	waiting_child.scale = Vector3.ONE * 0.7
	escort = Art.person(self, Vector3(1.8, 0, -5.3), "7c9392", "bab3a1")
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("c4cebf")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("9bb6bd")
	environment.environment.ambient_light_energy = 0.45
	add_child(environment)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, -30, 0)
	sun.light_color = Color("ffe5be")
	sun.light_energy = 0.65
	sun.shadow_enabled = true
	add_child(sun)
	lamp = OmniLight3D.new()
	lamp.position = Vector3(-1, 2.8, -1)
	lamp.omni_range = 6
	lamp.light_energy = 0.35
	lamp.light_color = Color("ffe2a0")
	add_child(lamp)
	waiting_child.hide()
	escort.hide()


func sync_state(state: Dictionary) -> void:
	var historical: bool = state["phase"] in [Session.Phase.BEFORE_OUTAGE, Session.Phase.AFTER_OUTAGE, Session.Phase.OBSERVED]
	var observed: bool = historical and state["facts"].has(&"c2_window_closed")
	door.rotation.y = -1.4 if observed else 0.0
	waiting_child.visible = observed
	escort.visible = observed and state["facts"].get(&"c2_escort") == "keeper"
	if _phase != state["phase"]:
		_phase = state["phase"]
		sun.light_energy = 0.28 if historical else 0.65
		lamp.visible = state["phase"] not in [Session.Phase.AFTER_OUTAGE, Session.Phase.OBSERVED]
