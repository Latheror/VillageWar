# Village War - Map Generator

A procedural island map generator for Godot with forests, villages, and snow-capped mountains.

## Project Structure

```
├── core/                    # Core game systems
│   ├── biome_system.gd      # Biome determination and properties
│   ├── feature_placer.gd    # Forest and village placement
│   ├── height_generator.gd  # Terrain height calculation
│   └── map_generator.gd     # Main map generation orchestrator
├── data/                    # Data structures and constants
│   ├── constants.gd         # Game constants and enums
│   └── tile.gd              # Tile data structure
├── rendering/               # Rendering systems
│   ├── forest_renderer.gd   # Forest tree rendering
│   └── tile_renderer.gd     # Tile and feature rendering
├── main.gd                  # Main scene script
├── main.tscn                # Main scene
└── project.godot           # Godot project file
```

## Architecture

The codebase is organized into focused, single-responsibility systems:

### Core Systems (`core/`)
- **MapGenerator**: Orchestrates the entire map generation process
- **HeightGenerator**: Handles terrain height calculation using noise
- **BiomeSystem**: Determines biomes based on height and provides colors/heights
- **FeaturePlacer**: Places forests and villages on the generated terrain

### Data Layer (`data/`)
- **Constants**: All game constants, enums, and configuration
- **Tile**: Data structure representing individual map tiles

### Rendering Layer (`rendering/`)
- **TileRenderer**: Renders tiles, forests, and village markers
- **ForestRenderer**: Specialized forest tree rendering

### Main Scene (`main.gd`)
- Scene setup and initialization
- Delegates to specialized systems for generation and rendering

## Features

- **Procedural Islands**: Noise-based terrain generation with natural edges
- **Biome System**: 8 different biomes from deep water to snow-capped peaks
- **Forest Patches**: Contiguous forest areas with 3D tree models
- **Villages**: Automatically placed settlements with visual markers
- **Snow-Capped Mountains**: Realistic alpine terrain

## Usage

1. Open the project in Godot
2. Run the main scene
3. The map generates automatically on startup

## Configuration

All parameters can be adjusted in `data/constants.gd`:
- Map size and terrain parameters
- Biome thresholds and colors
- Forest generation settings
- Village placement rules