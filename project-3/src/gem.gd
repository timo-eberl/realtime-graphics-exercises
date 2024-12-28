@tool
extends MeshInstance3D

@export var generate_button : bool:
	set(value):
		self.mesh = gen_mesh()

@export_range(1,50) var segments := 8
@export var radius := 0.5
@export_range(0.0,1.0) var center_size := 0.5

func _ready():
	self.mesh = gen_mesh()

func gen_mesh() -> Mesh:
	var m := ArrayMesh.new()
	MeshGeneration.add_gem_to_mesh(m, segments, radius, center_size)
	return m
