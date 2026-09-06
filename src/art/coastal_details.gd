extends Node3D
## Original silhouette, foliage and water layers outside playable collision geometry.

const Art := preload("res://src/art/low_poly.gd")
var ripples: Array[MeshInstance3D] = []
var clock := 0.0


func _ready() -> void:
	var sea := Art.material("78a5a2")
	sea.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	Art.box(self, Vector3(0, -0.65, 0), Vector3(160, 0.1, 160), sea)
	var foam := Art.material("b3cfbe")
	foam.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for i: int in range(32):
		var at := Vector3(-22 + (i % 8) * 6.3, -0.57, -7 - (i / 8) * 4.1)
		var ripple := Art.box(self, at, Vector3(1.5 + i % 3, 0.02, 0.045), foam)
		ripple.set_meta("origin_x", at.x)
		ripples.append(ripple)
	for i: int in range(7):
		Art.sphere(self, Vector3(-14 + i * 5.5, -0.1, -23 - i % 3), Vector3(9, 2.5 + i % 2, 5), Art.material("93afa4"))
	for i: int in range(8):
		Art.sphere(self, Vector3(-5.4 - (i % 2) * 0.8, -0.1, -3 + i), Vector3(0.9, 0.7, 1.2), Art.material("84948a"))


func _process(delta: float) -> void:
	clock += delta
	for i: int in range(ripples.size()):
		var ripple := ripples[i]
		ripple.position.x = float(ripple.get_meta("origin_x")) + sin(clock * 0.35 + i) * 0.35


static func tree(parent: Node3D, at: Vector3, scale_factor: float = 1.0) -> void:
	var trunk := Node3D.new()
	trunk.position = at
	trunk.scale = Vector3.ONE * scale_factor
	parent.add_child(trunk)
	Art.cylinder(trunk, Vector3(0, 1.1, 0), 0.14, 2.2, Art.material("817457"), 0.08)
	for i: int in range(5):
		Art.sphere(trunk, Vector3(sin(i * 2.4) * 0.65, 2.1 + i * 0.16, cos(i * 2.4) * 0.6), Vector3(1.6, 1.4, 1.5), Art.material("8da980" if i % 2 else "a4b990"))


static func window(parent: Node3D, at: Vector3) -> void:
	Art.box(parent, at, Vector3(2.2, 1.8, 0.12), Art.material("728f88"))
	Art.box(parent, at + Vector3(0, 0, 0.08), Vector3(1.95, 1.55, 0.02), Art.material("b9d6c5"))
	Art.box(parent, at + Vector3(0, 0, 0.11), Vector3(0.07, 1.7, 0.05), Art.material("eee2bd"))
	Art.box(parent, at + Vector3(0, 0, 0.11), Vector3(2.1, 0.06, 0.05), Art.material("eee2bd"))
	for x: float in [-1.1, 1.1]:
		Art.box(parent, at + Vector3(x, 0, 0.12), Vector3(0.3, 1.9, 0.08), Art.material("d7c6a1"))
