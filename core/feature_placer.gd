class_name FeaturePlacer

const Constants = preload("res://data/constants.gd")

# -------------------------
# Place forest patches on plain tiles as resources
# -------------------------
static func place_forests(tiles: Array) -> void:
	# Get all plain tiles without existing resources
	var plain_tiles: Array = []
	for tile in tiles:
		if tile.biome == Constants.Biome.PLAIN and tile.resource == Constants.ResourceType.NONE:
			plain_tiles.append(tile)

	if plain_tiles.size() == 0:
		return

	# Create forest patches probabilistically
	var used_tiles: Array = []

	for plain_tile in plain_tiles:
		# Skip if already used in a forest patch
		if used_tiles.has(plain_tile):
			continue

		# Chance to start a forest patch
		if randf() < Constants.FOREST_SPAWN_CHANCE:
			# Determine patch size
			var patch_size = randi() % (Constants.FOREST_MAX_SIZE - Constants.FOREST_MIN_SIZE + 1) + Constants.FOREST_MIN_SIZE

			# Grow the forest patch
			var patch_tiles: Array = [plain_tile]
			used_tiles.append(plain_tile)

			while patch_tiles.size() < patch_size:
				# Find neighbors of current patch
				var neighbors: Array = []
				for patch_tile in patch_tiles:
					# Check all 4 adjacent tiles
					var directions = [Vector2(0, 1), Vector2(0, -1), Vector2(1, 0), Vector2(-1, 0)]
					for dir in directions:
						var neighbor_x = patch_tile.x + int(dir.x)
						var neighbor_y = patch_tile.y + int(dir.y)

						# Find the neighbor tile
						for tile in plain_tiles:
							if tile.x == neighbor_x and tile.y == neighbor_y and not used_tiles.has(tile):
								if not neighbors.has(tile):
									neighbors.append(tile)
								break

				if neighbors.size() == 0:
					break

				# Pick a random neighbor to add
				var neighbor_index = randi() % neighbors.size()
				var new_tile = neighbors[neighbor_index]

				patch_tiles.append(new_tile)
				used_tiles.append(new_tile)

			# Add forest resource to patch tiles
			for tile in patch_tiles:
				tile.resource = Constants.ResourceType.FOREST

# -------------------------
# Place villages on land tiles
# -------------------------
static func place_villages(tiles: Array) -> void:
	var land_tiles: Array = []
	for tile in tiles:
		# Exclude water, mountains, and snow - villages can only be on sand, plains
		if (tile.biome != Constants.Biome.DEEP_WATER and 
			tile.biome != Constants.Biome.WATER and
			tile.biome != Constants.Biome.MOUNTAIN and
			tile.biome != Constants.Biome.HIGH_MOUNTAIN and
			tile.biome != Constants.Biome.SNOW):
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

# -------------------------
# Place resources on tiles
# -------------------------
static func place_resources(tiles: Array) -> void:
	for tile in tiles:
		# Place fish on water tiles
		if tile.biome == Constants.Biome.WATER or tile.biome == Constants.Biome.DEEP_WATER:
			if randf() < Constants.FISH_SPAWN_CHANCE:
				tile.resource = Constants.ResourceType.FISH