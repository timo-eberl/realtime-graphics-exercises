extends Node3D
class_name Rotate

@export var rotation_time := 5.0


func _process(delta: float) -> void:
	self.transform = self.transform.rotated(Vector3.UP, delta * TAU / rotation_time)
