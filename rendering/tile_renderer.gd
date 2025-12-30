class_name TileRenderer

const Constants = preload("res://data/constants.gd")
const ForestRenderer = preload("res://rendering/forest_renderer.gd")

# -------------------------
# Render a single tile
# -------------------------
static func render_tile(parent_node: Node, x: int, y: int, tile_size: float, color: Color, height: float, biome: int, village_id: int = 0) -> void:
	# Create the base tile mesh
	var mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(tile_size, height, tile_size)
	mesh_instance.mesh = box_mesh

	var material = StandardMaterial3D.new()
	if village_id > 0:
		material.albedo_color = Constants.VILLAGE_COLOR
	else:
		material.albedo_color = color
	mesh_instance.material_override = material

	mesh_instance.position = Vector3(x * tile_size, height / 2.0, y * tile_size)
	parent_node.add_child(mesh_instance)

	# Add biome-specific features
	if biome == Constants.Biome.FOREST:
		ForestRenderer.draw_forest_trees(parent_node, x, y, height)

	# Add village laser if needed
	if village_id > 0:
		_draw_village_laser(parent_node, x, y, height)

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