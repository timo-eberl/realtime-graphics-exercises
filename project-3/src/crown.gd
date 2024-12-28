@tool
extends MeshInstance3D

@export var generate_button : bool:
	set(value):
		self.mesh = gen_mesh()
@export_range(1,50) var tip_count := 8
@export_range(0.0,2.0) var tip_height := 0.4
@export var path : Path2D

@export var radius: float = 0.5
@export var tube_radius: float = 0.02
@export var tube_segments: int = 16

@export var tips_radial_segments: int = 1024
@export var torus_radial_segments: int = 64

func _ready():
	self.mesh = gen_mesh()

func gen_mesh() -> Mesh:
	var mesh := ArrayMesh.new()
	MeshGeneration.add_mirrored_curve_ring_to_mesh(
		mesh, path.curve, radius, tube_radius, tips_radial_segments, tube_segments, tip_count, tip_height, 0.125
	)
	MeshGeneration.add_torus_to_mesh(mesh, radius, tube_radius, torus_radial_segments, tube_segments,  0.1)
	MeshGeneration.add_torus_to_mesh(mesh, radius, tube_radius, torus_radial_segments, tube_segments,  0)
	return mesh
