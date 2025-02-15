class_name Explosion
extends Node3D

@export var objects : Array[RigidBody3D]

var i := 0

func explode() -> void:
	for o in objects:
		var self_to_o := o.global_position - self.global_position
		o.apply_impulse(self_to_o.normalized() * 5.0)
