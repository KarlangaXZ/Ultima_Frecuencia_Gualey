class_name ZoneCatalog
extends RefCounted
const HOME := "gualey_sector_04"
const MARKET := "market_abandoned"
const DEFINITIONS := {HOME: preload("res://resources/zones/Evacuated.tres"), MARKET: preload("res://resources/zones/Market.tres")}
static var _geometry: Dictionary = {}
static func definition(id: String) -> ZoneDefinition:
	return DEFINITIONS.get(id)
static func point_free(id: String, point: Array) -> bool:
	var zone := definition(id)
	if zone == null: return false
	var p := Vector2(point[0],point[1])
	if p.x < 40 or p.y < 40 or p.x > zone.dimensions.x - 40 or p.y > zone.dimensions.y - 40: return false
	if not _geometry.has(id):
		var scene := zone.world_scene.instantiate()
		var rects := []
		for obstacle in scene.get_node("Obstacles").get_children():
			var collider: CollisionShape2D = obstacle.get_node("CollisionShape2D")
			var transform: Transform2D = obstacle.transform * collider.transform
			var half: Vector2 = collider.shape.size / 2
			rects.append({"inverse": transform.affine_inverse(), "rect": Rect2(-half, half * 2).grow(16)})
		_geometry[id] = rects
		scene.free()
	for obstacle in _geometry[id]:
		if obstacle.rect.has_point(obstacle.inverse * p): return false
	return true
