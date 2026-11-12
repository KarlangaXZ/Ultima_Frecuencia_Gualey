extends NavigationRegion2D
## Genera la malla desde las colisiones reales, sin duplicar las cajas.

func _ready() -> void:
	var polygon := NavigationPolygon.new()
	polygon.agent_radius = 20.0
	var geometry := NavigationMeshSourceGeometryData2D.new()
	geometry.add_traversable_outline(PackedVector2Array([
		Vector2(24, 24), Vector2(2376, 24), Vector2(2376, 1576), Vector2(24, 1576)]))
	for obstacle in get_parent().get_node("Obstacles").get_children():
		var collider := obstacle.get_node("CollisionShape2D") as CollisionShape2D
		var rectangle := collider.shape as RectangleShape2D
		var half := rectangle.size / 2.0
		var outline := PackedVector2Array()
		for corner in [Vector2(-half.x, -half.y), Vector2(half.x, -half.y), half, Vector2(-half.x, half.y)]:
			outline.append(to_local(collider.to_global(corner)))
		geometry.add_obstruction_outline(outline)
	NavigationServer2D.bake_from_source_geometry_data(polygon, geometry)
	navigation_polygon = polygon
