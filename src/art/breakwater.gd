extends "res://src/art/arc_stage.gd"
## Chapter four staging. The far platform stays screened; no unconfirmed person or fate is drawn.

var backup: OmniLight3D
var ladder: Node3D
var indicator: MeshInstance3D
var lighthouse_roof: MeshInstance3D


func _ready() -> void:
	foundation("8c9d9a", "abbac0", false)
	# Concrete joints, tide stains and a distant lighthouse give the pier its own silhouette.
	for z: float in [-2.4, -0.8, 0.8, 2.4]:
		Art.box(self, Vector3(0, 0.028, z), Vector3(9.8, 0.01, 0.025), Art.material("687f7e"))
	Art.box(self, Vector3(0, -0.36, 0), Vector3(10.2, 0.3, 7.9), Art.material("658780"))
	Art.sphere(self, Vector3(-4.8, -0.4, -5.4), Vector3(2.2, 0.5, 2), Art.material("84948a"))
	Art.cylinder(self, Vector3(-4.8, 0.45, -5.4), 0.5, 1.8, Art.material("ded8ba"), 0.35)
	Art.cylinder(self, Vector3(-4.8, 1.5, -5.4), 0.4, 0.3, Art.material("798f89"))
	lighthouse_roof = Art.cylinder(self, Vector3(-4.8, 1.8, -5.4), 0.5, 0.3, Art.material("a57860"), 0.08)
	for x: float in [-4.4, 4.4]:
		Art.cylinder(self, Vector3(x, 0.25, 2.8), 0.18, 0.5, Art.material("586f72"))
	var metal := Art.material("4b6367")
	for x: float in [-4.7, -2.2, 0.3, 2.8, 4.7]:
		Art.cylinder(self, Vector3(x, 0.5, -3.5), 0.06, 1.0, metal)
	Art.box(self, Vector3(0, 0.9, -3.5), Vector3(9.5, 0.06, 0.06), metal)
	# Opaque sea wall keeps a free camera/player from observing the narrative's unseen platform.
	Art.box(self, Vector3(1.4, 0.6, -3), Vector3(6.8, 1.2, 0.3), Art.material("9daaa2"), true)
	Art.box(self, Vector3(-3.2, 0.85, -2.6), Vector3(1.2, 1.7, 0.7), metal, true)
	Art.box(self, Vector3(-3.2, 0.85, -2.23), Vector3(1, 1.45, 0.02), Art.material("7b9c90"))
	indicator = Art.sphere(self, Vector3(-3.2, 1.4, -2.19), Vector3.ONE * 0.14, Art.material("374947"))
	backup = lamp(Vector3(-3.2, 2.8, -2.6))
	Art.cylinder(self, Vector3(-3.2, 1.4, -2.8), 0.05, 2.8, metal)
	ladder = Node3D.new()
	ladder.position = Vector3(0, 1.8, -2.7)
	add_child(ladder)
	for x: float in [-0.4, 0.4]:
		Art.box(ladder, Vector3(x, 0.65, 0), Vector3(0.07, 1.3, 0.07), metal)
	for i: int in range(5):
		Art.box(ladder, Vector3(0, 0.15 + i * 0.25, 0), Vector3(0.8, 0.06, 0.08), metal)
	Art.box(self, Vector3(0, 0.65, -2.7), Vector3(0.55, 0.12, 0.3), Art.material("d9ad62"))
	# Observation point is a covered chart stand, not an always-visible alternative history.
	desk(Vector3(3.2, 0, -2.6), 1.3)
	paper(Vector3(3.2, 0.94, -2.6), "ced4c5")
	Art.box(self, Vector3(4.2, 0.3, 0.7), Vector3(0.7, 0.6, 0.7), metal, true)
	Art.cylinder(self, Vector3(4.2, 0.65, 0.7), 0.22, 0.1, Art.material("c1ad83"))
	exit_mat()


func sync_state(state: Dictionary) -> void:
	var f: Dictionary = state["facts"]
	var historical: bool = f.has(&"c4_entered") and not f.has(&"c4_closed")
	backup.visible = historical and f.get(&"backup_connected", false)
	indicator.material_override = Art.material("e8cf7a" if backup.visible else "374947")
	ladder.rotation.x = PI if historical and f.get(&"ladder_lowered", false) else 0.0
	sun.light_energy = 0.25 if historical and f.has(&"c4_boarding") else 0.65
