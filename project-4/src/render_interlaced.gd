extends MeshInstance3D

@export var enable := false
@export var resolution := Vector2i(1024, 1024)

func _ready() -> void:
	self.visible = enable
	if enable:
		get_viewport().get_window().size = resolution
		get_viewport().get_window().unresizable = true
		for i in 3:
			await get_tree().process_frame
		var img: Image = get_viewport().get_texture().get_image()
		img.convert(Image.FORMAT_RGBA8)
		img.save_png("res://screenshot.png")
		print("screenshot taken")
