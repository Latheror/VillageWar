class_name ForestRenderer

const Constants = preload("res://data/constants.gd")

# -------------------------
# Draw forest trees
# -------------------------
static func draw_forest_trees(parent_node: Node, x: int, y: int, tile_height: float) -> void:
	var tree_positions = [
		Vector2(0.3, 0.3),
		Vector2(0.7, 0.6),
		Vector2(0.2, 0.8)
	]
	
	for tree_pos in tree_positions:
		# Tree trunk
		var trunk = MeshInstance3D.new()
		var trunk_mesh = CylinderMesh.new()
		trunk_mesh.top_radius = 0.05
		trunk_mesh.bottom_radius = 0.08
		trunk_mesh.height = 1.0
		
		var trunk_material = StandardMaterial3D.new()
		trunk_material.albedo_color = Color(0.4, 0.2, 0.1)  # brown
		trunk.material_override = trunk_material
		trunk.mesh = trunk_mesh
		
		var base_x = x * Constants.TILE_SIZE + (tree_pos.x - 0.5) * Constants.TILE_SIZE
		var base_z = y * Constants.TILE_SIZE + (tree_pos.y - 0.5) * Constants.TILE_SIZE
		trunk.position = Vector3(base_x, tile_height + 0.5, base_z)
		parent_node.add_child(trunk)
		
		# Tree foliage
		var foliage = MeshInstance3D.new()
		var foliage_mesh = SphereMesh.new()
		foliage_mesh.radius = 0.3
		foliage_mesh.height = 0.6
		
		var foliage_material = StandardMaterial3D.new()
		foliage_material.albedo_color = Color(0.0, 0.5, 0.0)  # dark green
		foliage.material_override = foliage_material
		foliage.mesh = foliage_mesh
		
		foliage.position = Vector3(base_x, tile_height + 1.0, base_z)
		parent_node.add_child(foliage)