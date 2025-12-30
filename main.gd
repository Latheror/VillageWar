extends Node3D

const SIZE: int = 30
const TILE_SIZE: float = 1.0  # In 3D, 1 unit per tile

# --- Island shape ---
const SHAPE_FREQ: float = 0.05
const SHAPE_OCTAVES: int = 3
const WARP_FREQ: float = 0.1
const WARP_STRENGTH: float = 2.5
const LAND_THRESHOLD: float = 0.0   # début de la terre

# --- Edge safety ---
const EDGE_POWER: float = 6.0

# --- Height ---
const BASE_HEIGHT: float = 18.0
const DETAIL_FREQ: float = 0.08
const DETAIL_MULT: float = 4.0
const HEIGHT_SCALE: float = 0.1

# --- Biomes ---
const DEEP_WATER_THRESHOLD: float = -6.0
const WATER_THRESHOLD: float = 0.0
const SAND_THRESHOLD: float = 3.0
const PLAIN_THRESHOLD: float = 9.0


func _ready() -> void:
	var half: float = SIZE / 2.0

	var noise: FastNoiseLite = FastNoiseLite.new()
	noise.seed = randi()
	noise.fractal_octaves = SHAPE_OCTAVES
	noise.frequency = SHAPE_FREQ

	for x in range(SIZE):
		for y in range(SIZE):

			# -------------------------
			# Edge mask
			# -------------------------
			var cx: float = x - half
			var cy: float = y - half
			var edge_dist: float = Vector2(cx, cy).length() / half
			var edge_mask: float = pow(clamp(edge_dist, 0.0, 1.0), EDGE_POWER)

			# -------------------------
			# Warp coordinates (moderate)
			# -------------------------
			var warp_x: float = noise.get_noise_2d(x * WARP_FREQ, y * WARP_FREQ) * WARP_STRENGTH
			var warp_y: float = noise.get_noise_2d((x+100) * WARP_FREQ, (y+100) * WARP_FREQ) * WARP_STRENGTH
			var wx: float = x + warp_x
			var wy: float = y + warp_y

			# -------------------------
			# Shape noise (multi-octave)
			# -------------------------
			var shape: float = noise.get_noise_2d(wx, wy)

			# -------------------------
			# Smooth land factor (soft transition to water)
			# -------------------------
			var land_factor: float = clamp((shape - LAND_THRESHOLD) / 0.5, 0.0, 1.0)

			# Skip tiles that are basically water or near edges
			if land_factor <= 0.0 or edge_mask > 0.95:
				_draw_tile(x, y, TILE_SIZE, Color(0.0, 0.0, 0.4), 0.1)
				continue

			# -------------------------
			# Height
			# -------------------------
			var base_height: float = (1.0 - edge_mask) * BASE_HEIGHT * land_factor
			var detail: float = noise.get_noise_2d(x * DETAIL_FREQ, y * DETAIL_FREQ)
			var height: float = base_height + detail * DETAIL_MULT

			# Limit height near edges (no sand at map edge)
			var max_edge_height: float = lerp(1000.0, WATER_THRESHOLD - 0.01, edge_mask)
			height = min(height, max_edge_height)

			# Mountain exaggeration
			if height > PLAIN_THRESHOLD:
				height += pow(height - PLAIN_THRESHOLD, 1.4)

			# -------------------------
			# Biomes
			# -------------------------
			var color: Color
			var tile_height: float = 0.1  # default for water
			if height < DEEP_WATER_THRESHOLD:
				color = Color(0.0, 0.0, 0.4)
			elif height < WATER_THRESHOLD:
				color = Color(0.0, 0.3, 0.8)
			else:
				# Land
				tile_height = max(height * HEIGHT_SCALE, 0.1)
				if height < SAND_THRESHOLD:
					color = Color(0.9, 0.8, 0.5)  # sand
				elif height < PLAIN_THRESHOLD:
					color = Color(0.1, 0.7, 0.2)  # plains
				else:
					color = Color(0.45, 0.35, 0.25)  # mountains

			_draw_tile(x, y, TILE_SIZE, color, tile_height)


func _draw_tile(x: int, y: int, tile_size: float, color: Color, height: float) -> void:
	var mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(tile_size, height, tile_size)
	mesh_instance.mesh = box_mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	mesh_instance.material_override = material
	
	mesh_instance.position = Vector3(x * tile_size, height / 2, y * tile_size)
	add_child(mesh_instance)
