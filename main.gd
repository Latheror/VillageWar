extends Node3D

const Constants = preload("res://data/constants.gd")
const MapGenerator = preload("res://core/map_generator.gd")
const Tile = preload("res://data/tile.gd")
const TileRenderer = preload("res://rendering/tile_renderer.gd")

var tiles: Array = []

func _ready() -> void:
	tiles = MapGenerator.generate_map()
	_render_map()
	_setup_camera()
	_setup_light()

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
	var map_center = Constants.SIZE * Constants.TILE_SIZE / 2.0
	cam.transform.origin = Vector3(map_center, 60.0, map_center + 60.0)
	cam.look_at(Vector3(map_center, 0, map_center), Vector3.UP)
	cam.fov = 75.0
	cam.near = 0.1
	cam.far = 500.0

# -------------------------
# Light setup
# -------------------------
func _setup_light() -> void:
	var light = $DirectionalLight3D
	light.transform.origin = Vector3(Constants.SIZE * Constants.TILE_SIZE / 2, 50, -Constants.SIZE * Constants.TILE_SIZE / 2)
	light.rotation_degrees = Vector3(-45, 45, 0)
	light.light_energy = 3.0
