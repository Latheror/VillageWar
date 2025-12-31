class_name Village

var id: int
var name: String
var position: Vector2  # tile coordinates
var people: int = 5
var food: int = 50
var wood: int = 30
var tile_count: int = 1  # Starts with 1 (center tile)

func _init(village_id: int, pos: Vector2, village_name: String = ""):
	id = village_id
	position = pos
	if village_name == "":
		name = "Village %d" % id
	else:
		name = village_name

func get_info_text() -> String:
	return "%s\nTiles: %d\nPeople: %d\nFood: %d\nWood: %d" % [name, tile_count, people, food, wood]

func perform_daily_action(tiles: Array, constants) -> void:
	collect_resources(tiles, constants)
	consume_food()
	try_population_growth()
	_enforce_population_cap()
	
	# Calculate current farm stats
	var farm_count = 0
	for tile in tiles:
		if tile.village_id == id and tile.resource == constants.ResourceType.FARM:
			farm_count += 1
	var producing_farms = min(farm_count, int(people / 2.0))
	
	var boat_count = 0
	for tile in tiles:
		if tile.village_id == id and tile.resource == constants.ResourceType.FISHING_BOAT:
			boat_count += 1
	var operating_boats = 0
	if people >= 2 * boat_count:
		var fish_positions = []
		for tile in tiles:
			if tile.resource == constants.ResourceType.FISH:
				fish_positions.append(Vector2(tile.x, tile.y))
		for tile in tiles:
			if tile.village_id == id and tile.resource == constants.ResourceType.FISHING_BOAT:
				var min_dist = INF
				for f_pos in fish_positions:
					var dist = abs(tile.x - f_pos.x) + abs(tile.y - f_pos.y)
					if dist < min_dist:
						min_dist = dist
				if min_dist <= 5:
					operating_boats += 1
	
	var current_production = 5 * producing_farms + 5 * operating_boats
	var surplus = current_production > people
	
	# Determine action based on needs
	var build_farm_score = 0
	if wood >= 5:
		if food < people:  # Low food supply
			build_farm_score += 10
		if producing_farms < int(people / 2.0):  # Can staff more farms
			build_farm_score += 5
		if surplus:  # Net food production > population
			build_farm_score += 10
	
	var build_boat_score = 0
	if wood >= 5:
		if food < people:  # Low food supply
			build_boat_score += 10
		if surplus:  # Net food production > population
			build_boat_score += 10
	
	var cut_wood_score = 0
	if wood < 40:  # Maintain wood supply
		cut_wood_score += 15
	
	var colonize_score = 0
	if wood >= 10:
		if people < 2 * farm_count:  # Need more workers for farms
			colonize_score += 10
		if people >= 4 * tile_count:  # Need more housing capacity
			colonize_score += 10
	
	# Select action with highest score, or random if tie
	var actions_scores = {
		"build_farm": build_farm_score,
		"cut_wood": cut_wood_score,
		"colonize": colonize_score,
		"build_fishing_boat": build_boat_score
	}
	
	var max_score = 0
	for score in actions_scores.values():
		if score > max_score:
			max_score = score
	
	var candidate_actions = []
	for action in actions_scores:
		if actions_scores[action] == max_score:
			candidate_actions.append(action)
	
	var action = candidate_actions[randi() % candidate_actions.size()]
	
	if action == "colonize":
		try_colonize(tiles, constants)
	elif action == "cut_wood":
		try_cut_wood(tiles, constants)
	elif action == "build_farm":
		try_build_farm(tiles, constants)
	elif action == "build_fishing_boat":
		try_build_fishing_boat(tiles, constants)

func collect_resources(tiles: Array, constants) -> void:
	var farm_count = 0
	for tile in tiles:
		if tile.village_id == id and tile.resource == constants.ResourceType.FARM:
			farm_count += 1
	
	var producing_farms = min(farm_count, int(people / 2.0))
	food += 5 * producing_farms  # Each farm requires 2 workers
	
	var boat_count = 0
	for tile in tiles:
		if tile.village_id == id and tile.resource == constants.ResourceType.FISHING_BOAT:
			boat_count += 1
	
	if people >= 2 * boat_count:
		var fish_positions = []
		for tile in tiles:
			if tile.resource == constants.ResourceType.FISH:
				fish_positions.append(Vector2(tile.x, tile.y))
		
		var operating_boats = 0
		for tile in tiles:
			if tile.village_id == id and tile.resource == constants.ResourceType.FISHING_BOAT:
				var min_dist = INF
				for f_pos in fish_positions:
					var dist = abs(tile.x - f_pos.x) + abs(tile.y - f_pos.y)
					if dist < min_dist:
						min_dist = dist
				if min_dist <= 5:
					operating_boats += 1
		
		food += 5 * operating_boats  # Each operating boat gives 5 food

func consume_food() -> void:
	var needed = people
	if food >= needed:
		food -= needed
	else:
		people -= (needed - food)
		food = 0
		if people < 1:
			people = 1  # Minimum 1

func try_population_growth() -> void:
	if people < 5 * tile_count and food >= 5 and food > people:  # Enough houses, food excess, and can afford 5 food
		if randf() < 0.3:  # 30% chance
			people += 1
			food -= 5
			_enforce_population_cap()

