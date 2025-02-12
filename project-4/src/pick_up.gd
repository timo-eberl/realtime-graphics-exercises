extends Interactible

@onready var character : CharacterController = %Character
@onready var button_checker : ButtonChecker = %ButtonChecker
@onready var camera : Camera3D = %Camera
@onready var card : Node3D = %LenticularCard
@onready var leave_popup : Control = %LeavePopup
@onready var card_resting_place : Node3D = %CardRestingPlace
@export var rotation_speed := 0.5

var looking_at_card := false

func _ready() -> void:
	super._ready()
	ui_text = "Pick up"

func press() -> void:
	super.press()
	character.enabled = false
	button_checker.enabled = false
	self.looking_at_card = true
	leave_popup.visible = true
	
	var target_transform := camera.global_transform.translated_local(Vector3(0,0,-0.8))
	var tween := create_tween()
	tween.tween_property(card, "global_transform", target_transform, 0.5)

func _unhandled_input(event: InputEvent) -> void:
	if !looking_at_card:
		return
	# rotate card with mouse
	card.rotation_order = EULER_ORDER_XYZ
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		card.rotation_degrees.y += rotation_speed * event.relative.x;
		card.rotation_degrees.x += rotation_speed * event.relative.y;
	
	if event.is_action_pressed("interact") and looking_at_card:
		character.enabled = true
		self.looking_at_card = false
		leave_popup.visible = false
		
		var target_transform := card_resting_place.global_transform
		var tween := create_tween()
		tween.tween_property(card, "global_transform", target_transform, 0.5)
		
		# wait one frame, otherwise the interact input will get processed again by the
		# ButtonChecker and the object will be picked up again immediately
		await get_tree().process_frame
		button_checker.enabled = true
