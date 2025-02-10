extends Node3D

@export var speed := 0.03

func _process(delta: float) -> void:
	self.global_rotation.y += delta * speed * TAU
