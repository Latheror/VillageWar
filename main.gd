extends Node3D

const Constants = preload("res://constants.gd")
const MapGenerator = preload("res://map_generator.gd")
const Tile = preload("res://tile.gd")

var tiles: Array = []

func _ready() -> void:
	tiles = MapGenerator.generate_map()
	MapGenerator.place_villages(tiles)
	_render_map()
	_setup_camera()
	_setup_light()

# -------------------------
# Map rendering
# -------------------------
func _render_map() -> void:
	for tile in tiles:
		_draw_tile(tile.x, tile.y, Constants.TILE_SIZE, tile.color, tile.height, tile.village_id)

# -------------------------
# Draw 3D tile
# -------------------------
func _draw_tile(x: int, y: int, tile_size: float, color: Color, height: float, village_id: int = 0) -> void:
	var mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(tile_size, height, tile_size)
	mesh_instance.mesh = box_mesh

	var material = StandardMaterial3D.new()
	if village_id > 0:
		material.albedo_color = Constants.VILLAGE_COLOR
	else:
		material.albedo_color = color
	mesh_instance.material_override = material

	mesh_instance.position = Vector3(x * tile_size, height / 2.0, y * tile_size)
	add_child(mesh_instance)

	# Add laser for villages
	if village_id > 0:
		_draw_village_laser(x, y, height)

# -------------------------
# Draw village laser
# -------------------------
func _draw_village_laser(x: int, y: int, tile_height: float) -> void:
	var laser_instance = MeshInstance3D.new()
	var cylinder_mesh = CylinderMesh.new()
	cylinder_mesh.top_radius = 0.1
	cylinder_mesh.bottom_radius = 0.1
	cylinder_mesh.height = 10.0  # tall laser beam

	var laser_material = StandardMaterial3D.new()
	laser_material.albedo_color = Color(1.0, 0.0, 0.0, 0.3)  # red translucent
	laser_material.emission_enabled = true
	laser_material.emission = Color(1.0, 0.0, 0.0)  # red emission
	laser_material.emission_energy = 2.0
	laser_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	laser_instance.mesh = cylinder_mesh
	laser_instance.material_override = laser_material
	laser_instance.position = Vector3(x * Constants.TILE_SIZE, tile_height + 5.0, y * Constants.TILE_SIZE)  # above the tile
	add_child(laser_instance)

	# Add light at the top of the laser
	var laser_light = OmniLight3D.new()
	laser_light.light_color = Color(1.0, 0.0, 0.0)
	laser_light.light_energy = 3.0
	laser_light.omni_range = 5.0
	laser_light.position = Vector3(x * Constants.TILE_SIZE, tile_height + 10.0, y * Constants.TILE_SIZE)
	add_child(laser_light)

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
