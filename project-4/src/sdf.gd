@tool
extends MeshInstance3D

@onready var sun : DirectionalLight3D = %Sun

func _process(_delta: float) -> void:
	var mat : ShaderMaterial = self.material_override
	mat.set_shader_parameter("sun_direction", sun.global_basis * -Vector3.FORWARD)
