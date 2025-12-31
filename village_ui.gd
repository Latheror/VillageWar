extends CanvasLayer

const Village = preload("res://data/village.gd")

var village_panels: Dictionary = {}  # village_id -> Control node
var top_bar: Panel
var date_label: Label
var day_label: Label
var pause_button: Button
var next_day_button: Button
var main_node: Node  # Reference to main.gd

func _ready() -> void:
	# Create top bar
	top_bar = Panel.new()
	top_bar.custom_minimum_size = Vector2(700, 40)
	top_bar.position = Vector2(10, 10)
	add_child(top_bar)
	
	# Date label
	date_label = Label.new()
	date_label.text = "Date: "
	date_label.position = Vector2(10, 10)
	date_label.custom_minimum_size = Vector2(250, 20)
	top_bar.add_child(date_label)
	
	# Day label
	day_label = Label.new()
	day_label.text = "Day: "
	day_label.position = Vector2(270, 10)
	day_label.custom_minimum_size = Vector2(100, 20)
	top_bar.add_child(day_label)
	
	# Pause button
	pause_button = Button.new()
	pause_button.text = "Pause"
	pause_button.position = Vector2(380, 4)
	pause_button.custom_minimum_size = Vector2(80, 20)
	pause_button.connect("pressed", Callable(self, "_on_pause_pressed"))
	top_bar.add_child(pause_button)
	
	# Next Day button
	next_day_button = Button.new()
	next_day_button.text = "Next Day"
	next_day_button.position = Vector2(470, 4)
	next_day_button.custom_minimum_size = Vector2(100, 20)
	next_day_button.connect("pressed", Callable(self, "_on_next_day_pressed"))
	top_bar.add_child(next_day_button)

func set_main_reference(main: Node) -> void:
	main_node = main

func _on_pause_pressed() -> void:
	if main_node:
		main_node.toggle_pause()

func _on_next_day_pressed() -> void:
	if main_node:
		main_node.advance_day()

func update_pause_button(is_paused: bool) -> void:
	pause_button.text = "Resume" if is_paused else "Pause"

func _process(_delta: float) -> void:
	# Update panel positions each frame to follow villages
	_update_panel_positions()

func update_hud(date: String, day: int) -> void:
	date_label.text = "Date: " + date
	day_label.text = "Day: " + str(day)

func add_village_panel(village: Village, world_position: Vector3) -> void:
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(140, 120)
	
	var container = VBoxContainer.new()
	container.custom_minimum_size = Vector2(120, 100)
	
	# Village name - larger and bold
	var name_label = Label.new()
	name_label.text = village.name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color(1, 0.8, 0))  # Gold color
	
	# Resources info - smaller
	var info_label = Label.new()
	info_label.text = "Tiles: %d\nPeople: %d\nFood: %d\nWood: %d" % [village.tile_count, village.people, village.food, village.wood]
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
		screen_pos.y -= 70  # Move up by 70 pixels (adjusted for larger panel)
		
		# Center the panel on the screen position
		var panel_size = data.panel.custom_minimum_size
		data.panel.position = screen_pos - panel_size / 2
		
		# Update the resource info (name stays the same)
		var container = data.panel.get_child(0)
		var info_label = container.get_child(1)
		info_label.text = "Tiles: %d\nPeople: %d\nFood: %d\nWood: %d" % [data.village.tile_count, data.village.people, data.village.food, data.village.wood]