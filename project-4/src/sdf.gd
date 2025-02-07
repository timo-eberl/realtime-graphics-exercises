extends Panel

@onready var camera : Camera3D = %Camera

func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	set_shader_parameters();

func radians(degrees: float) -> float:
	return degrees / 360.0 * TAU

func set_shader_parameters():
	self.material.set_shader_parameter("aspect_ratio", self.size.x / self.size.y);
	
	self.material.set_shader_parameter("azimuth", camera.global_rotation.y)
	self.material.set_shader_parameter("elevation", camera.global_rotation.x)
	self.material.set_shader_parameter("camera_position", camera.global_position)
	self.material.set_shader_parameter("vertical_fov_radians", radians(camera.fov))
