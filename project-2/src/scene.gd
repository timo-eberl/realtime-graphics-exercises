@tool

extends Control

# generic shader parameters
# the rationale is: building the user interface once for
# a generic set of parameters permits much faster iteration

@export_group("Generic Shader Parameters")

@export_subgroup("Points in space")

@export var P := Vector3(0.0, 0.0, 0.0)
@export var Q := Vector3(0.0, 0.0, 0.0)

@export_subgroup("Extents (radii etc.)")

@export var R := Vector3(1.0, 1.0, 1.0)
@export var S := Vector3(1.0, 1.0, 1.0)

@export_subgroup("Angles (degrees)")

@export_range(0.0, 360.0, 1.0, "or_greater", "or_less") var theta  = 0.0
@export_range(0.0, 360.0, 1.0, "or_greater", "or_less") var phi    = 0.0

@export_subgroup("Scalars")

@export_range(0.0, 1.0, 0.01, "or_greater", "or_less") var lambda = 1.0
@export_range(0.0, 1.0, 0.01, "or_greater", "or_less") var mu     = 0.0
@export_range(0.0, 1.0, 0.01, "or_greater", "or_less") var nu     = 0.0

@export_subgroup("Colors")

@export_color_no_alpha var color_a : Color = Color(1.0,1.0,1.0)
@export_color_no_alpha var color_b : Color = Color(1.0,0.3,0.3)
@export_color_no_alpha var color_c : Color = Color(1.0,1.0,0.3)
@export_color_no_alpha var color_d : Color = Color(0.3,1.0,0.3)

@export_group("Background")

# sky

@export_subgroup("Sky")

@export_color_no_alpha var zenith_color : Color = Color(0.2,0.3,0.5)
@export_color_no_alpha var horizon_color : Color = Color(0.2,0.45,0.75)

@export_color_no_alpha var sun_color : Color = Color(1.0, 1.0, 1.0)
@export var sun_direction := Vector3(0.7,0.7,-0.7)
@export_range(0.0, 10.0,0.01, "or_greater") var sun_radius_degrees : float = 0.5

@export_group("Camera")

## in degrees against north
@export_range(0.0, 360.0) var azimuth = 0.0

# camera view direction (not position)

const MIN_ELEVATION := -90.0
const MAX_ELEVATION :=  90.0

## in degrees against the horizon
@export_range(MIN_ELEVATION, MAX_ELEVATION) var elevation = 0.0

const MIN_CAM_POS_Y := 2.0
const MAX_CAM_POS_Y := 250.0

## in meters
@export var camera_position := Vector3(0.0, 1.8, 0.0)

@export_subgroup("Interactive Control")

## in degrees/s
@export var turn_speed = 60.0

## in m/s
@export var movement_speed := 5.0

## in m
@export var height_offset := 1.8

## in degrees / pixel
@export var mouse_look_speed := 0.2

@export var mouse_wheel_step_factor := 1.5

## vertical field of view, in degrees
@export var vertical_fov_degrees := 45.0

## how fast the camera moves between preset points
@export var CAMERA_ANIMATION_TIME := 1.0

@export_group("Tone mapper")

## in f-stops
@export_range(-10.0, 10.0) var exposure : float = 0.0
@export_range(0.0, 10.0, 0.01, "or_greater") var l_white = 2.0

@onready var panel : Panel = $Panel


func _ready():
	# only if not in tool mode:
	
	if not Engine.is_editor_hint():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

# trig helpers

func radians(degrees: float) -> float:
	return degrees / 360.0 * TAU

func dsin(degrees: float) -> float:
	return sin(radians(degrees));

