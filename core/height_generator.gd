## Generates raw terrain heights using Perlin noise with domain warping.
## Applies edge falloff and detail layers to create natural-looking terrain.
class_name HeightGenerator

const Constants = preload("res://data/constants.gd")

# -------------------------
# Height Computation
# -------------------------
## Compute raw height for a tile using noise, domain warping, and edge falloff.
## Combines multiple noise layers to create varied, natural terrain.
static func compute_raw_height(x: int, y: int, half: float, noise: FastNoiseLite) -> float:
	# Edge mask
	var cx: float = x - half
	var cy: float = y - half
	var edge_dist: float = Vector2(cx, cy).length() / half
	var edge_mask: float = pow(clamp(edge_dist, 0.0, 1.0), Constants.EDGE_POWER)

	# Domain warp
	var warp_x: float = noise.get_noise_2d(x * Constants.WARP_FREQ, y * Constants.WARP_FREQ) * Constants.WARP_STRENGTH
	var warp_y: float = noise.get_noise_2d((x+100) * Constants.WARP_FREQ, (y+100) * Constants.WARP_FREQ) * Constants.WARP_STRENGTH
	var wx: float = x + warp_x
	var wy: float = y + warp_y

	# Shape noise
	var shape: float = noise.get_noise_2d(wx, wy)

	# Smooth land factor
	var land_factor: float = clamp((shape - Constants.LAND_THRESHOLD) / 0.5, 0.0, 1.0)

	# Height
	var base_height: float = (1.0 - edge_mask) * Constants.BASE_HEIGHT * land_factor
	var detail: float = noise.get_noise_2d(x * Constants.DETAIL_FREQ, y * Constants.DETAIL_FREQ)
	var height: float = base_height + detail * Constants.DETAIL_MULT

	# Limit height near edges to prevent unnatural spikes, but allow water
	var max_edge_height: float = lerp(1000.0, Constants.PLAIN_THRESHOLD, edge_mask)
	height = min(height, max_edge_height)

	if height > Constants.PLAIN_THRESHOLD:
		height += pow(height - Constants.PLAIN_THRESHOLD, 1.4)

	return height

# -------------------------
# Height Scaling
# -------------------------
## Normalize heights across the entire map to ensure proper biome distribution.
## Stretches height range to cover thresholds for deep water through snow peaks.
static func scale_heights(raw_tiles: Array) -> void:
	var heights: Array = []
	for raw in raw_tiles:
		heights.append(raw.height)
	var min_h: float = heights.min()
	var max_h: float = heights.max()
	var desired_min: float = Constants.DEEP_WATER_THRESHOLD - 1.0
	var desired_max: float = Constants.SNOW_THRESHOLD + 2.0
	if max_h == min_h:
		# If all heights are the same, set min to desired_min and max to desired_max for variety
		for i in range(raw_tiles.size()):
			if i == 0:
				raw_tiles[i].height = desired_max
			else:
				raw_tiles[i].height = desired_min
	else:
		for raw in raw_tiles:
			raw.height = (raw.height - min_h) / (max_h - min_h) * (desired_max - desired_min) + desired_min