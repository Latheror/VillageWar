# VillageWar

A strategic village simulation game in Godot with procedural island generation, autonomous village management, and resource economy. Villages expand, build farms and fishing boats, manage population, and cut wood—all driven by AI decision-making based on survival priorities.

## Quick Start

1. Open the project in Godot Engine 4.2.2
2. Run `main.tscn`
3. Use arrow keys or mouse to pan the camera, scroll wheel to zoom
4. Click "Next Day" to advance time manually, or let the timer auto-advance every 5 seconds
5. Pause/Resume button controls automatic day advancement

## Project Structure

```
├── core/                    # Map generation and feature placement
│   ├── biome_system.gd      # Biome determination from height values
│   ├── feature_placer.gd    # Forest patches, villages, and fish placement
│   ├── height_generator.gd  # Procedural terrain using Perlin noise
│   └── map_generator.gd     # Main orchestrator for map generation
├── data/                    # Data models and game configuration
│   ├── constants.gd         # Global constants, enums, and thresholds
│   ├── tile.gd              # Tile data structure (position, biome, resources)
│   └── village.gd           # Village class with AI logic and resource management
├── rendering/               # 3D mesh and visual rendering
│   ├── forest_renderer.gd   # Tree rendering for forest tiles
│   └── tile_renderer.gd     # Tile meshes, houses, farms, boats, villagers
├── main.gd                  # Scene orchestrator and game loop
├── main.tscn                # Godot scene root
├── time_manager.gd          # Day/time tracking and signals
├── village_ui.gd            # HUD panels and village info display
└── project.godot            # Godot project configuration
```

## Architecture Overview

### Generation Pipeline (`core/`)
The map is generated in four stages:

1. **Height Calculation** (`HeightGenerator`)
   - Uses FastNoiseLite with domain warping for natural terrain
   - Applies edge falloff to constrain land to the center
   - Combines base noise with detail layers for variation

2. **Height Normalization**
   - Scales raw heights to cover biome thresholds (deep water to snow peaks)
   - Ensures proper distribution across elevation ranges

3. **Biome Assignment** (`BiomeSystem`)
   - 8 biome types: Deep Water → Water → Sand → Plain → Mountain → High Mountain → Snow
   - Each biome has color and rendering height

4. **Feature Placement** (`FeaturePlacer`)
   - **Forests**: Contiguous patches on plains (3–12 tiles per patch)
   - **Villages**: 4 settlements spawned on plains with minimum spacing (8+ tiles apart)
   - **Fish**: Random spawn on water tiles (5% chance per tile)

### Village System (`data/village.gd`)

Villages are autonomous agents that manage:
- **Population**: Starts at 5, limited by housing (5 people per house tile)
- **Resources**: Food (consumed daily), Wood (used for building)
- **Tiles Owned**: House tiles (resource=NONE), Farms, Fishing Boats
- **Daily Actions**: Controlled by survival-first AI logic

#### Village Actions (Priority-Based)
Villages choose one action per day based on:

1. **Food Production** (highest priority when starving)
   - `try_build_farm`: Costs 5 wood, produces 5 food (requires 2 workers)
   - `try_build_fishing_boat`: Costs 5 wood, produces 5 food on water near fish (requires 2 workers)
   - `try_cut_wood`: Harvests forest within 5 tiles, yields 5 wood

2. **Expansion**
   - `try_build_house`: Costs 10 wood, claims adjacent plain tile as housing (+5 population capacity)
   - `try_colonize`: Costs 10 wood, claims non-water/mountain adjacent tile (early expansion)

#### Population & Housing
- **Max capacity**: 5 people per house tile (resource=NONE, village-owned)
- **Growth**: Stochastic (30% daily chance) if food ≥ 5, food > current consumption, capacity exists
- **Starvation**: If food < population, population decreases by shortage (minimum 1)

#### Worker Allocation
- **Farms**: 2 workers per farm (must have available worker pairs)
- **Fishing Boats**: 2 workers per boat (only if fish within 5 tiles)
- **Idle**: Remaining workers placed on house tiles (visualization)

### Rendering (`rendering/`)

Each tile renders:
- **Base mesh**: Colored box at appropriate height for biome
- **Forest**: 3 trees (trunk + foliage) on forest tiles
- **Houses**: 3 small houses arranged in triangle on house tiles
- **Farms**: Fence posts + yellow wheat grid
- **Fishing Boats**: Brown hull + mast + white sail
- **Villagers**: Simple 2-sphere human figures at worker positions
- **Village Center**: Red laser beam for easy identification

### Game Loop (`main.gd`)

1. **Initialization** (`_ready`)
   - Generate map via `MapGenerator`
   - Set up camera, lighting, UI
   - Start time manager

2. **Daily Processing** (`_on_day_advanced`)
   - Call `village.perform_daily_action()` for each village
   - Recompute `tile_count` (house tiles only)
   - Enforce population cap
   - Re-render if any tile changed

