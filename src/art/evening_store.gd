extends "res://src/art/arc_stage.gd"
## Chapter five: a sealed archive, a telephone, two retained reports and a family table.

var seal: MeshInstance3D
var correction: MeshInstance3D


func _ready() -> void:
	foundation("aa9c82", "71858a")
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
	Art.person(self, Vector3(4.3, 0, 1.9), "b69078")
	Art.person(self, Vector3(4.3, 0, -0.5), "8fa68a", "807467")
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
