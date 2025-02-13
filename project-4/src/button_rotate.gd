extends Button3D

@export var morph_time := 2.0
@export var rotation_target := 90 # degrees

@onready var window_center : Node3D = %WindowCenter

func press() -> void:
	super.press()
	
	var tween := create_tween()
	var target := window_center.rotation_degrees
	target.y = rotation_target
	tween.tween_property(window_center, "rotation_degrees", target, morph_time).set_trans(Tween.TRANS_SINE)
