class_name Constants

const SIZE: int = 50
const TILE_SIZE: float = 2.0        # world units per tile
const HEIGHT_SCALE: float = 2.0     # scale for mountain heights

# --- Island shape ---
const SHAPE_FREQ: float = 0.05
const SHAPE_OCTAVES: int = 3
const WARP_FREQ: float = 0.1
const WARP_STRENGTH: float = 2.5
const LAND_THRESHOLD: float = -0.3

# --- Edge safety ---
const EDGE_POWER: float = 2.0

# --- Height ---
const BASE_HEIGHT: float = 10.0
const DETAIL_FREQ: float = 0.08
const DETAIL_MULT: float = 4.0

# --- Biomes ---
const DEEP_WATER_THRESHOLD: float = -5.0
const WATER_THRESHOLD: float = 0.0
const SAND_THRESHOLD: float = 3.0
const PLAIN_THRESHOLD: float = 9.0
const HIGH_MOUNTAIN_THRESHOLD: float = 15.0
const SNOW_THRESHOLD: float = 18.0

# --- Fixed Heights for Flat Biomes ---
const SAND_HEIGHT: float = 1.0
const PLAIN_HEIGHT: float = 2.0
const MOUNTAIN_HEIGHT: float = 3.0
const HIGH_MOUNTAIN_HEIGHT: float = 4.0
const SNOW_HEIGHT: float = 5.0

# --- Villages ---
const VILLAGE_COUNT: int = 4
const MIN_VILLAGE_DISTANCE: float = 8.0  # minimum distance between villages in tiles
const VILLAGE_COLOR: Color = Color(1.0, 0.0, 0.0)  # red for villages

# --- Forests ---
const FOREST_SEED_CHANCE: float = 0.08  # Chance for a plain tile to start a forest patch
const FOREST_HEIGHT: float = 2.0   # Height for forest tiles (same as plains)
const FOREST_COLOR: Color = Color(0.0, 0.4, 0.1)  # Dark green for forests
const SNOW_COLOR: Color = Color(1.0, 1.0, 1.0)    # White for snow

# --- Resources ---
const FISH_SPAWN_CHANCE: float = 0.05  # Chance for a water tile to have fish
const FOREST_SPAWN_CHANCE: float = 0.08  # Chance for a plain tile to have forest
const FOREST_MIN_SIZE: int = 3     # Minimum tiles per forest patch
const FOREST_MAX_SIZE: int = 12    # Maximum tiles per forest patch

enum ResourceType {
	NONE,
	FISH,
	FOREST
}

enum Biome {
	DEEP_WATER,
	WATER,
	SAND,
	PLAIN,
	MOUNTAIN,
	HIGH_MOUNTAIN,
	SNOW
}
