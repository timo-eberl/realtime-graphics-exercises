@tool
class_name SDF
extends MeshInstance3D

@onready var sun : DirectionalLight3D = %Sun

@export_range(0,1) var morph_progress := 0.0

func _process(_delta: float) -> void:
	var mat : ShaderMaterial = self.material_override
	mat.set_shader_parameter("sun_direction", sun.global_basis * -Vector3.FORWARD)
	mat.set_shader_parameter("morph_progress", morph_progress)
