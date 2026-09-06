extends "res://src/art/arc_stage.gd"
## Chapter six: a memorial, tripod and departing bus. No sister spawned from an invitation.

var shiori: Node3D
var inscription: MeshInstance3D


func _ready() -> void:
	foundation("c9bda0", "e0ddbf", false)
	Art.box(self, Vector3(-3.2, 0.8, -2.7), Vector3(1.5, 1.6, 0.35), Art.material("788d86"), true)
	inscription = Art.box(self, Vector3(-3.2, 0.8, -2.5), Vector3(1.05, 0.55, 0.02), Art.material("ece0bb"))
	Art.plant(self, Vector3(-4.3, 0, -2.7), 0.8)
	var metal := Art.material("526766")
	for x: float in [-0.3, 0, 0.3]:
		var leg := Art.cylinder(self, Vector3(x, 0.65, -2.7), 0.035, 1.3, metal)
		leg.rotation.z = x * 0.5
	Art.box(self, Vector3(0, 1.4, -2.7), Vector3(0.5, 0.3, 0.25), metal)
	var lens := Art.cylinder(self, Vector3(0, 1.4, -2.5), 0.1, 0.2, Art.material("263e42"))
	lens.rotation.x = PI / 2
	shiori = Art.person(self, Vector3(1.2, 0, -2.7), "b69078")
	# Bus is beyond the navigable slab; doors and wheels are decorative.
	Art.box(self, Vector3(3.5, 1.2, -4.6), Vector3(3, 1.8, 1.5), Art.material("bda666"))
	Art.box(self, Vector3(3.5, 1.55, -3.83), Vector3(2.6, 0.6, 0.03), Art.material("65888c"))
	for x: float in [2.5, 4.5]:
		var wheel := Art.cylinder(self, Vector3(x, 0.35, -4), 0.35, 0.2, metal)
		wheel.rotation.x = PI / 2
	Art.cylinder(self, Vector3(4.2, 1.1, 0.7), 0.05, 2.2, metal)
	Art.box(self, Vector3(4.2, 2.1, 0.7), Vector3(0.65, 0.55, 0.08), Art.material("859d8b"))
	desk(Vector3(-2.4, 0, 1.9), 2.4)
	Art.plant(self, Vector3(-4.5, 0, 2.4), 1.6)


func sync_state(state: Dictionary) -> void:
	var f: Dictionary = state["facts"]
	shiori.visible = f.get(&"shiori_boundary_respected", false)
	inscription.visible = f.has(&"memorial_wording")
