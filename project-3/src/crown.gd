@tool
extends MeshInstance3D

@export var generate_button : bool:
	set(value):
		self.mesh = gen_mesh()

@export_range(1,50) var tip_count := 8
@export_range(0,90) var tip_bend_angle := 15
@export_range(0.0,2.0) var tip_height := 0.4
@export var path : Path2D
@export var curve_flat_ring : Curve

@export var radius: float = 0.5
@export var tube_radius: float = 0.02
@export var tube_segments: int = 16

@export var tips_radial_segments: int = 1024
@export var ring_radial_segments: int = 64

func _ready():
	self.mesh = gen_mesh()

func gen_mesh() -> Mesh:
	var m := ArrayMesh.new()
	MeshGeneration.add_mirrored_curve_ring_to_mesh(
		m, path.curve, radius, tube_radius, tips_radial_segments, tube_segments,
		tip_count, tip_height, deg_to_rad(tip_bend_angle), 0.125
	)
	MeshGeneration.add_torus_to_mesh(m, radius, tube_radius, ring_radial_segments, tube_segments,  0.1)
	MeshGeneration.add_torus_to_mesh(m, radius, tube_radius, ring_radial_segments, tube_segments,  0)
	#MeshGeneration.add_flat_ring_to_mesh(m, radius, ring_radial_segments, 0.1, false, 0)
	#MeshGeneration.add_flat_ring_to_mesh(m, radius, ring_radial_segments, 0.1, true, 0)
	MeshGeneration.add_curve_limited_flat_ring_to_mesh(m, curve_flat_ring, radius, ring_radial_segments, true, tip_count, 0)
	MeshGeneration.add_curve_limited_flat_ring_to_mesh(m, curve_flat_ring, radius, ring_radial_segments, false, tip_count, 0)
	return m
