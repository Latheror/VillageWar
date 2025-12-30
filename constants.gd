class_name Constants

const SIZE: int = 30
const TILE_SIZE: float = 2.0        # world units per tile
const HEIGHT_SCALE: float = 1.0     # scale for mountain heights

# --- Island shape ---
const SHAPE_FREQ: float = 0.05
const SHAPE_OCTAVES: int = 3
const WARP_FREQ: float = 0.1
const WARP_STRENGTH: float = 2.5
const LAND_THRESHOLD: float = 0.0

# --- Edge safety ---
const EDGE_POWER: float = 6.0

# --- Height ---
const BASE_HEIGHT: float = 10.0
const DETAIL_FREQ: float = 0.08
const DETAIL_MULT: float = 4.0

# --- Biomes ---
const DEEP_WATER_THRESHOLD: float = -6.0
const WATER_THRESHOLD: float = 0.0
const SAND_THRESHOLD: float = 3.0
const PLAIN_THRESHOLD: float = 9.0

# --- Villages ---
const VILLAGE_COUNT: int = 4
const MIN_VILLAGE_DISTANCE: float = 8.0  # minimum distance between villages in tiles
const VILLAGE_COLOR: Color = Color(1.0, 0.0, 0.0)  # red for villages

enum Biome {
	DEEP_WATER,
	WATER,
	SAND,
	PLAIN,
	MOUNTAIN
}