## Renders all map tiles and their features (forests, farms, boats, houses, villagers).
## Handles 3D mesh creation for terrain, resources, buildings, and people.
class_name TileRenderer

const Constants = preload("res://data/constants.gd")
const ForestRenderer = preload("res://rendering/forest_renderer.gd")

# ==================== Main Tile Rendering ====================
## Render a single tile with base mesh, biome features, and resources.
## Creates visual representation of terrain, forests, buildings, and population.
static func render_tile(parent_node: Node, x: int, y: int, tile_size: float, color: Color, height: float, biome: int, village_id: int = 0, resource: int = 0, villages: Array = []) -> void:
	# Create the base tile mesh
	var mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(tile_size, height, tile_size)
	mesh_instance.mesh = box_mesh

	var material = StandardMaterial3D.new()
	material.albedo_color = color
	mesh_instance.material_override = material

	mesh_instance.position = Vector3(x * tile_size, height / 2.0, y * tile_size)
	parent_node.add_child(mesh_instance)

	# Add biome-specific features
	if resource == Constants.ResourceType.FOREST:
		ForestRenderer.draw_forest_trees(parent_node, x, y, height)

	# Add village features if needed
	if village_id > 0:
		var is_center = false
		for village in villages:
			if village.id == village_id and village.position.x == x and village.position.y == y:
				is_center = true
				break
		if resource != Constants.ResourceType.FARM:
			_draw_village_house(parent_node, x, y, height)
		if is_center:
			_draw_village_laser(parent_node, x, y, height)

	# Add resources
	if resource == Constants.ResourceType.FISH:
		_draw_fish(parent_node, x, y, height)
	if resource == Constants.ResourceType.FARM:
		_draw_farm(parent_node, x, y, height)
	if resource == Constants.ResourceType.FISHING_BOAT:
		_draw_boat(parent_node, x, y, height)

# ==================== Feature Rendering ====================
# --------- Village Indicators ---------
## Draw a red laser beam above village center tile for easy identification.
static func _draw_village_laser(parent_node: Node, x: int, y: int, tile_height: float) -> void:
	var laser_instance = MeshInstance3D.new()
	var cylinder_mesh = CylinderMesh.new()
	cylinder_mesh.top_radius = 0.1
	cylinder_mesh.bottom_radius = 0.1
	cylinder_mesh.height = 10.0  # tall laser beam

	var laser_material = StandardMaterial3D.new()
	laser_material.albedo_color = Color(1.0, 0.0, 0.0, 0.3)  # red translucent
	laser_material.emission_enabled = true
	laser_material.emission = Color(1.0, 0.0, 0.0)  # red emission
	laser_material.emission_energy = 2.0
	laser_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	laser_instance.mesh = cylinder_mesh
	laser_instance.material_override = laser_material
	laser_instance.position = Vector3(x * Constants.TILE_SIZE, tile_height + 5.0, y * Constants.TILE_SIZE)  # above the tile
	parent_node.add_child(laser_instance)

	# Add light at the top of the laser
	var laser_light = OmniLight3D.new()
	laser_light.light_color = Color(1.0, 0.0, 0.0)
	laser_light.light_energy = 3.0
	laser_light.omni_range = 5.0
	laser_light.position = Vector3(x * Constants.TILE_SIZE, tile_height + 10.0, y * Constants.TILE_SIZE)
	parent_node.add_child(laser_light)

# --------- Housing ---------
## Draw 3 small houses arranged in a triangle on a village-owned residential tile.
static func _draw_village_house(parent_node: Node, x: int, y: int, tile_height: float) -> void:
	var base_x = x * Constants.TILE_SIZE
	var base_z = y * Constants.TILE_SIZE
	var tile_center_x = base_x
	var tile_center_z = base_z
	
	# Create exactly 3 houses arranged in a triangle around the tile center
	var house_count = 3
	var radius = Constants.TILE_SIZE * 0.25  # distance from center (reduced from 0.3)
	
	for i in range(house_count):
		# Position houses at 120-degree intervals
		var angle = (i * 2.0 * PI) / house_count  # 0°, 120°, 240°
		var offset_x = cos(angle) * radius
		var offset_z = sin(angle) * radius
		
		# Make houses face toward the center
		var rotation_y = angle + PI  # face toward center
		
		# Random house size variation (much smaller)
		var house_scale = 0.4 + randf() * 0.1
		
		# Create the main house body (box)
		var house_body = MeshInstance3D.new()
		var box_mesh = BoxMesh.new()
		box_mesh.size = Vector3(0.8 * house_scale, 0.5 * house_scale, 0.8 * house_scale)  # smaller base size
		
		var house_material = StandardMaterial3D.new()
		# Vary house colors slightly
		var color_variation = randf() * 0.3
		house_material.albedo_color = Color(0.8 + color_variation, 0.6 + color_variation * 0.5, 0.4 + color_variation * 0.3)
		house_body.material_override = house_material
		house_body.mesh = box_mesh
		house_body.position = Vector3(tile_center_x + offset_x, tile_height + 0.25 * house_scale, tile_center_z + offset_z)
		house_body.rotation.y = rotation_y
		parent_node.add_child(house_body)
		
		# Create the roof (pyramid)
		var roof = MeshInstance3D.new()
		var roof_mesh = PrismMesh.new()
		roof_mesh.size = Vector3(0.9 * house_scale, 0.4 * house_scale, 0.9 * house_scale)  # smaller roof
		
		var roof_material = StandardMaterial3D.new()
		roof_material.albedo_color = Color(0.6, 0.3, 0.2)  # darker brown roof
		roof.material_override = roof_material
		roof.mesh = roof_mesh
		roof.position = Vector3(tile_center_x + offset_x, tile_height + 0.6 * house_scale, tile_center_z + offset_z)
		roof.rotation.y = rotation_y
		parent_node.add_child(roof)

