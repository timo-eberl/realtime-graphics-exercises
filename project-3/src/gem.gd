@tool
extends MeshInstance3D

@export var generate_button : bool:
	set(value):
		self.mesh = gen_mesh()

@export_range(1,50) var segments := 8
@export var radius := 0.5

func _ready():
	self.mesh = gen_mesh()

func gen_mesh() -> Mesh:
	var mesh := ArrayMesh.new()
	MeshGeneration.add_gem_to_mesh(mesh, segments, radius)
	return mesh
