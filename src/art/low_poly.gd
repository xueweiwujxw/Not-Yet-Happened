extends RefCounted
## Original code-native art primitives. No downloaded models or runtime art dependencies.

static func material(color: String) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = Color(color)
	result.roughness = 0.88
	return result


static func box(parent: Node3D, at: Vector3, size: Vector3, mat: Material, solid: bool = false) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var item := _mesh(parent, at, mesh, mat)
	if solid:
		var shape := BoxShape3D.new()
		shape.size = size
		_collider(parent, at, shape)
	return item


static func cylinder(parent: Node3D, at: Vector3, radius: float, height: float, mat: Material, top: float = -1.0) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = radius
	mesh.top_radius = radius if top < 0.0 else top
	mesh.height = height
	mesh.radial_segments = 12
	return _mesh(parent, at, mesh, mat)


static func sphere(parent: Node3D, at: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radial_segments = 10
	mesh.rings = 5
	var item := _mesh(parent, at, mesh, mat)
	item.scale = size
	return item


static func _mesh(parent: Node3D, at: Vector3, mesh: Mesh, mat: Material) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	item.mesh = mesh
	item.material_override = mat
	item.position = at
	parent.add_child(item)
	return item


static func _collider(parent: Node3D, at: Vector3, shape: Shape3D) -> void:
	var body := StaticBody3D.new()
	body.position = at
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	parent.add_child(body)


static func plant(parent: Node3D, at: Vector3, scale_factor: float = 1.0) -> void:
	var pot := Node3D.new()
	pot.position = at
	pot.scale = Vector3.ONE * scale_factor
	parent.add_child(pot)
	cylinder(pot, Vector3(0, 0.15, 0), 0.16, 0.3, material("b7694e"), 0.22)
	cylinder(pot, Vector3(0, 0.31, 0), 0.19, 0.015, material("554a3c"))
	var green := material("64856d")
	for i: int in range(7):
		var angle := float(i) * TAU / 7.0
		var leaf := sphere(pot, Vector3(sin(angle) * 0.18, 0.48 + float(i % 3) * 0.07, cos(angle) * 0.18), Vector3(0.2, 0.42, 0.13), green)
		leaf.rotation = Vector3(0.4, angle, 0.45)


static func person(parent: Node3D, at: Vector3, shirt: String, hair_color: String = "41433e") -> Node3D:
	var person := Node3D.new()
	person.position = at
	parent.add_child(person)
	var skin := material("dcaf88")
	var cloth := material(shirt)
	var trousers := material("4e6668")
	for x: float in [-0.14, 0.14]:
		box(person, Vector3(x, 0.3, 0), Vector3(0.19, 0.58, 0.22), trousers)
		box(person, Vector3(x, 0.07, 0.075), Vector3(0.23, 0.13, 0.36), material("e8d8b7"))
	cylinder(person, Vector3(0, 0.85, 0), 0.3, 0.63, cloth, 0.24)
	for x: float in [-0.34, 0.34]:
		box(person, Vector3(x, 0.88, 0), Vector3(0.17, 0.39, 0.23), cloth)
		sphere(person, Vector3(x, 0.6, 0), Vector3(0.17, 0.19, 0.18), skin)
	sphere(person, Vector3(0, 1.38, 0), Vector3(0.53, 0.57, 0.48), skin)
	sphere(person, Vector3(0, 1.55, -0.035), Vector3(0.57, 0.32, 0.5), material(hair_color))
	for x: float in [-0.105, 0.105]:
		sphere(person, Vector3(x, 1.4, 0.226), Vector3(0.035, 0.045, 0.025), material("443e38"))
	return person
