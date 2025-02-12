class_name Interactible
extends Area3D

@export var ui_text := "Interact"

func _ready() -> void:
	self.collision_layer = 0b100

func press() -> void:
	pass
