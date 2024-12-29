@tool
extends MeshInstance3D

@export var generate_button : bool:
	set(value):
		update_crown()

@export_group("General")
@export var radius: float = 0.5
@export_range(1,50) var tip_count := 8
@export_range(0.0,2.0) var tip_height := 0.4
@export_range(0,90) var tip_bend_angle := 15
@export var tube_radius: float = 0.02

@export_group("Gems")
@export var gem_top: PackedScene
@export var gem_middle: PackedScene
@export var gem_lower: PackedScene

@export_group("Materials")
@export var metal_material: Material
@export var gem_material: Material

@export_group("Tip Curves")
@export var path : Path2D
@export var curve_flat_ring : Curve

@export_group("Subdivision")
@export var tube_segments: int = 16
@export var tips_radial_segments: int = 1024
@export var ring_radial_segments: int = 64

@onready var gems_top_container : Node3D = $GemsTop
@onready var gems_middle_container : Node3D = $GemsMiddle
@onready var gems_bottom_container : Node3D = $GemsBottom

var curved_tube_height_offset := 0.125
var second_ring_height_offset := 0.1
var gem_top_offset := 0.03

func _ready():
	update_crown()

func update_crown():
	self.mesh = gen_mesh()
	spawn_gems_top()

func spawn_gems_top():
	# delete existing nodes
	for node : Node in gems_top_container.get_children():
		gems_top_container.remove_child(node)
		node.queue_free()
	
	for i in tip_count:
		var theta := (float(i) / tip_count) * TAU
		var m := Transform3D.IDENTITY \
			.translated(Vector3(0, tip_height + 0.03, 0)) \
			.rotated(Vector3(0,0,-1), deg_to_rad(tip_bend_angle)) \
			.translated(Vector3(radius, 0, 0)) \
			.rotated(Vector3(0,1,0), theta) \
			.translated(Vector3(0, curved_tube_height_offset, 0))
		
		var gem_node : MeshInstance3D = gem_top.instantiate()
		gem_node.name = "Gem" + str(i)
		gems_top_container.add_child(gem_node)
		gem_node.owner = get_tree().edited_scene_root
		gem_node.transform = m * gem_node.transform
		gem_node.material_override = gem_material

func gen_mesh() -> Mesh:
	var m := ArrayMesh.new()
	MeshGeneration.add_mirrored_curve_ring_to_mesh(
		m, path.curve, radius, tube_radius, tips_radial_segments, tube_segments,
		tip_count, tip_height, deg_to_rad(tip_bend_angle), curved_tube_height_offset
	)
	m.surface_set_material(m.get_surface_count()-1, metal_material)
	MeshGeneration.add_torus_to_mesh(m, radius, tube_radius, ring_radial_segments, tube_segments,  second_ring_height_offset)
	m.surface_set_material(m.get_surface_count()-1, metal_material)
	MeshGeneration.add_torus_to_mesh(m, radius, tube_radius, ring_radial_segments, tube_segments, 0)
	m.surface_set_material(m.get_surface_count()-1, metal_material)
	#MeshGeneration.add_flat_ring_to_mesh(m, radius, ring_radial_segments, second_ring_height_offset, false, 0)
	MeshGeneration.add_curve_limited_flat_ring_to_mesh(m, curve_flat_ring, radius, ring_radial_segments, false, tip_count, 0)
	m.surface_set_material(m.get_surface_count()-1, metal_material)
	#MeshGeneration.add_flat_ring_to_mesh(m, radius, ring_radial_segments, second_ring_height_offset, true, 0)
	MeshGeneration.add_curve_limited_flat_ring_to_mesh(m, curve_flat_ring, radius, ring_radial_segments, true, tip_count, 0)
	m.surface_set_material(m.get_surface_count()-1, metal_material)
	return m
