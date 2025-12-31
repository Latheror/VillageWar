## Represents a single map tile with biome, height, and resource information.
## Tiles track ownership (village_id) and what resource/feature they contain.
class_name Tile

var x: int                         # X coordinate in tile grid
var y: int                         # Y coordinate in tile grid
var height: float                  # Terrain height at this tile
var biome: int                     # Biome type (see Constants.Biome enum)
var color: Color                   # Display color for rendering
var village_id: int                # 0 = unowned, 1+ = owning village ID
var resource: int                  # Resource type (see Constants.ResourceType enum)

## Initialize a tile at position (px, py) with given properties.
func _init(px: int, py: int, pheight: float, pbiome: int, pcolor: Color, pvillage_id: int = 0, presource: int = 0) -> void:
	x = px
	y = py
	height = pheight
	biome = pbiome
	color = pcolor
	village_id = pvillage_id
	resource = presource