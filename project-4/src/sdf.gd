@tool
class_name SDF
extends MeshInstance3D

@export_range(0,1) var morph_progress := 0.0

func _process(_delta: float) -> void:
	var mat : ShaderMaterial = self.material_override
	mat.set_shader_parameter("morph_progress", morph_progress)
