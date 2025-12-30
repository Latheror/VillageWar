extends Node2D

const SIZE := 30
const TILE_SIZE := 32
const ISLAND_RADIUS := 0.85   # taille globale
const FALLOFF_POWER := 3.0    # douceur du bord

func _ready():
	var half = SIZE / 2.0

	var noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = 0.06

	for x in range(SIZE):
		for y in range(SIZE):

			var cx = x - half
			var cy = y - half

			# Distance normalisée (0 = centre, 1 = bord)
			var dist = Vector2(cx, cy).length() / half
			dist = clamp(dist / ISLAND_RADIUS, 0.0, 1.0)

			# Courbe de chute
			var falloff = pow(dist, FALLOFF_POWER)

			var n = noise.get_noise_2d(x, y)

			# Attraction progressive vers l'eau
			var height = lerp(n, -1.0, falloff)

			_draw_tile(x, y, TILE_SIZE, Color.GREEN if height > 0 else Color.BLUE)


func _draw_tile(x: int, y: int, tile_size: int, color: Color) -> void:
	var rect = ColorRect.new()
	rect.size = Vector2(tile_size, tile_size)
	rect.position = Vector2(x * tile_size, y * tile_size)
	rect.color = color
	add_child(rect)
