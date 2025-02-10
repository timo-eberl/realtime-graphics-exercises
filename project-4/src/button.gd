class_name Button3D
extends Area3D

@onready var sphere_mesh : MeshInstance3D = $Sphere

func press() -> void:
	var tween := create_tween()
	tween.tween_property(sphere_mesh, "scale", Vector3(1,0.1,1), 0.1)
	tween.tween_property(sphere_mesh, "scale", Vector3(1,1,1), 0.1)
