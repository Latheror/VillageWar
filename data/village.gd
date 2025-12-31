class_name Village
const Constants = preload("res://data/constants.gd")

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
	# Ensure initial population does not exceed housing
	var max_pop = 5 * tile_count
	if people > max_pop:
		people = max_pop

func get_info_text() -> String:
	var max_pop = 5 * tile_count
	var display_people = people
	if people > max_pop:
		display_people = max_pop
		print("[Village] Clamping displayed population for %s: %d -> %d" % [name, people, max_pop])
	return "%s\nTiles: %d\nPeople: %d\nFood: %d\nWood: %d" % [name, tile_count, display_people, food, wood]

func get_worker_positions(tiles: Array) -> Array:
	# Returns an array of Vector2 tile positions for each villager (length == people)
	var positions: Array = []

	# Collect owned tiles by type
	var farm_tiles: Array = []
	var boat_tiles: Array = []
	var house_tiles: Array = []
	var fish_positions: Array = []

	for t in tiles:
		if t.resource == Constants.ResourceType.FISH:
			fish_positions.append(Vector2(t.x, t.y))
		if t.village_id == id:
			if t.resource == Constants.ResourceType.FARM:
				farm_tiles.append(Vector2(t.x, t.y))
			elif t.resource == Constants.ResourceType.FISHING_BOAT:
				boat_tiles.append(Vector2(t.x, t.y))
			elif t.resource == Constants.ResourceType.NONE:
				house_tiles.append(Vector2(t.x, t.y))

	var remaining = people

	# Assign workers to farms first (2 workers per farm)
	for fpos in farm_tiles:
		if remaining >= 2:
			positions.append(fpos)
			positions.append(fpos)
			remaining -= 2
		else:
			break

	# Assign workers to operating boats (2 workers per operating boat)
	for bpos in boat_tiles:
		if remaining < 2:
			break
		# Check if there is accessible fish within range 5
		var min_dist = INF
		for fpos in fish_positions:
			var dist = abs(bpos.x - fpos.x) + abs(bpos.y - fpos.y)
			if dist < min_dist:
				min_dist = dist
		if min_dist <= 5:
			positions.append(bpos)
			positions.append(bpos)
			remaining -= 2

	# Remaining villagers idle: place them on house tiles (or village center if none)
	if house_tiles.size() == 0:
		# fallback to village center
		for i in range(remaining):
			positions.append(position)
	else:
		for i in range(remaining):
			positions.append(house_tiles[i % house_tiles.size()])

	# Ensure positions length equals people (if people changed elsewhere, adjust)
	while positions.size() < people:
		positions.append(position)
	while positions.size() > people:
		positions.pop_back()

	return positions

func perform_daily_action(tiles: Array, constants) -> bool:
	var changed: bool = false
	collect_resources(tiles, constants)
	consume_food()
	try_population_growth(tiles)
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
	
	# Determine action based on needs (survival first)
	var survival_needed = food < people

	var build_farm_score = 0
	var build_boat_score = 0
	var cut_wood_score = 0
	var colonize_score = 0
	var build_house_score = 0

	# Strongly prefer food-producing structures when starving
	if wood >= 5:
		if food < people:  # Immediate shortage: highest priority
			build_farm_score += 50
			build_boat_score += 50
		# Build additional staffed farms only if there are free worker pairs
		if producing_farms < int(people / 2.0):
			build_farm_score += 10
		# Boats only if can staff more boats
		if boat_count < int(people / 2.0):
			build_boat_score += 5
		# Expand production during surplus, but with moderate priority
		if surplus:
			build_farm_score += 15
			build_boat_score += 15

	# Maintain a healthy wood buffer; cutting wood helps build farms/boats
	if wood < 30:
		cut_wood_score += 40
	if survival_needed:
		# If starving, also prioritize cutting wood so we can build food sources
		cut_wood_score += 20

	# Only consider colonization if survival isn't urgent
	if not survival_needed and wood >= 10:
		if people < 2 * farm_count:  # Need more workers for farms
			colonize_score += 10
		if people >= 4 * tile_count:  # Need more housing capacity
			colonize_score += 10

	# If at or above housing capacity, strongly prefer building a new house tile
	var current_capacity = 5 * tile_count
	if people >= current_capacity and wood >= 10:
		# Build house to increase capacity (cost 10 wood)
		build_house_score += 80
	
	# Select action with highest score, or random if tie
	var actions_scores = {
		"build_farm": build_farm_score,
		"cut_wood": cut_wood_score,
		"colonize": colonize_score,
		"build_house": build_house_score,
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
		changed = try_colonize(tiles, constants)
	elif action == "build_house":
		changed = try_build_house(tiles, constants)
	elif action == "cut_wood":
		changed = try_cut_wood(tiles, constants)
	elif action == "build_farm":
		changed = try_build_farm(tiles, constants)
	elif action == "build_fishing_boat":
		changed = try_build_fishing_boat(tiles, constants)

	# Ensure population doesn't exceed new capacity after actions
	_enforce_population_cap()
	return changed

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

func try_population_growth(tiles = null) -> void:
	# Determine actual owned tiles at this moment to avoid growing beyond capacity
	var owned_tiles = tile_count
	if tiles != null:
		owned_tiles = 0
		for t in tiles:
			if t.village_id == id:
				owned_tiles += 1

	# Only grow if there is capacity for one more person
	if people + 1 <= 5 * owned_tiles and food >= 5 and food > people:
		if randf() < 0.3:  # 30% chance
			people += 1
			food -= 5
			_enforce_population_cap()

func try_build_farm(tiles: Array, constants) -> bool:
	if wood < 5:
		return false  # Cost 5 wood
	
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
		return true

	return false

func try_build_fishing_boat(tiles: Array, constants) -> bool:
	if wood < 5:
		return false  # Cost 5 wood
	
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
		return true

	return false

func _enforce_population_cap() -> void:
	var max_pop = 5 * tile_count
	if people > max_pop:
		people = max_pop

func try_colonize(tiles: Array, constants) -> bool:
	if wood < 10:
		return false  # Not enough wood
	
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
		return true

	return false

func try_build_house(tiles: Array, constants) -> bool:
	# Build a house by claiming an adjacent plain tile (cost 10 wood)
	if wood < 10:
		return false

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
							# Claim only plain tiles that are unclaimed and have no resource
							if t.village_id == 0 and t.resource == constants.ResourceType.NONE and t.biome == constants.Biome.PLAIN:
								candidate_tiles.append(t)
							break

	# Claim the first available candidate as housing (reserve as village-owned NONE)
	if candidate_tiles.size() > 0:
		var target = candidate_tiles[0]
		target.village_id = id
		wood -= 10
		return true

	return false

func try_cut_wood(tiles: Array, constants) -> bool:
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
		return true

	return false

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
