class_name ButtonChecker
extends Node3D

@export_flags_3d_physics var buttons_layer := 0b100
@export var ray_distance := 2.0

@onready var camera : Node3D = %Camera
@onready var press_popup : Control = %PressPopup

var enabled := true
var interactible : Interactible = null

func _physics_process(_delta: float) -> void:
	if !enabled:
		press_popup.visible = false
		return
	
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
		interactible = result.collider
		%PressPopup/Label.text = "E - " + interactible.ui_text
	else:
		press_popup.visible = false
		interactible = null

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and enabled and interactible:
		interactible.press()
