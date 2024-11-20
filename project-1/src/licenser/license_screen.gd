extends CanvasLayer
## A license screen that automatically populates from asset_source.md files found recursively
## in the resource path and runtime component and licensing information from godot.
## A small subset of markdown is converted to BBcode using regexes. BBcode is supported
## in all text fields configured below.

## The title font size. Font sizes for modules and submodules are automatically derived.
@export var title_font_size := 64
var module_font_size := title_font_size * 2 / 3.0
var submodule_font_size := title_font_size / 2.0

## The project name. Leave on the default value to use the project name given in project settings.
@export var project_name : String = ProjectSettings.get_setting("application/config/name")

## Inserted below the project name.
@export_multiline var project_credits := ""

## Inserted at the end of the scroller.
##
## You could use this to add license texts that are not part of the Godot-supplied texts,
## for instance.

@export var scroller_suffix := ""
## The scroll speed, in pixels / second.
@export var scroll_speed := 60 # in pixels / second

var desired_scroll_position := 0.0 
var auto_scrolling := false

# asset_source.md files should only have h2 or lower sections, as they are combined into whole files

var markdown_to_bbcode_regexes = [
	["####\\s+(.*?)\\n", "[font_size=%d]$1[/font_size]" % submodule_font_size],
	["###\\s+(.*?)\\n", "[font_size=%d]$1[/font_size]" % module_font_size],
	["##\\s+(.*?)\\n", "[font_size=%d]$1[/font_size]" % title_font_size],
	["\\*\\*(.*?)\\*\\*", "[b]$1[/b]"],
	["\\*(.*?)\\*", "[i]$1[/i]"],
	["<(.*?)>","[u]$1[/u]"], # our URLs are non-clickable, hence are rendered only visually
	["\\[(.*?)\\]\\((.*?)\\)","$1 ([u]$2[/u])"]  # accordingly
]

func compile_regexes():
	for m in markdown_to_bbcode_regexes:
		m[0] = RegEx.create_from_string(m[0])

func _ready():
	adapt_size()
	
	compile_regexes()
	
	build_scroller()
	
	# so that you can grab it with the mouse to navigate manually
	
	%ScrollContainer.get_v_scroll_bar().connect("scrolling", stop_scrolling)
	
	# prepare and start fade_in
	
	fade_in()
		
func find_and_make_all_asset_credits(path:="res://"):
	
	# see: https://docs.godotengine.org/de/stable/classes/class_directory.html
	# however: as of 2023-09-06, the online help for DirAccess is more current
	
	var dir := DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				find_and_make_all_asset_credits(path+file_name+"/")
			else:
				if file_name == "asset_source.md":
					make_asset_credits(path+file_name)
			file_name = dir.get_next()
	
func make_asset_credits(asset_source: String):
	var file = FileAccess.open(asset_source, FileAccess.READ)
	var content = file.get_as_text()
	
	# massage the markdown to look a little bit more like BBcode
	for m in markdown_to_bbcode_regexes:
		content = m[0].sub(content, m[1], true)
	
	%RichTextLabel.append_text("[p align=left]%s\n[/p]" % [content])	

func make_component_credits():

	var engine_name_version : String = ("Godot Engine %d.%d.%d" %
	 [Engine.get_version_info()["major"],
	  Engine.get_version_info()["minor"],
	  Engine.get_version_info()["patch"]])	

	%RichTextLabel.append_text("[p align=left][font_size=%d]%s\n\n[/font_size][/p]" % [module_font_size,engine_name_version])	
	# redundant: %RichTextLabel.append_text(Engine.get_license_text())
	
	%RichTextLabel.append_text("[p align=left]The Godot Engine embeds the following components:[/p]\n\n")
	
	# third-party licenses
	
	for l in Engine.get_copyright_info():
		%RichTextLabel.append_text("[p align=left][font_size=%d]%s\n\n[/font_size][/p]" % [submodule_font_size,l["name"]])
		for p in l["parts"]:
			for c in p["copyright"]:
				%RichTextLabel.append_text("[p align=left](c) %s\n[/p]" % c)
			%RichTextLabel.append_text("\n[p align=left]License: [b]%s[/b]\n\n[/p]" % p["license"])
				
	
	%RichTextLabel.append_text("\n\n\n\n[p align=center]Detailed license texts follow:[/p]")
	
	var licenses := Engine.get_license_info()
	
	for k in licenses:
		%RichTextLabel.append_text("\n\n[p align=left][font_size=%d][b]%s[/b] license\n\n[/font_size][/p]" % [submodule_font_size,k])
		%RichTextLabel.append_text("[code]%s[/code]" % licenses[k])

	%RichTextLabel.append_text("\n\n")

func build_scroller():
	
	%RichTextLabel.text = """\n\n\n\n\n\n\n\n\n\n\n[p align=center][font_size=%d]%s[/font_size][/p]
[p align=center][font_size=%d]%s[/font_size][/p]\n	
\n[p align=center]The following externally sourced software, 
assets, and contributions are acknowledged in gratitude[/p]\n\n""" % [title_font_size, project_name, 
									submodule_font_size, project_credits]

	find_and_make_all_asset_credits()
	make_component_credits()

	%RichTextLabel.append_text(scroller_suffix)	
	

func adapt_size():
	$Panel/ScrollContainer.custom_minimum_size.x = min($Panel.size.x * 0.8, 928)

func fade_in():
	var original_canvas_color : Color = $CanvasModulate.color
	$CanvasModulate.color = Color($CanvasModulate.color, 0.0)
	
	var tween = get_tree().create_tween()
	tween.tween_property($CanvasModulate, "color", 
						 original_canvas_color, 4)
	tween.tween_callback(start_scrolling)

func fade_out():
	var tween = get_tree().create_tween()
	tween.tween_property($CanvasModulate, "color", 
						 Color($CanvasModulate.color, 0.0), 2)
	tween.tween_callback(queue_free)

func start_scrolling():
	desired_scroll_position = $Panel/ScrollContainer.scroll_vertical
	auto_scrolling = true	

func stop_scrolling():
	auto_scrolling = false

func _process(delta):
	# keep in float variable so that less than one pixel
	# scrolling per frame is on average possible
	
	if auto_scrolling:
		desired_scroll_position += scroll_speed * delta
		$Panel/ScrollContainer.scroll_vertical = desired_scroll_position
	
	if Input.is_action_just_pressed("ui_cancel"):
		fade_out()
		
