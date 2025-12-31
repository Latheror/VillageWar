## Main scene orchestrator for VillageWar strategy game.
## Handles map generation, rendering, camera control, and daily village actions.
extends Node3D

const Constants = preload("res://data/constants.gd")
const MapGenerator = preload("res://core/map_generator.gd")
const Tile = preload("res://data/tile.gd")
const Village = preload("res://data/village.gd")
const TileRenderer = preload("res://rendering/tile_renderer.gd")
const VillageUI = preload("res://village_ui.gd")
const TimeManager = preload("res://time_manager.gd")

var tiles: Array = []
var villages: Array = []
var village_ui: CanvasLayer
var time_manager: TimeManager
var camera: Camera3D
var camera_distance: float = 80.0
var camera_angle: float = 45.0
var camera_speed: float = 20.0
var zoom_speed: float = 10.0
var camera_target: Vector3

# ==================== Core Lifecycle ====================
## Initialize map, rendering, camera, UI, and time manager.
func _ready() -> void:
	time_manager = TimeManager.new()
	add_child(time_manager)
	time_manager.connect("day_advanced", Callable(self, "_on_day_advanced"))
	
	var map_data = MapGenerator.generate_map()
	tiles = map_data.tiles
	villages = map_data.villages
	_render_map()
	_setup_camera()
	_setup_light()
	_setup_village_ui()
	
	# Get camera reference for controls
	camera = $Camera3D
	# Initialize camera target at map center
	var map_center = Constants.SIZE * Constants.TILE_SIZE / 2.0
	camera_target = Vector3(map_center, 0, map_center)
	_update_camera_position()  # Set initial camera position

func _on_day_advanced() -> void:
	process_village_actions()
	village_ui.update_hud(time_manager.get_date(), time_manager.get_day())

# ==================== Daily Processing ====================
## Execute daily village actions and update UI.
## Villages build, farm, cut wood, and manage population each day.
func process_village_actions() -> void:
	var any_changed = false
	for village in villages:
		if village.perform_daily_action(tiles, Constants):
			any_changed = true

	# Update tile counts (count only house tiles: village-owned tiles with resource NONE)
	for village in villages:
		var count = 0
		for tile in tiles:
			if tile.village_id == village.id and tile.resource == Constants.ResourceType.NONE:
				count += 1
		village.tile_count = count

	# Enforce population cap after tile counts updated
	for village in villages:
		var max_pop = 5 * village.tile_count
		if village.people > max_pop:
			village.people = max_pop

	# Re-render map only if something changed
	if any_changed:
		_render_map()

func _process(delta: float) -> void:
	_handle_camera_movement(delta)
	_update_camera_position()

func _input(event: InputEvent) -> void:
	_handle_zoom(event)

# ==================== Rendering ====================
## Clear and redraw all tiles, buildings, and villagers each frame.
func _render_map() -> void:
	# Clear existing mesh instances
	for child in get_children():
		if child is MeshInstance3D:
			child.queue_free()
	
	for tile in tiles:
		TileRenderer.render_tile(self, tile.x, tile.y, Constants.TILE_SIZE, tile.color, tile.height, tile.biome, tile.village_id, tile.resource, villages)

	# Draw village workers (humans)
	for village in villages:
		var worker_positions = village.get_worker_positions(tiles)
		for pos in worker_positions:
			# pos is a Vector2 tile coordinate; convert to world coords (center of tile)
			var world_x = pos.x * Constants.TILE_SIZE + Constants.TILE_SIZE / 2.0
			var world_z = pos.y * Constants.TILE_SIZE + Constants.TILE_SIZE / 2.0
			TileRenderer._draw_human(self, world_x, world_z, 0.0, Color(0.9, 0.9, 0.9))

# ==================== Camera Setup ====================
## Configure camera parameters.
func _setup_camera() -> void:
	var cam = $Camera3D
	cam.fov = 75.0
	cam.near = 0.1
	cam.far = 500.0
	# Initial camera position will be set by _update_camera_position()

# ==================== Lighting ====================
## Setup directional light for the scene.
func _setup_light() -> void:
	var light = $DirectionalLight3D
	light.transform.origin = Vector3(Constants.SIZE * Constants.TILE_SIZE / 2, 50, -Constants.SIZE * Constants.TILE_SIZE / 2)
	light.rotation_degrees = Vector3(-45, 45, 0)
	light.light_energy = 3.0

# ==================== UI Setup ====================
## Create village info panels and HUD.
func _setup_village_ui() -> void:
	village_ui = VillageUI.new()
	add_child(village_ui)
	village_ui.set_main_reference(self)
	
	# Create UI panels for each village
	for village in villages:
		# Calculate world position of the village (center of the tile)
		var world_pos = Vector3(
			village.position.x * Constants.TILE_SIZE + Constants.TILE_SIZE / 2.0,
			5.0,  # Height above the ground
			village.position.y * Constants.TILE_SIZE + Constants.TILE_SIZE / 2.0
		)
		village_ui.add_village_panel(village, world_pos)
	
	# Update HUD with initial values
	village_ui.update_hud(time_manager.get_date(), time_manager.get_day())

# ==================== Camera Controls ====================
## Handle camera movement and zoom from player input.
func _handle_camera_movement(delta: float) -> void:
	var move_vector = Vector3.ZERO
	
	if Input.is_action_pressed("ui_left"):
		move_vector.x -= 1
	if Input.is_action_pressed("ui_right"):
		move_vector.x += 1
	if Input.is_action_pressed("ui_up"):
		move_vector.z -= 1
	if Input.is_action_pressed("ui_down"):
		move_vector.z += 1
	
	if move_vector != Vector3.ZERO:
		move_vector = move_vector.normalized() * camera_speed * delta * camera_distance * 0.1
		camera_target += move_vector
		_update_camera_position()

func _handle_zoom(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			camera_distance = max(20.0, camera_distance - zoom_speed)
			_update_camera_position()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			camera_distance = min(200.0, camera_distance + zoom_speed)
			_update_camera_position()

## Advance game time by one day (called manually by UI button).
func advance_day() -> void:
	time_manager.advance_day()
	village_ui.update_hud(time_manager.get_date(), time_manager.get_day())

## Toggle automatic day advancement (pause/resume).
func toggle_pause() -> void:
	time_manager.toggle_pause()
	village_ui.update_pause_button(time_manager.is_paused())

## Update camera position based on distance, angle, and target.
func _update_camera_position() -> void:
	if camera:
		# Calculate camera position based on distance and angle around the target
		var camera_x = camera_target.x + camera_distance * cos(deg_to_rad(camera_angle))
		var camera_z = camera_target.z + camera_distance * sin(deg_to_rad(camera_angle))
		var camera_y = camera_distance * 0.5  # Height based on distance
		
		camera.transform.origin = Vector3(camera_x, camera_y, camera_z)
		camera.look_at(camera_target, Vector3.UP)
