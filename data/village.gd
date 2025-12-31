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
	# Randomly choose action
	var actions = ["colonize", "cut_wood", "build_farm"]
	var action = actions[randi() % actions.size()]
	
	if action == "colonize":
		try_colonize(tiles, constants)
	elif action == "cut_wood":
		try_cut_wood(tiles, constants)
	elif action == "build_farm":
		try_build_farm(tiles, constants)

func collect_resources(tiles: Array, constants) -> void:
	for tile in tiles:
		if tile.village_id == id and tile.resource == constants.ResourceType.FARM:
			food += 2  # Farms produce 2 food per day

func consume_food() -> void:
	food -= people  # Each person consumes 1 food per day
	if food < 0:
		food = 0
		# Optional: reduce population if starving
		if people > 1:
			people -= 1

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
							if t.resource == constants.ResourceType.NONE and t.biome == constants.Biome.PLAIN:
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
	# Find adjacent forest tiles to any owned tile
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
							if t.resource == constants.ResourceType.FOREST:
								candidate_tiles.append(t)
							break
	
	# Cut the first candidate
	if candidate_tiles.size() > 0:
		var target_tile = candidate_tiles[0]
		target_tile.resource = constants.ResourceType.NONE
		wood += 5
