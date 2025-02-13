@tool
extends MeshInstance3D

func _process(_delta: float) -> void:
	var mat : ShaderMaterial = self.material_override
	var sun : Node3D = %FakeSun
	mat.set_shader_parameter("light_position_world", sun.global_position)