3. **Per-Frame** (`_process`)
   - Handle camera input (arrow keys, mouse wheel)
   - Update camera position/rotation

### UI (`village_ui.gd` and `time_manager.gd`)

- **HUD Bar**: Shows current date and day number
- **Pause/Resume**: Toggles automatic day advancement (default 5 seconds per day)
- **Next Day**: Manual day advance button
- **Village Panels**: Float above each village showing name, population, food, wood, tiles

## Key Design Patterns

### Enum-Based Configuration
All game constants (biome thresholds, resource spawn rates, etc.) are in `constants.gd`. Changes propagate automatically.

### Tile-Based Ownership
Villages claim tiles by setting `tile.village_id`. Ownership determines:
- Housing capacity (tiles with `resource=NONE`)
- Farm/boat productivity
- Expansion boundaries

### Return-Based Change Tracking
Village actions return `bool` indicating whether they changed tile state. Main only redraws map when changes occur (efficiency).

### Survival-First AI
Villages score actions with high weight on food/wood when:
- Food < population (starvation risk)
- Wood < 30 (insufficient resources to build)
- Survival needs ignored if basic needs met

## Configuration (`data/constants.gd`)

### Map Dimensions
```gdscript
const SIZE: int = 50                    # Grid size (50×50 tiles)
const TILE_SIZE: float = 2.0            # World units per tile
```

### Terrain Generation
```gdscript
const SHAPE_FREQ: float = 0.05          # Noise frequency for island shape
const SHAPE_OCTAVES: int = 3            # Noise octaves
const BASE_HEIGHT: float = 10.0         # Sea level height
const DETAIL_MULT: float = 4.0          # Detail layer strength
```

### Biome Thresholds (by height)
```gdscript
const DEEP_WATER_THRESHOLD: float = -5.0
const WATER_THRESHOLD: float = 0.0
const SAND_THRESHOLD: float = 3.0
const PLAIN_THRESHOLD: float = 9.0
const HIGH_MOUNTAIN_THRESHOLD: float = 15.0
const SNOW_THRESHOLD: float = 18.0
```

### Village & Resource Settings
```gdscript
const VILLAGE_COUNT: int = 4
const MIN_VILLAGE_DISTANCE: float = 8.0

const FISH_SPAWN_CHANCE: float = 0.05
const FOREST_SEED_CHANCE: float = 0.08
const FOREST_MIN_SIZE: int = 3
const FOREST_MAX_SIZE: int = 12
```

## Gameplay Features

### Autonomous Villages
Each village independently:
- Manages population growth and food consumption
- Builds farms, fishing boats, and houses based on needs
- Cuts wood to sustain construction
- Expands territory when advantageous

### Realistic Resource Economy
- **Food**: Produced by farms (2 workers/farm) and boats (2 workers/boat)
- **Wood**: Consumed for building, harvested from forests
- **Housing**: Explicit tiles that cap population at 5 per tile
- **Fishing**: Requires fish within 5-tile range to operate boats

### Procedural Variety
- Unique island per game (randomized noise seed)
- Variable forest patch placement and size
- Biome distribution depends on height variance
- Villages placed deterministically far apart

### Visualization
- Small human figures show where villagers are working
- Farm fields clearly show production tiles
- Fishing boats on coastal water
- Houses cluster on residential tiles
- Laser beam marks village center

## Future Enhancements

Potential additions to deepen gameplay:
- **Trading**: Exchanges between villages (via merchants or boats)
- **Combat**: Raids, walls, military units
- **More Biomes**: Desert, volcanic, swamp with unique mechanics
- **Tech Tree**: Villages research improvements (better farming, faster construction)
- **Events**: Random disasters (plague, storms) affecting food/wood
- **Pathfinding**: Visible trade routes, military movements
- **Seasons**: Varying resource yields by time of year

## Development Notes

### Code Organization
- Single-responsibility principle: each file handles one major system
- Static utility classes for generation and rendering
- Village as main simulation entity with daily `perform_daily_action()` call
- Constants centralized for easy tuning

### Performance Considerations
- Full map redraw only on tile changes (not every frame)
- Rendering uses simple geometric primitives (spheres, cylinders, boxes)
- No physics or collision (tiles don't interact, only visually represented)
- Village logic runs once per day (5-second intervals)

### Extending the Code
1. **New Resource Type**: Add to `ResourceType` enum, implement placement in `FeaturePlacer`, and rendering in `TileRenderer`
2. **New Village Action**: Add `try_*` function in `Village`, return bool, add to action scoring in `perform_daily_action`
3. **New Biome**: Add to `Biome` enum, thresholds in `Constants`, color/height in `BiomeSystem`
4. **Custom Rendering**: Add static function in `TileRenderer`, call from `render_tile`

## License

Created as a strategic village simulation prototype for Godot.

