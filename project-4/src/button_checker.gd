extends Node3D

@export_flags_3d_physics var buttons_layer := 0b100
@export var ray_distance := 2.0

@onready var camera : Node3D = %Camera
@onready var press_popup : Control = %PressPopup

func _physics_process(_delta: float) -> void:
	var space_state = get_world_3d().direct_space_state
	var origin := camera.global_position
	var direction := camera.global_basis * Vector3.FORWARD
	var end := origin + (direction * ray_distance)
	var query := PhysicsRayQueryParameters3D.create(origin, end)
	query.collide_with_areas = true
	query.collision_mask = buttons_layer

	var result := space_state.intersect_ray(query)
	if result:
		press_popup.visible = true
		var button : Button3D = result.collider
		if Input.is_action_just_pressed("interact"):
			button.press()
	else:
		press_popup.visible = false
