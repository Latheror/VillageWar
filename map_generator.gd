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

	# First pass: compute raw heights
	var raw_tiles: Array = []
	for x in range(Constants.SIZE):
		for y in range(Constants.SIZE):
			var height = compute_raw_height(x, y, half, noise)
			raw_tiles.append({"x": x, "y": y, "height": height})

	# Scale heights to ensure deep sea and high mountains
	scale_heights(raw_tiles)

	# Second pass: create tiles with biomes
	for raw in raw_tiles:
		var biome = determine_biome(raw.height)
		var color = get_biome_color(biome)
		var tile_height = get_tile_height(biome)
		var tile = Tile.new(raw.x, raw.y, tile_height, biome, color)
		tiles.append(tile)
	return tiles

static func scale_heights(raw_tiles: Array) -> void:
	var heights: Array = []
	for raw in raw_tiles:
		heights.append(raw.height)
	var min_h: float = heights.min()
	var max_h: float = heights.max()
	var desired_min: float = Constants.DEEP_WATER_THRESHOLD - 1.0  # -6.0
	var desired_max: float = Constants.HIGH_MOUNTAIN_THRESHOLD + 5.0  # 20.0
	if max_h == min_h:
		# If all heights are the same, set min to desired_min and max to desired_max for variety
		for i in range(raw_tiles.size()):
			if i == 0:
				raw_tiles[i].height = desired_max
			else:
				raw_tiles[i].height = desired_min
	else:
		for raw in raw_tiles:
			raw.height = (raw.height - min_h) / (max_h - min_h) * (desired_max - desired_min) + desired_min

static func compute_raw_height(x: int, y: int, half: float, noise: FastNoiseLite) -> float:
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

	# Height
	var base_height: float = (1.0 - edge_mask) * Constants.BASE_HEIGHT * land_factor
	var detail: float = noise.get_noise_2d(x * Constants.DETAIL_FREQ, y * Constants.DETAIL_FREQ)
	var height: float = base_height + detail * Constants.DETAIL_MULT

	# Limit height near edges to prevent unnatural spikes, but allow water
	var max_edge_height: float = lerp(1000.0, Constants.PLAIN_THRESHOLD, edge_mask)
	height = min(height, max_edge_height)

	if height > Constants.PLAIN_THRESHOLD:
		height += pow(height - Constants.PLAIN_THRESHOLD, 1.4)

	return height

static func determine_biome(height: float) -> int:
	if height < Constants.DEEP_WATER_THRESHOLD:
		return Constants.Biome.DEEP_WATER
	elif height < Constants.WATER_THRESHOLD:
		return Constants.Biome.WATER
	elif height < Constants.SAND_THRESHOLD:
		return Constants.Biome.SAND
	elif height < Constants.PLAIN_THRESHOLD:
		return Constants.Biome.PLAIN
	elif height < Constants.HIGH_MOUNTAIN_THRESHOLD:
		return Constants.Biome.MOUNTAIN
	else:
		return Constants.Biome.HIGH_MOUNTAIN

static func get_biome_color(biome: int) -> Color:
	match biome:
		Constants.Biome.DEEP_WATER:
			return Color(0.0, 0.0, 0.4)
		Constants.Biome.WATER:
			return Color(0.0, 0.3, 0.8)
		Constants.Biome.SAND:
			return Color(0.9, 0.8, 0.5)
		Constants.Biome.PLAIN:
			return Color(0.1, 0.7, 0.2)
		Constants.Biome.MOUNTAIN:
			return Color(0.45, 0.35, 0.25)
		Constants.Biome.HIGH_MOUNTAIN:
			return Color(0.5, 0.5, 0.5)
		_:
			return Color(1.0, 0.0, 1.0)  # error

static func get_tile_height(biome: int) -> float:
	match biome:
		Constants.Biome.DEEP_WATER, Constants.Biome.WATER:
			return 0.5
		Constants.Biome.SAND:
			return Constants.SAND_HEIGHT
		Constants.Biome.PLAIN:
			return Constants.PLAIN_HEIGHT
		Constants.Biome.MOUNTAIN:
			return Constants.MOUNTAIN_HEIGHT
		Constants.Biome.HIGH_MOUNTAIN:
			return Constants.HIGH_MOUNTAIN_HEIGHT
		_:
			return 0.5

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
