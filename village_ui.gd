extends CanvasLayer

const Village = preload("res://data/village.gd")

var village_panels: Dictionary = {}  # village_id -> Control node

func _ready() -> void:
	# This will be called when the scene is ready
	pass

func _process(_delta: float) -> void:
	# Update panel positions each frame to follow villages
	_update_panel_positions()

func add_village_panel(village: Village, world_position: Vector3) -> void:
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(140, 100)
	
	var container = VBoxContainer.new()
	container.custom_minimum_size = Vector2(120, 80)
	
	# Village name - larger and bold
	var name_label = Label.new()
	name_label.text = village.name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color(1, 0.8, 0))  # Gold color
	
	# Resources info - smaller
	var info_label = Label.new()
	info_label.text = "People: %d\nFood: %d\nWood: %d" % [village.people, village.food, village.wood]
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_label.add_theme_font_size_override("font_size", 12)
	
	container.add_child(name_label)
	container.add_child(info_label)
	
	panel.add_child(container)
	add_child(panel)
	
	village_panels[village.id] = {
		"panel": panel,
		"world_pos": world_position,
		"village": village
	}

func _update_panel_positions() -> void:
	var camera = get_viewport().get_camera_3d()
	if not camera:
		return
		
	for village_id in village_panels:
		var data = village_panels[village_id]
		var world_pos = data.world_pos
		
		# Convert 3D world position to screen position
		var screen_pos = camera.unproject_position(world_pos)
		
		# Offset the panel to appear above the village
		screen_pos.y -= 60  # Move up by 60 pixels (adjusted for larger panel)
		
		# Center the panel on the screen position
		var panel_size = data.panel.custom_minimum_size
		data.panel.position = screen_pos - panel_size / 2
		
		# Update the resource info (name stays the same)
		var container = data.panel.get_child(0)
		var info_label = container.get_child(1)
		info_label.text = "People: %d\nFood: %d\nWood: %d" % [data.village.people, data.village.food, data.village.wood]