func dcos(degrees: float) -> float:
	return cos(radians(degrees));

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not Engine.is_editor_hint(): # process input only when running stand-alone
		if Input.is_action_just_pressed("ui_cancel"):
			get_tree().quit()
		# compute movement updates
		# elevation and azimuth are updated in _input
		# update movement
		var forward := Vector3(dsin(azimuth), 0.0, -dcos(azimuth))
		var right   := Vector3(dcos(azimuth), 0.0, dsin(azimuth))
		var movement_update : Vector2 = movement_speed * delta * \
			Input.get_vector("move_left","move_right","move_backward","move_forward")
		var movement_update_y : float = movement_speed * delta * \
			Input.get_axis("move_down", "move_up")
		camera_position += movement_update.y * forward
		camera_position += movement_update.x * right
		camera_position.y += movement_update_y
		
	camera_position.y = clamp(camera_position.y, MIN_CAM_POS_Y, MAX_CAM_POS_Y)
	set_shader_parameters();
	
func set_shader_parameters():

	# set shader parameter: aspect ration
	
	panel.material.set_shader_parameter("aspect_ratio", panel.size.x / panel.size.y);
	
	# set shader parameters: sky
	
	panel.material.set_shader_parameter("zenith_color", zenith_color)
	panel.material.set_shader_parameter("horizon_color", horizon_color)
	panel.material.set_shader_parameter("sun_direction", sun_direction.normalized())
	panel.material.set_shader_parameter("sun_color", sun_color)
	panel.material.set_shader_parameter("cos_sun_radius", cos(radians(sun_radius_degrees)))
	
	# set shader uniforms - camera
	
	panel.material.set_shader_parameter("vertical_fov_radians", radians(vertical_fov_degrees))
	panel.material.set_shader_parameter("camera_position", camera_position)
	panel.material.set_shader_parameter("azimuth", radians(azimuth))
	panel.material.set_shader_parameter("elevation", radians(elevation))

	# set shader uniforms - tone mapper
	panel.material.set_shader_parameter("exposure", exposure)
	panel.material.set_shader_parameter("l_white", l_white)

	# set shader uniforms – generic parameters
	
	panel.material.set_shader_parameter("P", P)
	panel.material.set_shader_parameter("Q", Q)
	panel.material.set_shader_parameter("R", R)
	panel.material.set_shader_parameter("S", S)
	
	panel.material.set_shader_parameter("lambda", lambda)
	panel.material.set_shader_parameter("mu", mu)
	panel.material.set_shader_parameter("nu", nu)
	panel.material.set_shader_parameter("theta", radians(theta))
	panel.material.set_shader_parameter("phi", radians(phi))
	
	panel.material.set_shader_parameter("color_a", color_a)
	panel.material.set_shader_parameter("color_b", color_b)
	panel.material.set_shader_parameter("color_c", color_c)
	panel.material.set_shader_parameter("color_d", color_d)