# --------- Resources ---------
## Draw fish as a simple capsule on water tiles.
static func _draw_fish(parent_node: Node, x: int, y: int, tile_height: float) -> void:
	# Create a simple fish shape using a capsule
	var fish = MeshInstance3D.new()
	var capsule_mesh = CapsuleMesh.new()
	capsule_mesh.radius = 0.15
	capsule_mesh.height = 0.4
	
	var fish_material = StandardMaterial3D.new()
	fish_material.albedo_color = Color(0.8, 0.6, 0.2)  # orange fish
	fish.material_override = fish_material
	fish.mesh = capsule_mesh
	
	# Position fish slightly above water surface
	var base_x = x * Constants.TILE_SIZE
	var base_z = y * Constants.TILE_SIZE
	fish.position = Vector3(base_x, tile_height + 0.3, base_z)
	
	# Add some random rotation for variety
	fish.rotation_degrees = Vector3(0, randf() * 360, 0)
	
	parent_node.add_child(fish)

# --------- Farms ---------
## Draw a farm with fence posts at corners and yellow wheat rows covering the tile.
static func _draw_farm(parent_node: Node, x: int, y: int, tile_height: float) -> void:
	var base_x = x * Constants.TILE_SIZE
	var base_z = y * Constants.TILE_SIZE
	var half_tile = Constants.TILE_SIZE / 2.0
	
	# Draw fence posts at the four corners
	var fence_material = StandardMaterial3D.new()
	fence_material.albedo_color = Color(0.4, 0.2, 0.1)  # dark brown
	
	var post_positions = [
		Vector3(base_x - half_tile + 0.1, tile_height + 0.5, base_z - half_tile + 0.1),
		Vector3(base_x + half_tile - 0.1, tile_height + 0.5, base_z - half_tile + 0.1),
		Vector3(base_x - half_tile + 0.1, tile_height + 0.5, base_z + half_tile - 0.1),
		Vector3(base_x + half_tile - 0.1, tile_height + 0.5, base_z + half_tile - 0.1)
	]
	
	for pos in post_positions:
		var post = MeshInstance3D.new()
		var cylinder = CylinderMesh.new()
		cylinder.top_radius = 0.05
		cylinder.bottom_radius = 0.05
		cylinder.height = 1.0
		post.mesh = cylinder
		post.material_override = fence_material
		post.position = pos
		parent_node.add_child(post)
	
	# Draw wheat covering the tile
	var wheat_material = StandardMaterial3D.new()
	wheat_material.albedo_color = Color(1.0, 1.0, 0.0)  # yellow
	
	for i in range(8):
		for j in range(8):
			var wheat = MeshInstance3D.new()
			var box = BoxMesh.new()
			box.size = Vector3(0.1, 0.3, 0.1)
			wheat.mesh = box
			wheat.material_override = wheat_material
			wheat.position = Vector3(
				base_x - half_tile + 0.2 + i * 0.2,
				tile_height + 0.15,
				base_z - half_tile + 0.2 + j * 0.2
			)
			parent_node.add_child(wheat)

# --------- Boats ---------
## Draw a fishing boat with hull, mast, and sail on water tiles.
static func _draw_boat(parent_node: Node, x: int, y: int, tile_height: float) -> void:
	var base_x = x * Constants.TILE_SIZE
	var base_z = y * Constants.TILE_SIZE
	
	# Create a simple boat hull using a box
	var boat = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(1.5, 0.3, 0.6)  # boat shape
	
	var boat_material = StandardMaterial3D.new()
	boat_material.albedo_color = Color(0.4, 0.2, 0.1)  # brown wood
	boat.material_override = boat_material
	boat.mesh = box_mesh
	boat.position = Vector3(base_x, tile_height + 0.15, base_z)
	parent_node.add_child(boat)
	
	# Add a mast with sail
	var mast = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.02
	cylinder.bottom_radius = 0.02
	cylinder.height = 1.0
	mast.mesh = cylinder
	mast.material_override = boat_material
	mast.position = Vector3(base_x, tile_height + 0.6, base_z)
	parent_node.add_child(mast)
	
	# Sail
	var sail = MeshInstance3D.new()
	var plane = PlaneMesh.new()
	plane.size = Vector2(0.8, 0.6)
	var sail_material = StandardMaterial3D.new()
	sail_material.albedo_color = Color(1.0, 1.0, 1.0)  # white sail
	sail.material_override = sail_material
	sail.mesh = plane
	sail.position = Vector3(base_x, tile_height + 0.8, base_z)
	sail.rotation_degrees = Vector3(0, 0, 0)  # flat
	parent_node.add_child(sail)

# --------- Villagers ---------
## Draw simple human figures (2 spheres) at world position.
## Used to visualize where villagers are working or living.
static func _draw_human(parent_node: Node, x: float, y: float, tile_height: float, color: Color = Color(0.9, 0.9, 0.9)) -> void:
	# x and y are world coordinates (not tile indices)
	var body = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.12
	body.mesh = sphere
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	body.material_override = mat
	body.position = Vector3(x, tile_height + 0.35, y)
	parent_node.add_child(body)

	# Head
	var head = MeshInstance3D.new()
	var head_mesh = SphereMesh.new()
	head_mesh.radius = 0.08
	head.mesh = head_mesh
	head.material_override = mat
	head.position = Vector3(x, tile_height + 0.6, y)
	parent_node.add_child(head)

