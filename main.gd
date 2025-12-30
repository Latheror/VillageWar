extends Node3D

const SIZE: int = 30
const TILE_SIZE: float = 2.0        # world units per tile
const HEIGHT_SCALE: float = 1.0     # scale for mountain heights

# --- Island shape ---
const SHAPE_FREQ: float = 0.05
const SHAPE_OCTAVES: int = 3
const WARP_FREQ: float = 0.1
const WARP_STRENGTH: float = 2.5
const LAND_THRESHOLD: float = 0.0

# --- Edge safety ---
const EDGE_POWER: float = 6.0

# --- Height ---
const BASE_HEIGHT: float = 10.0
const DETAIL_FREQ: float = 0.08
const DETAIL_MULT: float = 4.0

# --- Biomes ---
const DEEP_WATER_THRESHOLD: float = -6.0
const WATER_THRESHOLD: float = 0.0
const SAND_THRESHOLD: float = 3.0
const PLAIN_THRESHOLD: float = 9.0

func _ready() -> void:
	_generate_map()
	_setup_camera()
	_setup_light()

# -------------------------
# Map generation
# -------------------------
func _generate_map() -> void:
	var half = SIZE / 2.0
	var noise: FastNoiseLite = FastNoiseLite.new()
	noise.seed = randi()
	noise.fractal_octaves = SHAPE_OCTAVES
	noise.frequency = SHAPE_FREQ

	for x in range(SIZE):
		for y in range(SIZE):
			# Edge mask
			var cx: float = x - half
			var cy: float = y - half
			var edge_dist: float = Vector2(cx, cy).length() / half
			var edge_mask: float = pow(clamp(edge_dist, 0.0, 1.0), EDGE_POWER)

			# Domain warp
			var warp_x: float = noise.get_noise_2d(x * WARP_FREQ, y * WARP_FREQ) * WARP_STRENGTH
			var warp_y: float = noise.get_noise_2d((x+100) * WARP_FREQ, (y+100) * WARP_FREQ) * WARP_STRENGTH
			var wx: float = x + warp_x
			var wy: float = y + warp_y

			# Shape noise
			var shape: float = noise.get_noise_2d(wx, wy)

			# Smooth land factor
			var land_factor: float = clamp((shape - LAND_THRESHOLD) / 0.5, 0.0, 1.0)
			if land_factor <= 0.0 or edge_mask > 0.95:
				_draw_tile(x, y, TILE_SIZE, Color(0.0, 0.0, 0.4), 0.5)
				continue

			# Height
			var base_height: float = (1.0 - edge_mask) * BASE_HEIGHT * land_factor
			var detail: float = noise.get_noise_2d(x * DETAIL_FREQ, y * DETAIL_FREQ)
			var height: float = base_height + detail * DETAIL_MULT

			# Limit height near edges
			var max_edge_height: float = lerp(1000.0, WATER_THRESHOLD - 0.01, edge_mask)
			height = min(height, max_edge_height)

			if height > PLAIN_THRESHOLD:
				height += pow(height - PLAIN_THRESHOLD, 1.4)

			# Biomes
			var color: Color
			var tile_height: float = max(height * HEIGHT_SCALE, 0.5) # minimum 0.5 to see water
			if height < DEEP_WATER_THRESHOLD:
				color = Color(0.0, 0.0, 0.4)
			elif height < WATER_THRESHOLD:
				color = Color(0.0, 0.3, 0.8)
			elif height < SAND_THRESHOLD:
				color = Color(0.9, 0.8, 0.5)
			elif height < PLAIN_THRESHOLD:
				color = Color(0.1, 0.7, 0.2)
			else:
				color = Color(0.45, 0.35, 0.25)

			_draw_tile(x, y, TILE_SIZE, color, tile_height)

# -------------------------
# Draw 3D tile
# -------------------------
func _draw_tile(x: int, y: int, tile_size: float, color: Color, height: float) -> void:
	var mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(tile_size, height, tile_size)
	mesh_instance.mesh = box_mesh

	var material = StandardMaterial3D.new()
	material.albedo_color = color
	mesh_instance.material_override = material

	mesh_instance.position = Vector3(x * tile_size, height / 2.0, y * tile_size)
	add_child(mesh_instance)

# -------------------------
# Camera setup
# -------------------------
func _setup_camera() -> void:
	var cam = $Camera3D
	var map_center = SIZE * TILE_SIZE / 2.0
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
	light.transform.origin = Vector3(SIZE * TILE_SIZE / 2, 50, -SIZE * TILE_SIZE / 2)
	light.rotation_degrees = Vector3(-45, 45, 0)
	light.light_energy = 3.0
