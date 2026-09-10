extends "res://src/art/arc_stage.gd"
## Chapter five: a sealed archive, a telephone, two retained reports and a family table.

var seal: MeshInstance3D
var correction: MeshInstance3D


func _ready() -> void:
	foundation("aa9c82", "71858a")
	# A tiled shop, stocked shelves and a striped shopfront distinguish the night interior.
	for x: int in range(10):
		for z: int in range(8):
			Art.box(self, Vector3(-4.5 + x, 0.03, -3.3 + z * 0.94), Vector3(0.97, 0.025, 0.91), Art.material("b8bba5" if (x + z) % 2 else "8e9e92"))
	Details.window(self, Vector3(-3.1, 2.1, -3.65))
	for i: int in range(10):
		Art.box(self, Vector3(-4.5 + i, 3.3, -3.1), Vector3(1, 0.13, 1.3), Art.material("b58167" if i % 2 else "e5d5b0"))
	Art.box(self, Vector3(0, 2.5, -3.65), Vector3(1.7, 0.65, 0.08), Art.material("718c80"))
	for i: int in range(5):
		Art.cylinder(self, Vector3(-4.65, 0.3, -1.4 + i * 0.35), 0.12, 0.55, Art.material("c7a770"))
	sun.light_energy = 0.2
	for x: float in [-3.2, 0, 3.2]:
		desk(Vector3(x, 0, -2.6))
	Art.box(self, Vector3(-3.2, 1, -2.6), Vector3(1.1, 0.16, 0.65), Art.material("a38963"))
	seal = Art.box(self, Vector3(-3.2, 1.1, -2.6), Vector3(0.16, 0.02, 0.65), Art.material("b76552"))
	Art.box(self, Vector3(0, 1.02, -2.6), Vector3(0.8, 0.2, 0.5), Art.material("486164"))
	Art.box(self, Vector3(0, 1.18, -2.7), Vector3(0.9, 0.12, 0.16), Art.material("36494c"))
	notice(Vector3(3.2, 2, -3.65), 1)
	correction = Art.box(self, Vector3(3.55, 2, -3.58), Vector3(0.55, 0.83, 0.02), Art.material("d2e0cc"))
	desk(Vector3(4.15, 0, 0.7), 1.0)
	for z: float in [0.45, 0.95]:
		Art.cylinder(self, Vector3(4.15, 0.98, z), 0.18, 0.13, Art.material("eadfc2"), 0.23)
	var shiori := Art.person(self, Vector3(4.3, 0, 1.9), "b69078")
	Appearance.apply(shiori, &"shiori")
	var xu := Art.person(self, Vector3(4.3, 0, -0.5), "8fa68a", "807467")
	xu.set_meta("actor_id", &"xu")
	Appearance.apply(xu, &"xu")
	for y: float in [0.7, 1.5, 2.3]:
		Art.box(self, Vector3(-4.65, y, 0.2), Vector3(0.6, 0.1, 2.4), Art.material("796850"), true)
		for z: float in [-0.6, 0, 0.6]:
			Art.box(self, Vector3(-4.65, y + 0.25, z), Vector3(0.35, 0.4, 0.3), Art.material("adbe98"))
	lamp(Vector3(-2.5, 2.8, -1.5))
	lamp(Vector3(3.5, 2.8, 0.5))
	exit_mat()


func sync_state(state: Dictionary) -> void:
	var f: Dictionary = state["facts"]
	seal.visible = f.get(&"identity_sealed", false)
	correction.visible = f.has(&"report_correction")
