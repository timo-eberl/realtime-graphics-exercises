extends CollisionShape3D

@export var time_offset = 0.0
@export var time_scale = 0.0
@export var grow_scale = 1.0

@onready var sphere_shape : SphereShape3D = self.shape
var original_radius : float

func _ready() -> void:
	original_radius = sphere_shape.radius

func _physics_process(_delta: float) -> void:
	# the same time is used in the shader
	var time := Time.get_ticks_msec() / 1000.0
	sphere_shape.radius = original_radius + 0.1 * sin(time * time_scale + time_offset) * grow_scale
