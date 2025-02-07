extends MeshInstance3D

@onready var camera : Camera3D = %Camera

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(_delta: float) -> void:
	#set_shader_parameters();

func radians(degrees: float) -> float:
	return degrees / 360.0 * TAU

func set_shader_parameters():
	self.material_override.set_shader_parameter(
		"aspect_ratio", float(get_viewport().size.x) / get_viewport().size.y
	);
	
	self.material_override.set_shader_parameter("azimuth", camera.global_rotation.y)
	self.material_override.set_shader_parameter("elevation", camera.global_rotation.x)
	self.material_override.set_shader_parameter("camera_position", camera.global_position)
	self.material_override.set_shader_parameter("vertical_fov_radians", radians(camera.fov))
