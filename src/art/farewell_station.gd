extends "res://src/art/arc_stage.gd"
## Chapter six: a memorial, tripod and departing bus. No sister spawned from an invitation.

var shiori: Node3D
var inscription: MeshInstance3D


func _ready() -> void:
	foundation("c9bda0", "e0ddbf", false)
	Art.box(self, Vector3(0, -0.35, -1.5), Vector3(12, 0.4, 12), Art.material("b9b49b"))
	Art.box(self, Vector3(0, -0.1, -5.8), Vector3(26, 0.05, 3.5), Art.material("84908a"))
	for x: int in range(9):
		Art.box(self, Vector3(-12 + x * 3, -0.06, -6.5), Vector3(1.5, 0.015, 0.1), Art.material("e6d6ab"))
	Details.tree(self, Vector3(-5.7, 0, -2.8), 1.0)
	Details.tree(self, Vector3(-6.0, 0, 3.0), 0.8)
	# Open waiting shelter, luggage and slatted bench, with no new narrative evidence.
	for x: float in [-4, -1]:
		Art.cylinder(self, Vector3(x, 1.35, 2.65), 0.05, 2.7, Art.material("667f76"))
	Art.box(self, Vector3(-2.5, 2.75, 2.5), Vector3(3.4, 0.14, 1.3), Art.material("8ca48a"))
	Art.box(self, Vector3(3.8, 0.25, 1.7), Vector3(0.55, 0.5, 0.32), Art.material("a48362"))
	Art.box(self, Vector3(3.8, 0.53, 1.7), Vector3(0.2, 0.07, 0.08), Art.material("5e6555"))
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
	shiori.set_meta("actor_id", &"shiori")
	# Bus is beyond the navigable slab; doors and wheels are decorative.
	Art.box(self, Vector3(3.5, 1.2, -4.6), Vector3(3, 1.8, 1.5), Art.material("bda666"))
	Art.box(self, Vector3(3.5, 1.55, -3.83), Vector3(2.6, 0.6, 0.03), Art.material("65888c"))
	for x: float in [2.5, 3.2, 3.9]:
		Art.box(self, Vector3(x, 1.55, -3.8), Vector3(0.05, 0.65, 0.05), Art.material("e5d8a6"))
	Art.box(self, Vector3(4.75, 1.15, -3.8), Vector3(0.38, 1.6, 0.04), Art.material("6e8987"))
	Art.box(self, Vector3(3.5, 0.65, -3.79), Vector3(2.9, 0.1, 0.04), Art.material("eee0ba"))
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
