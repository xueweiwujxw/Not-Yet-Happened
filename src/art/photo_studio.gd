extends "res://src/art/arc_stage.gd"
## Chapter three: evidence workspace, with no legible invented identity in the photos.

var shiori: Node3D


func _ready() -> void:
	foundation("c9b992", "dce0c9")
	Details.window(self, Vector3(-3.15, 2.15, -3.65))
	# The studio has a fabric work mat, photo drying line, books and a darkroom curtain.
	Art.box(self, Vector3(0, 0.045, 0), Vector3(3.9, 0.025, 2.8), Art.material("a8b9a0"))
	for z: float in [-1.3, 1.3]:
		Art.box(self, Vector3(0, 0.061, z), Vector3(3.7, 0.01, 0.05), Art.material("ddcfac"))
	for i: int in range(5):
		Art.box(self, Vector3(-4.8, 1.1 + i * 0.17, -1.3), Vector3(0.3, 0.12, 0.6), Art.material("9b7d61" if i % 2 else "809d94"))
	Art.box(self, Vector3(-4.75, 1, -1.3), Vector3(0.5, 0.08, 0.85), Art.material("97785c"))
	Art.box(self, Vector3(-4.83, 1.6, 2.5), Vector3(0.06, 2.9, 1.4), Art.material("b88771"))
	for i: int in range(6):
		Art.box(self, Vector3(-4.77, 1.6, 1.85 + i * 0.23), Vector3(0.05, 2.9, 0.07), Art.material("ac7b68"))
	Art.box(self, Vector3(0, 2.95, -3.5), Vector3(2.7, 0.018, 0.02), Art.material("665c4b"))
	for i: int in range(4):
		Art.box(self, Vector3(-1.05 + i * 0.7, 2.74, -3.5), Vector3(0.43, 0.38, 0.02), Art.material("e9dcbb"))
	for x: float in [-3.2, 0, 3.2]:
		desk(Vector3(x, 0, -2.6))
	paper(Vector3(-3.2, 0.94, -2.6))
	Art.box(self, Vector3(0, 1, -2.6), Vector3(1.5, 0.15, 0.65), Art.material("536665"))
	paper(Vector3(0, 1.1, -2.6), "c2d4cb")
	var scan_material := Art.material("d6efd8")
	scan_material.emission_enabled = true
	scan_material.emission = Color("91cdb5")
	var scan := Art.box(self, Vector3(0, 1.13, -2.6), Vector3(1.15, 0.015, 0.025), scan_material)
	scan.set_meta("performance_id", &"scanner")
	scan.hide()
	for x: float in [-0.5, 0.5]:
		Art.box(self, Vector3(x, 2.2, -3.65), Vector3(0.75, 0.95, 0.05), Art.material("536665"))
		Art.box(self, Vector3(x, 2.2, -3.61), Vector3(0.62, 0.8, 0.01), Art.material("bec9c0"))
	notice(Vector3(3.1, 2, -3.65))
	paper(Vector3(3.2, 0.94, -2.6))
	desk(Vector3(-4.1, 0, 0.7), 1.0)
	paper(Vector3(-4.1, 0.94, 0.7), "c3d4cb")
	var shen := Art.person(self, Vector3(4.2, 0, -2.8), "7c9392", "bab3a1")
	shen.set_meta("actor_id", &"shen")
	Appearance.apply(shen, &"shen")
	shiori = Art.person(self, Vector3(4.2, 0, 0.7), "b69078")
	shiori.set_meta("actor_id", &"shiori")
	Appearance.apply(shiori, &"shiori")
	Art.plant(self, Vector3(-4.5, 0, 2), 1.2)
	lamp(Vector3(-2, 2.8, -2))
	exit_mat()


func sync_state(state: Dictionary) -> void:
	var facts: Dictionary = state["facts"]
	shiori.visible = not facts.has(&"shiori_boundary_respected") or facts[&"shiori_boundary_respected"]
