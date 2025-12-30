class_name BiomeSystem

const Constants = preload("res://data/constants.gd")

# -------------------------
# Determine biome based on height
# -------------------------
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
	elif height < Constants.SNOW_THRESHOLD:
		return Constants.Biome.HIGH_MOUNTAIN
	else:
		return Constants.Biome.SNOW

# -------------------------
# Get color for biome
# -------------------------
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
		Constants.Biome.FOREST:
			return Constants.FOREST_COLOR
		Constants.Biome.MOUNTAIN:
			return Color(0.45, 0.35, 0.25)
		Constants.Biome.HIGH_MOUNTAIN:
			return Color(0.5, 0.5, 0.5)
		Constants.Biome.SNOW:
			return Constants.SNOW_COLOR
		_:
			return Color(1.0, 0.0, 1.0)  # error

# -------------------------
# Get height for biome
# -------------------------
static func get_biome_height(biome: int) -> float:
	match biome:
		Constants.Biome.DEEP_WATER, Constants.Biome.WATER:
			return 0.5
		Constants.Biome.SAND:
			return Constants.SAND_HEIGHT
		Constants.Biome.PLAIN:
			return Constants.PLAIN_HEIGHT
		Constants.Biome.FOREST:
			return Constants.FOREST_HEIGHT
		Constants.Biome.MOUNTAIN:
			return Constants.MOUNTAIN_HEIGHT
		Constants.Biome.HIGH_MOUNTAIN:
			return Constants.HIGH_MOUNTAIN_HEIGHT
		Constants.Biome.SNOW:
			return Constants.SNOW_HEIGHT
		_:
			return 0.5