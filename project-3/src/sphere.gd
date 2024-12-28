@tool
extends MeshInstance3D

@export_range(0,5) var subdivision_levels := 1:
	set(value):
		subdivision_levels = value
		self.mesh = gen_mesh()

func _ready():
	self.mesh = gen_mesh()

func gen_mesh() -> Mesh:
	var mesh := ArrayMesh.new()
	MeshGeneration.add_subdivided_sphere_to_mesh(mesh, subdivision_levels)
	return mesh
