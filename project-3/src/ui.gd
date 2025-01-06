extends PanelContainer

@onready var crown : Crown = $"../Crown"
@onready var rotating_light : Rotate = $"../RotatingLight"

@onready var age_slider : HSlider = $VBoxContainer/HBoxContainerAge/HSlider
@onready var light_speed_slider : HSlider = $VBoxContainer/HBoxContainerLightSpeed/HSlider
@onready var crown_tips_slider : HSlider = $VBoxContainer/HBoxContainerCrownTips/HSlider
@onready var crown_tips_count : Label = $VBoxContainer/HBoxContainerCrownTips/Count

func _ready() -> void:
	update_age(age_slider.value)
	age_slider.value_changed.connect(self.update_age)
	
	update_light_speed(light_speed_slider.value)
	light_speed_slider.value_changed.connect(self.update_light_speed)
	
	update_crown_tips(crown_tips_slider.value)
	crown_tips_slider.value_changed.connect(self.update_crown_tips)

func update_age(value):
	crown.age = value

func update_light_speed(value):
	rotating_light.rotation_time = 1.0 / value

func update_crown_tips(value):
	crown.tip_count = int(value)
	crown_tips_count.text = str(crown.tip_count)
