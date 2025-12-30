class_name TileRenderer

const Constants = preload("res://data/constants.gd")
const ForestRenderer = preload("res://rendering/forest_renderer.gd")

# -------------------------
# Render a single tile
# -------------------------
static func render_tile(parent_node: Node, x: int, y: int, tile_size: float, color: Color, height: float, biome: int, village_id: int = 0, resource: int = 0) -> void:
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
		_draw_village_house(parent_node, x, y, height)
		_draw_village_laser(parent_node, x, y, height)

	# Add resources
	if resource == Constants.ResourceType.FISH:
		_draw_fish(parent_node, x, y, height)

# -------------------------
# Draw village laser
# -------------------------
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

# -------------------------
# Draw village house
# -------------------------
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

# -------------------------
# Draw fish resource
# -------------------------
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
