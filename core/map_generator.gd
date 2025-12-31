## Main orchestrator for procedural map generation.
## Coordinates terrain generation, biome assignment, and feature placement.
## Returns a dictionary with tiles array and villages array.
class_name MapGenerator

const Constants = preload("res://data/constants.gd")
const Tile = preload("res://data/tile.gd")
const Village = preload("res://data/village.gd")
const HeightGenerator = preload("res://core/height_generator.gd")
const BiomeSystem = preload("res://core/biome_system.gd")
const FeaturePlacer = preload("res://core/feature_placer.gd")

## Generate a complete map with terrain, biomes, and villages.
## Process: compute heights → scale heights → assign biomes → place features.
## Returns: {"tiles": Array[Tile], "villages": Array[Village]}
static func generate_map() -> Dictionary:
	var tiles: Array = []
	var villages: Array = []
	var half = Constants.SIZE / 2.0
	var noise: FastNoiseLite = FastNoiseLite.new()
	noise.seed = randi()
	noise.fractal_octaves = Constants.SHAPE_OCTAVES
	noise.frequency = Constants.SHAPE_FREQ

	# First pass: compute raw heights
	var raw_tiles: Array = []
	for x in range(Constants.SIZE):
		for y in range(Constants.SIZE):
			var height = HeightGenerator.compute_raw_height(x, y, half, noise)
			raw_tiles.append({"x": x, "y": y, "height": height})

	# Scale heights to ensure deep sea and high mountains
	HeightGenerator.scale_heights(raw_tiles)

	# Second pass: create tiles with biomes
	for raw in raw_tiles:
		var biome = BiomeSystem.determine_biome(raw.height)
		var color = BiomeSystem.get_biome_color(biome)
		var tile_height = BiomeSystem.get_biome_height(biome)
		var tile = Tile.new(raw.x, raw.y, tile_height, biome, color)
		tiles.append(tile)

	# Third pass: add features (forests and villages)
	FeaturePlacer.place_forests(tiles)
	villages = FeaturePlacer.place_villages(tiles)
	FeaturePlacer.place_resources(tiles)

	return {"tiles": tiles, "villages": villages}