func try_build_farm(tiles: Array, constants) -> void:
	if wood < 5:
		return  # Cost 5 wood
	
	# Find adjacent plain tiles without resource to any owned tile
	var candidate_tiles = []
	for tile in tiles:
		if tile.village_id == id:
			var adjacent_positions = [
				Vector2(tile.x, tile.y) + Vector2(0, 1),
				Vector2(tile.x, tile.y) + Vector2(0, -1),
				Vector2(tile.x, tile.y) + Vector2(1, 0),
				Vector2(tile.x, tile.y) + Vector2(-1, 0)
			]
			for adj_pos in adjacent_positions:
				var already_candidate = false
				for cand in candidate_tiles:
					if cand.x == adj_pos.x and cand.y == adj_pos.y:
						already_candidate = true
						break
				if not already_candidate:
					for t in tiles:
						if t.x == adj_pos.x and t.y == adj_pos.y:
							if t.village_id == 0 and t.resource == constants.ResourceType.NONE and t.biome == constants.Biome.PLAIN:
								candidate_tiles.append(t)
							break
	
	# Build on the first candidate
	if candidate_tiles.size() > 0:
		var target_tile = candidate_tiles[0]
		target_tile.resource = constants.ResourceType.FARM
		target_tile.village_id = id  # Claim the tile
		wood -= 5
		tile_count += 1

func try_build_fishing_boat(tiles: Array, constants) -> void:
	if wood < 5:
		return  # Cost 5 wood
	
	# Find adjacent water tiles without resource to any owned tile
	var candidate_tiles = []
	for tile in tiles:
		if tile.village_id == id:
			var adjacent_positions = [
				Vector2(tile.x, tile.y) + Vector2(0, 1),
				Vector2(tile.x, tile.y) + Vector2(0, -1),
				Vector2(tile.x, tile.y) + Vector2(1, 0),
				Vector2(tile.x, tile.y) + Vector2(-1, 0)
			]
			for adj_pos in adjacent_positions:
				var already_candidate = false
				for cand in candidate_tiles:
					if cand.x == adj_pos.x and cand.y == adj_pos.y:
						already_candidate = true
						break
				if not already_candidate:
					for t in tiles:
						if t.x == adj_pos.x and t.y == adj_pos.y:
							if t.village_id == 0 and t.resource == constants.ResourceType.NONE and (t.biome == constants.Biome.WATER or t.biome == constants.Biome.DEEP_WATER) and _is_adjacent_to_land(t, tiles, constants):
								candidate_tiles.append(t)
							break
	
	# Build on the first candidate
	if candidate_tiles.size() > 0:
		var target_tile = candidate_tiles[0]
		target_tile.resource = constants.ResourceType.FISHING_BOAT
		target_tile.village_id = id  # Claim the tile
		wood -= 5
		tile_count += 1

func _enforce_population_cap() -> void:
	var max_pop = 5 * tile_count
	if people > max_pop:
		people = max_pop

func try_colonize(tiles: Array, constants) -> void:
	if wood < 10:
		return  # Not enough wood
	
	# Find adjacent tiles to any owned tile
	var candidate_tiles = []
	for tile in tiles:
		if tile.village_id == id:
			var adjacent_positions = [
				Vector2(tile.x, tile.y) + Vector2(0, 1),
				Vector2(tile.x, tile.y) + Vector2(0, -1),
				Vector2(tile.x, tile.y) + Vector2(1, 0),
				Vector2(tile.x, tile.y) + Vector2(-1, 0)
			]
			for adj_pos in adjacent_positions:
				# Check if not already in candidates
				var already_candidate = false
				for cand in candidate_tiles:
					if cand.x == adj_pos.x and cand.y == adj_pos.y:
						already_candidate = true
						break
				if not already_candidate:
					for t in tiles:
						if t.x == adj_pos.x and t.y == adj_pos.y:
							if (t.village_id == 0 and 
								t.resource == constants.ResourceType.NONE and
								t.biome != constants.Biome.DEEP_WATER and 
								t.biome != constants.Biome.WATER):
								candidate_tiles.append(t)
							break
	
	# Colonize the first candidate
	if candidate_tiles.size() > 0:
		var target_tile = candidate_tiles[0]
		target_tile.village_id = id
		wood -= 10
		tile_count += 1

func try_cut_wood(tiles: Array, constants) -> void:
	# Find forest tiles within 5 tiles from any owned tile
	var village_positions = []
	for tile in tiles:
		if tile.village_id == id:
			village_positions.append(Vector2(tile.x, tile.y))
	
	var candidate_tiles = []
	for tile in tiles:
		if tile.resource == constants.ResourceType.FOREST:
			var min_dist = INF
			for v_pos in village_positions:
				var dist = abs(tile.x - v_pos.x) + abs(tile.y - v_pos.y)
				if dist < min_dist:
					min_dist = dist
			if min_dist <= 5:
				candidate_tiles.append({"tile": tile, "dist": min_dist})
	
	# Sort by distance (closest first)
	candidate_tiles.sort_custom(func(a, b): return a.dist < b.dist)
	
	# Cut the closest candidate
	if candidate_tiles.size() > 0:
		var target_tile = candidate_tiles[0].tile
		target_tile.resource = constants.ResourceType.NONE
		wood += 5

func _is_adjacent_to_land(tile, tiles: Array, constants) -> bool:
	var adjacent_positions = [
		Vector2(tile.x, tile.y) + Vector2(0, 1),
		Vector2(tile.x, tile.y) + Vector2(0, -1),
		Vector2(tile.x, tile.y) + Vector2(1, 0),
		Vector2(tile.x, tile.y) + Vector2(-1, 0)
	]
	for adj_pos in adjacent_positions:
		for t in tiles:
			if t.x == adj_pos.x and t.y == adj_pos.y:
				if t.biome != constants.Biome.DEEP_WATER and t.biome != constants.Biome.WATER:
					return true
				break
	return false
