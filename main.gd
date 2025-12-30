extends Node3D

const Constants = preload("res://data/constants.gd")
const MapGenerator = preload("res://core/map_generator.gd")
const Tile = preload("res://data/tile.gd")
const Village = preload("res://data/village.gd")
const TileRenderer = preload("res://rendering/tile_renderer.gd")
const VillageUI = preload("res://village_ui.gd")

var tiles: Array = []
var villages: Array = []
var village_ui: CanvasLayer
var camera: Camera3D
var camera_distance: float = 80.0
var camera_angle: float = 45.0
var camera_speed: float = 20.0
var zoom_speed: float = 10.0
var camera_target: Vector3

func _ready() -> void:
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

func _process(delta: float) -> void:
	_handle_camera_movement(delta)
	_update_camera_position()

func _input(event: InputEvent) -> void:
	_handle_zoom(event)

# -------------------------
# Map rendering
# -------------------------
func _render_map() -> void:
	for tile in tiles:
		TileRenderer.render_tile(self, tile.x, tile.y, Constants.TILE_SIZE, tile.color, tile.height, tile.biome, tile.village_id, tile.resource)

# -------------------------
# Camera setup
# -------------------------
func _setup_camera() -> void:
	var cam = $Camera3D
	cam.fov = 75.0
	cam.near = 0.1
	cam.far = 500.0
	# Initial camera position will be set by _update_camera_position()

# -------------------------
# Light setup
# -------------------------
func _setup_light() -> void:
	var light = $DirectionalLight3D
	light.transform.origin = Vector3(Constants.SIZE * Constants.TILE_SIZE / 2, 50, -Constants.SIZE * Constants.TILE_SIZE / 2)
	light.rotation_degrees = Vector3(-45, 45, 0)
	light.light_energy = 3.0

# -------------------------
# Village UI setup
# -------------------------
func _setup_village_ui() -> void:
	village_ui = VillageUI.new()
	add_child(village_ui)
	
	# Create UI panels for each village
	for village in villages:
		# Calculate world position of the village (center of the tile)
		var world_pos = Vector3(
			village.position.x * Constants.TILE_SIZE + Constants.TILE_SIZE / 2.0,
			5.0,  # Height above the ground
			village.position.y * Constants.TILE_SIZE + Constants.TILE_SIZE / 2.0
		)
		village_ui.add_village_panel(village, world_pos)

# -------------------------
# Camera controls
# -------------------------
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

func _update_camera_position() -> void:
	if camera:
		# Calculate camera position based on distance and angle around the target
		var camera_x = camera_target.x + camera_distance * cos(deg_to_rad(camera_angle))
		var camera_z = camera_target.z + camera_distance * sin(deg_to_rad(camera_angle))
		var camera_y = camera_distance * 0.5  # Height based on distance
		
		camera.transform.origin = Vector3(camera_x, camera_y, camera_z)
		camera.look_at(camera_target, Vector3.UP)
