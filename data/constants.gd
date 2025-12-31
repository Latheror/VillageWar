## Global constants and configuration for the VillageWar game.
## Includes map parameters, biome thresholds, village settings, and resource spawn rates.
class_name Constants

# ==================== Map Dimensions ====================
const SIZE: int = 50
const TILE_SIZE: float = 2.0        # world units per tile
const HEIGHT_SCALE: float = 2.0     # scale for mountain heights

# ==================== Terrain Generation ====================
# --- Island shape ---
const SHAPE_FREQ: float = 0.05
const SHAPE_OCTAVES: int = 3
const WARP_FREQ: float = 0.1
const WARP_STRENGTH: float = 2.5
const LAND_THRESHOLD: float = -0.3

# --- Edge falloff to prevent land at map edges ---
const EDGE_POWER: float = 2.0

# --- Height variation and detail ---
const BASE_HEIGHT: float = 10.0
const DETAIL_FREQ: float = 0.08
const DETAIL_MULT: float = 4.0

# ==================== Biome Thresholds ====================
# Biomes are determined by height using these thresholds (lower elevation = deeper water)
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

# ==================== Village Configuration ====================
# Villages spawn on plains and manage resources (food, wood) and population growth
const VILLAGE_COUNT: int = 4
const MIN_VILLAGE_DISTANCE: float = 8.0  # minimum distance between villages in tiles
const VILLAGE_COLOR: Color = Color(1.0, 0.0, 0.0)  # red for villages

# ==================== Resource Generation ====================
const FISH_SPAWN_CHANCE: float = 0.05  # Chance for a water tile to have fish
const FOREST_SEED_CHANCE: float = 0.08  # Chance for a plain tile to start a forest patch
const FOREST_HEIGHT: float = 2.0   # Height for forest tiles (same as plains)
const FOREST_COLOR: Color = Color(0.0, 0.4, 0.1)  # Dark green for forests
const SNOW_COLOR: Color = Color(1.0, 1.0, 1.0)    # White for snow
const FOREST_MIN_SIZE: int = 3     # Minimum tiles per forest patch
const FOREST_MAX_SIZE: int = 12    # Maximum tiles per forest patch

# ==================== Enums ====================
## Resource types that can exist on tiles
enum ResourceType {
	NONE,           # Empty tile (or house tile when village-owned)
	FISH,           # Fish resource (on water)
	FOREST,         # Forest trees (on plains)
	FARM,           # Agricultural land (village resource)
	FISHING_BOAT    # Fishing boat (on water, village resource)
}

## Biome types from lowest elevation (water) to highest (snow)
enum Biome {
	DEEP_WATER,
	WATER,
	SAND,
	PLAIN,
	MOUNTAIN,
	HIGH_MOUNTAIN,
	SNOW
}
