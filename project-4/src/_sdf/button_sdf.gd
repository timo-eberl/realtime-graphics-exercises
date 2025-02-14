extends Button3D

@export var morph_time := 2.0

@onready var sdf : SDF = %SDF

var morph_progress := 0.0
var morph_progress_target := 0.0

func press() -> void:
	super.press()
	
	if morph_progress_target == 0.0:
		morph_progress_target = 1.0
	else:
		morph_progress_target = 0.0
	
	var tween := create_tween()
	tween.tween_property(self, "morph_progress", morph_progress_target, morph_time).set_trans(Tween.TRANS_SINE)

func _process(_delta: float) -> void:
	sdf.morph_progress = self.morph_progress
