extends Node2D
## Un solo rayo al primer cuerpo World/Zombie. Trazo breve en coordenadas del mundo.
signal shot_resolved(endpoint: Vector2, hit: bool)
signal visual_shot(origin: Vector2, endpoint: Vector2, kind: String)
var trace_start: Vector2
var trace_end: Vector2
var hit_something: bool = false
var trace_remaining: float = 0.0

func _ready() -> void:
	top_level = true
	global_transform = Transform2D.IDENTITY

func fire(origin: Vector2, direction: Vector2, damage: float, shot_range: float) -> void:
	present_result(origin, cast_hit(origin, direction, damage, shot_range))

func cast_hit(origin: Vector2, direction: Vector2, damage: float, shot_range: float) -> Dictionary:
	var endpoint := origin + direction.normalized() * shot_range
	var query := PhysicsRayQueryParameters2D.create(origin, endpoint, 1 | 4)
	query.hit_from_inside = true
	var result := get_world_2d().direct_space_state.intersect_ray(query)
	var impact_kind := "none"
	if not result.is_empty():
		impact_kind = "world"
		endpoint = result.position
		var collider := result.collider as Node
		if collider.get_collision_layer() & 4:
			impact_kind = "zombie"
			var health := collider.get_node_or_null("HealthComponent") as HealthComponent
			if health != null:
				health.take_damage(damage)
	return {"endpoint": endpoint, "hit": not result.is_empty(), "kind": impact_kind}

func present_result(origin: Vector2, result: Dictionary, show_trace: bool = true) -> void:
	trace_start = origin
	trace_end = result.endpoint
	hit_something = result.hit
	trace_remaining = 0.1 if show_trace else 0.0
	queue_redraw()
	shot_resolved.emit(trace_end, hit_something)
	visual_shot.emit(origin, trace_end, result.kind)

func _process(delta: float) -> void:
	if trace_remaining > 0.0:
		trace_remaining = maxf(0.0, trace_remaining - delta)
		queue_redraw()

func _draw() -> void:
	if trace_remaining <= 0.0:
		return
	draw_line(trace_start, trace_end, Color("ffe6a1"), 2.0)
	draw_circle(trace_end, 5.0, Color("ff8855") if hit_something else Color("ffe6a1"))
