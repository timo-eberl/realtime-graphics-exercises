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
@export_range(0, 3) var distance_shell_density_attenuation: float = 1
@export_range(1, 1000) var density: float = 100
@export_range(0, 10) var thickness: float = 5
@export_range(0, 0.999) var strand_roundness: float = 0
@export_category("Shading")
@export_color_no_alpha var color: Color
@export_range(0, 5) var occlusion_attenuation: float = 1

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

func _process(_delta: float) -> void:
	update_materials()