func set_condition(k: Key):
	
	var tween := create_tween()
	
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_parallel(true)
	
	match k:
		KEY_R: # reset camera to salient points
			
			if elevation < 5.0 and azimuth < 5.0:
				tween.tween_property(self, "elevation", 25.0, CAMERA_ANIMATION_TIME)
				tween.tween_property(self, "azimuth", 45.0, CAMERA_ANIMATION_TIME)
			elif 20.0 < elevation and elevation < 30.0 and 40.0 < azimuth and azimuth < 50.0:
				tween.tween_property(self, "elevation", 90.0, CAMERA_ANIMATION_TIME)
				tween.tween_property(self, "azimuth", 0.0, CAMERA_ANIMATION_TIME)
			elif elevation > 85.0 and azimuth < 5.0:
				tween.tween_property(self, "elevation", 0.0, CAMERA_ANIMATION_TIME)
				tween.tween_property(self, "azimuth", 90.0, CAMERA_ANIMATION_TIME)
			elif elevation < 5.0 and 85.0 < azimuth and azimuth < 95.0:
				tween.tween_property(self, "elevation", 0.0, CAMERA_ANIMATION_TIME)
				tween.tween_property(self, "azimuth", 180.0, CAMERA_ANIMATION_TIME)
			elif elevation < 5.0 and 175.0 < azimuth and azimuth  < 185.0:
				tween.tween_property(self, "elevation", 0.0, CAMERA_ANIMATION_TIME)
				tween.tween_property(self, "azimuth", 270.0, CAMERA_ANIMATION_TIME)
			elif elevation < 5.0 and 265.0 < azimuth and azimuth < 275.0:
				tween.tween_property(self, "elevation", 0.0, CAMERA_ANIMATION_TIME)
				tween.tween_property(self, "azimuth", 360.0, CAMERA_ANIMATION_TIME)
			else:
				tween.tween_property(self, "elevation", 0.0, CAMERA_ANIMATION_TIME)
				tween.tween_property(self, "azimuth", 0.0, CAMERA_ANIMATION_TIME)
			
		KEY_M: # mu
			if mu >= 1.0:
				tween.tween_property(self, "mu", 0.0, 1.0)
			else:			
				tween.tween_property(self, "mu", clamp(mu + 0.25, 0.0, 1.0), 0.5)

		KEY_N: # nu
			if nu >= 1.0:
				tween.tween_property(self, "nu", 0.0, 1.0)
			else:			
				tween.tween_property(self, "nu", clamp(nu + 0.25, 0.0, 1.0), 0.5)

		KEY_L: # lambda
			if lambda >= 1.0:
				tween.tween_property(self, "lambda", 0.0, 1.0)
			else:			
				tween.tween_property(self, "lambda", clamp(lambda + 0.25, 0.0, 1.0), 0.5)

				
		KEY_1: # daylight
			tween.tween_property(self, "zenith_color", Color(0.2,0.3,0.5), 5.0)
			tween.tween_property(self, "horizon_color", Color(0.2,0.45,0.75), 5.0)
			tween.tween_property(self, "sun_color", Color(1.0,1.0,1.0), 5.0)
			tween.tween_property(self, "sun_direction", Vector3(0.7,0.7,-0.7), 5.0)
			
		KEY_2: # sunset
			tween.tween_property(self, "zenith_color", Color(0.2,0.05,0.05), 5.0)
			tween.tween_property(self, "horizon_color", Color(0.5,0.2,0.05), 5.0)
			tween.tween_property(self, "sun_color", Color(1.0,0.9,0.8), 5.0)
			tween.tween_property(self, "sun_direction", Vector3(0.1,0.1,-0.7), 5.0)
			
		KEY_P:
			var image = get_viewport().get_texture().get_image()
			var time = Time.get_datetime_string_from_system().replace(":","_")
			var filename = "godot-screenshot_%s.png" % time
			
			image.save_png(filename)
			print("Saved screen in %s" % filename)
			# do whatever to make sure the tween does not cause an error
			tween.tween_property(self, "lambda", lambda, 0.0)
			
		_:
			# do whatever to make sure the tween does not cause an error
			tween.tween_property(self, "lambda", lambda, 0.0)
			
	
# for mouse look;
# see: https://ask.godotengine.org/24094/inputeventmousemotion
# see: https://docs.godotengine.org/en/stable/classes/class_inputeventmousemotion.html

func _input(event):
	if ( event is InputEventMouseButton 
		and (   event.button_index == MOUSE_BUTTON_WHEEL_DOWN
			 or event.button_index == MOUSE_BUTTON_WHEEL_UP    )):
		
		var tween := create_tween()
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.set_ease(Tween.EASE_OUT)
		tween.set_parallel(true)
		
	if event is InputEventMouseMotion:
		azimuth = fmod(azimuth + mouse_look_speed * event.relative.x ,360.0);
		elevation = elevation + mouse_look_speed * event.relative.y;
		elevation = clamp(elevation, MIN_ELEVATION, MAX_ELEVATION);
		
	if event is InputEventKey and event.is_pressed():
		set_condition(event.get_keycode())
		
