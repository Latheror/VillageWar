class_name Village

var id: int
var name: String
var position: Vector2  # tile coordinates
var people: int = 10
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
	
	# Calculate current farm stats
	var farm_count = 0
	for tile in tiles:
		if tile.village_id == id and tile.resource == constants.ResourceType.FARM:
			farm_count += 1
	var producing_farms = min(farm_count, int(people / 2.0))
	
	# Determine action based on needs
	var build_farm_score = 0
	if wood >= 5:
		if food < people:  # Low food supply
			build_farm_score += 10
		if producing_farms < farm_count:  # Not all farms are working
			build_farm_score += 5
	
	var cut_wood_score = 0
	if wood < 20:  # Low wood
		cut_wood_score += 10
	
	var colonize_score = 0
	if wood >= 10:
		if people < 2 * farm_count:  # Need more workers for farms
			colonize_score += 10
		if tile_count < 10:  # Expand territory
			colonize_score += 5
	
	# Select action with highest score, or random if tie
	var actions_scores = {
		"build_farm": build_farm_score,
		"cut_wood": cut_wood_score,
		"colonize": colonize_score
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

func collect_resources(tiles: Array, constants) -> void:
	var farm_count = 0
	for tile in tiles:
		if tile.village_id == id and tile.resource == constants.ResourceType.FARM:
			farm_count += 1
	
	var producing_farms = min(farm_count, int(people / 2.0))
	food += 5 * producing_farms  # Each farm requires 2 workers

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
	if food > 0 and people < 50:  # Max population 50
		if randf() < 0.3:  # 30% chance
			people += 1
			food -= 1

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
				candidate_tiles.append(tile)
	
	# Cut the first candidate
	if candidate_tiles.size() > 0:
		var target_tile = candidate_tiles[0]
		target_tile.resource = constants.ResourceType.NONE
		wood += 5
