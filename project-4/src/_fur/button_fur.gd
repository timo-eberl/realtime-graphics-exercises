extends Button3D

@onready var explosion : Explosion = %Explosion

func press() -> void:
	super.press()
	explosion.explode()
