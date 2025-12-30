class_name Tile

var x: int
var y: int
var height: float
var biome: int  # Use int for enum
var color: Color
var village_id: int  # 0 = no village, 1-4 = village ID

func _init(px: int, py: int, pheight: float, pbiome: int, pcolor: Color, pvillage_id: int = 0):
	x = px
	y = py
	height = pheight
	biome = pbiome
	color = pcolor
	village_id = pvillage_id