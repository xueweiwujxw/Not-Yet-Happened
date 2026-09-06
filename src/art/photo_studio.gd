extends "res://src/art/arc_stage.gd"
## Chapter three: evidence workspace, with no legible invented identity in the photos.

var shiori: Node3D


func _ready() -> void:
	foundation("c9b992", "dce0c9")
	for x: float in [-3.2, 0, 3.2]:
		desk(Vector3(x, 0, -2.6))
	paper(Vector3(-3.2, 0.94, -2.6))
	Art.box(self, Vector3(0, 1, -2.6), Vector3(1.5, 0.15, 0.65), Art.material("536665"))
	paper(Vector3(0, 1.1, -2.6), "c2d4cb")
	for x: float in [-0.5, 0.5]:
		Art.box(self, Vector3(x, 2.2, -3.65), Vector3(0.75, 0.95, 0.05), Art.material("536665"))
		Art.box(self, Vector3(x, 2.2, -3.61), Vector3(0.62, 0.8, 0.01), Art.material("bec9c0"))
	notice(Vector3(3.1, 2, -3.65))
	paper(Vector3(3.2, 0.94, -2.6))
	desk(Vector3(-4.1, 0, 0.7), 1.0)
	paper(Vector3(-4.1, 0.94, 0.7), "c3d4cb")
	Art.person(self, Vector3(4.2, 0, -2.8), "7c9392", "bab3a1")
	shiori = Art.person(self, Vector3(4.2, 0, 0.7), "b69078")
	Art.plant(self, Vector3(-4.5, 0, 2), 1.2)
	lamp(Vector3(-2, 2.8, -2))
	exit_mat()


func sync_state(state: Dictionary) -> void:
	var facts: Dictionary = state["facts"]
	shiori.visible = not facts.has(&"shiori_boundary_respected") or facts[&"shiori_boundary_respected"]
