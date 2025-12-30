class_name MapGenerator

const Constants = preload("res://constants.gd")
const Tile = preload("res://tile.gd")

static func generate_map() -> Array:
	var tiles: Array = []
	var half = Constants.SIZE / 2.0
	var noise: FastNoiseLite = FastNoiseLite.new()
	noise.seed = randi()
	noise.fractal_octaves = Constants.SHAPE_OCTAVES
	noise.frequency = Constants.SHAPE_FREQ

	for x in range(Constants.SIZE):
		for y in range(Constants.SIZE):
			var tile = create_tile(x, y, half, noise)
			tiles.append(tile)
	return tiles

static func create_tile(x: int, y: int, half: float, noise: FastNoiseLite) -> Tile:
	# Edge mask
	var cx: float = x - half
	var cy: float = y - half
	var edge_dist: float = Vector2(cx, cy).length() / half
	var edge_mask: float = pow(clamp(edge_dist, 0.0, 1.0), Constants.EDGE_POWER)

	# Domain warp
	var warp_x: float = noise.get_noise_2d(x * Constants.WARP_FREQ, y * Constants.WARP_FREQ) * Constants.WARP_STRENGTH
	var warp_y: float = noise.get_noise_2d((x+100) * Constants.WARP_FREQ, (y+100) * Constants.WARP_FREQ) * Constants.WARP_STRENGTH
	var wx: float = x + warp_x
	var wy: float = y + warp_y

	# Shape noise
	var shape: float = noise.get_noise_2d(wx, wy)

	# Smooth land factor
	var land_factor: float = clamp((shape - Constants.LAND_THRESHOLD) / 0.5, 0.0, 1.0)
	if land_factor <= 0.0 or edge_mask > 0.95:
		return Tile.new(x, y, 0.5, Constants.Biome.DEEP_WATER, Color(0.0, 0.0, 0.4))

	# Height
	var base_height: float = (1.0 - edge_mask) * Constants.BASE_HEIGHT * land_factor
	var detail: float = noise.get_noise_2d(x * Constants.DETAIL_FREQ, y * Constants.DETAIL_FREQ)
	var height: float = base_height + detail * Constants.DETAIL_MULT

	# Limit height near edges
	var max_edge_height: float = lerp(1000.0, Constants.WATER_THRESHOLD - 0.01, edge_mask)
	height = min(height, max_edge_height)

	if height > Constants.PLAIN_THRESHOLD:
		height += pow(height - Constants.PLAIN_THRESHOLD, 1.4)

	# Determine biome and color
	var biome: int
	var color: Color
	if height < Constants.DEEP_WATER_THRESHOLD:
		biome = Constants.Biome.DEEP_WATER
		color = Color(0.0, 0.0, 0.4)
	elif height < Constants.WATER_THRESHOLD:
		biome = Constants.Biome.WATER
		color = Color(0.0, 0.3, 0.8)
	elif height < Constants.SAND_THRESHOLD:
		biome = Constants.Biome.SAND
		color = Color(0.9, 0.8, 0.5)
	elif height < Constants.PLAIN_THRESHOLD:
		biome = Constants.Biome.PLAIN
		color = Color(0.1, 0.7, 0.2)
	else:
		biome = Constants.Biome.MOUNTAIN
		color = Color(0.45, 0.35, 0.25)

	# Set fixed height based on biome
	var tile_height: float
	if biome == Constants.Biome.DEEP_WATER or biome == Constants.Biome.WATER:
		tile_height = 0.5
	elif biome == Constants.Biome.SAND:
		tile_height = Constants.SAND_HEIGHT
	elif biome == Constants.Biome.PLAIN:
		tile_height = Constants.PLAIN_HEIGHT
	else:  # mountain
		tile_height = Constants.MOUNTAIN_HEIGHT

	return Tile.new(x, y, tile_height, biome, color)

static func place_villages(tiles: Array) -> void:
	var land_tiles: Array = []
	for tile in tiles:
		if tile.biome != Constants.Biome.DEEP_WATER and tile.biome != Constants.Biome.WATER:
			land_tiles.append(tile)
	
	var placed_villages: Array = []
	for i in range(Constants.VILLAGE_COUNT):
		var attempts = 0
		var max_attempts = 100
		while attempts < max_attempts:
			var random_tile = land_tiles[randi() % land_tiles.size()]
			var too_close = false
			for village in placed_villages:
				var dist = Vector2(random_tile.x - village.x, random_tile.y - village.y).length()
				if dist < Constants.MIN_VILLAGE_DISTANCE:
					too_close = true
					break
			if not too_close:
				random_tile.village_id = i + 1
				placed_villages.append(random_tile)
				break
			attempts += 1
