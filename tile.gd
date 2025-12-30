class_name Tile

var x: int
var y: int
var height: float
var biome: int  # Use int for enum
var color: Color

func _init(px: int, py: int, pheight: float, pbiome: int, pcolor: Color):
	x = px
	y = py
	height = pheight
	biome = pbiome
	color = pcolor