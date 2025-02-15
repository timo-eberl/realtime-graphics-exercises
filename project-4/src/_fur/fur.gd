@tool
extends MeshInstance3D

@export_group("Setup")
@export var shell_mesh: Mesh
@export var shell_material: ShaderMaterial
@export_range(1, 256) var shell_count: int = 16 # 256 is the max number of possible mesh surfaces
@export var setup_button: bool:
	set(value):
		setup()
	get():
		return false

@export_category("Fur")
@export_range(0, 1) var length: float = 0.15
@export_range(0, 1) var length_uniformity: float = 0.0
@export_range(0.01, 3) var distance_shell_density_attenuation: float = 1
@export_range(1, 1000) var density: float = 100
@export_range(0, 10) var thickness: float = 5
@export_range(0, 0.999) var strand_roundness: float = 0
@export_category("Shading")
@export_color_no_alpha var color: Color
@export_range(0, 5) var occlusion_attenuation: float = 1
@export_category("Physics")
@export_range(0, 1) var displacement_strength: float = 0.1
@export_range(0, 10) var curvature: float = 1
@export var max_displacement := 3.0
@export var max_rotation_displacement_degrees := 30
@export var inertia := 1.0
@export var displacement_vector := Vector3.ZERO
@export var rotation_displacement_global := Quaternion.IDENTITY
@export var rotation_displacement_local := Quaternion.IDENTITY

@onready var old_pos: Vector3 = self.global_position
@onready var old_rot: Quaternion = Quaternion(self.global_basis.orthonormalized())

func _ready() -> void:
	setup()

func setup() -> void:
	# generate mesh that has one surface for every shell
	var mdt := MeshDataTool.new()
	var array_mesh := ArrayMesh.new()
	if shell_mesh is PrimitiveMesh:
		# mesh is of type PrimitiveMesh -> convert to ArrayMesh
		array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, shell_mesh.get_mesh_arrays())
	elif shell_mesh is ArrayMesh:
		array_mesh = shell_mesh
	else:
		printerr("no mesh or unknown mesh type")
		return
	mdt.create_from_surface(array_mesh, 0)
	var multi_surface_mesh: ArrayMesh = ArrayMesh.new()
	for i in shell_count:
		mdt.commit_to_surface(multi_surface_mesh)
	self.mesh = multi_surface_mesh
	
	# set a different material for every shell
	for i in shell_count:
		var mat_duplicate : ShaderMaterial = shell_material.duplicate()
		self.set_surface_override_material(i, mat_duplicate)
	
	# disable shadows
	self.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# we move the vertices outwards in the vertex shader, so we have to increase the cull margin
	self.extra_cull_margin = 2
	
	update_materials()

func update_materials() -> void:
	for i in self.get_surface_override_material_count():
		var mat: ShaderMaterial = self.get_surface_override_material(i)
		mat.set_shader_parameter("u_shell_index", i)
		mat.set_shader_parameter("u_shell_count", shell_count)
		mat.set_shader_parameter("u_length", length)
		mat.set_shader_parameter("u_length_uniformity", length_uniformity)
		mat.set_shader_parameter("u_distance_shell_density_attenuation", distance_shell_density_attenuation)
		mat.set_shader_parameter("u_density", density)
		mat.set_shader_parameter("u_thickness", thickness)
		mat.set_shader_parameter("u_strand_roundness", strand_roundness)
		mat.set_shader_parameter("u_color", color)
		mat.set_shader_parameter("u_occlusion_attenuation", occlusion_attenuation)
		mat.set_shader_parameter("u_displacement_strength", displacement_strength)
		mat.set_shader_parameter("u_curvature", curvature)
		mat.set_shader_parameter("u_displacement_vector", displacement_vector)
		mat.set_shader_parameter("u_rotation_displacement", Basis(rotation_displacement_local))

func _process(_delta: float) -> void:
	update_materials()

func _physics_process(delta: float) -> void:
	var global_scale_vec := self.global_transform.basis.get_scale()
	var global_scale_avg := (global_scale_vec.x + global_scale_vec.y + global_scale_vec.z) / 3.0
	
	var pos_change = self.global_position - old_pos
	old_pos = self.global_position
	# add force resulting from translation
	displacement_vector -= pos_change * (5 / inertia)
	# add force resulting from gravity
	var gravity := Vector3(0,-10,0)
	# we lerp so it looks more smooth
	displacement_vector = lerp(displacement_vector, gravity, delta * global_scale_avg / inertia)
	
	# limit displacement to avoid clipping
	if (displacement_vector.length() > (max_displacement * global_scale_avg)):
		displacement_vector = displacement_vector.normalized() * (max_displacement * global_scale_avg)
	
	var curr_rot := Quaternion(self.global_basis.orthonormalized())
	# calculate the difference in rotation
	var rot_change = curr_rot * old_rot.inverse()
	old_rot = curr_rot
	
	# "subtract" the rotation change
	rotation_displacement_global = rot_change.inverse() * rotation_displacement_global
	var rotation_neutral_global := curr_rot * Quaternion.IDENTITY
	
	rotation_displacement_global = rotation_displacement_global.slerp(rotation_neutral_global, delta * 6.0 / inertia)
	# convert to local space
	rotation_displacement_local = curr_rot.inverse() * rotation_displacement_global
	
	# limit displacement to avoid clipping
	var angle := rotation_displacement_local.get_angle()
	var angle_amount = abs(angle - TAU if angle > PI else angle)
	var angle_max := max_rotation_displacement_degrees * (PI/180)
	if angle_amount > angle_max:
		var scale_factor = angle_max / angle_amount
		rotation_displacement_local = Quaternion(rotation_displacement_local.get_axis(), angle * scale_factor)
		rotation_displacement_global = curr_rot * rotation_displacement_local
	
