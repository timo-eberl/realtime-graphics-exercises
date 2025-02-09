class_name Button3D
extends Area3D

@onready var sphere_mesh : MeshInstance3D = $Sphere

func press() -> void:
	print("button was pressed")
