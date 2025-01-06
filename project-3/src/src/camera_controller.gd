extends Node3D

# camera pan controls

@export var look_speed := 0.2
@export var zoom_speed := 0.1
@export var distance_limit_min := 0.1
@export var distance_limit_max := 100.0
@export var rotation_limit_upwards := 90
@export var rotation_limit_downwards := 90

@onready var camera : Camera3D = $Camera

func _ready() -> void:
	assert(is_zero_approx(camera.position.x), "Only z component of camera.position should be modified")
	assert(is_zero_approx(camera.position.y), "Only z component of camera.position should be modified")
	assert(camera.rotation.is_zero_approx(), "To change camera rotation, change the camera controllers rotation")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.is_action_pressed("mouse_down"):
		self.rotation_degrees.y -= look_speed * event.relative.x;
		self.rotation_degrees.x -= look_speed * event.relative.y;
		self.rotation_degrees.x = clampf(self.rotation_degrees.x, -rotation_limit_upwards, rotation_limit_downwards)
	
	if Input.is_action_pressed("zoom_in"):
		camera.position.z *= 1 - zoom_speed
	if Input.is_action_pressed("zoom_out"):
		camera.position.z *= 1 + zoom_speed
	camera.position.z = clampf(camera.position.z, distance_limit_min, distance_limit_max)
