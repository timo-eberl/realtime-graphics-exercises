extends Button
## Loads a [LicenseScreen]

@export var timeout_seconds := 4.0

var fading_out := false

# Called when the node enters the scene tree for the first time.
func _ready():
	grab_focus.call_deferred()
	await get_tree().create_timer(timeout_seconds).timeout
	fade_out()
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if (Input.is_joy_button_pressed(0,JOY_BUTTON_A) or 
		Input.is_joy_button_pressed(0,JOY_BUTTON_B) or 
		Input.is_joy_button_pressed(0,JOY_BUTTON_X) or 
		Input.is_joy_button_pressed(0,JOY_BUTTON_Y)): 
		_on_pressed()

func _on_pressed():
	var license_screen = load("res://licenser/license_screen.tscn").instantiate()
	owner.add_child(license_screen)

	fade_out()
	
func fade_out():
	# fade_out could be triggered by time-out or 
	# user action, do not do it twice (or queue_free
	# would be called twice)

	if fading_out:
		return
	
	fading_out = true	
	
	var tween = get_tree().create_tween()
	tween.tween_property(self, 
						 "position", 
						 self.position + Vector2(0.0, self.size.y), 2)
	tween.tween_callback(queue_free)

