extends Node2D
## Una descarga, N rayos reutilizando la resolución de impactos, un solo destello.
var endpoints: Array[Vector2] = []
var trace_origin := Vector2.ZERO
var remaining := 0.0
@onready var hitscan: Node = $"../Combat"

func _ready() -> void:
	top_level = true
	global_transform = Transform2D.IDENTITY

func fire(config: WeaponConfig, origin: Vector2, direction: Vector2) -> void:
	endpoints.clear()
	trace_origin = origin
	var representative: Dictionary
	for index in range(config.pellet_count):
		var fraction := float(index) / maxf(1, config.pellet_count - 1) - 0.5 if config.pellet_count > 1 else 0.0
		var ray_direction := direction.rotated(deg_to_rad(config.spread_degrees) * fraction)
		var result: Dictionary = hitscan.cast_hit(origin, ray_direction, config.damage, config.shot_range)
		endpoints.append(result.endpoint)
		if representative.is_empty() or result.kind == "zombie" or (result.hit and not representative.hit): representative = result
	hitscan.present_result(origin, representative, false)
	remaining = 0.1
	queue_redraw()

func _process(delta: float) -> void:
	if remaining > 0:
		remaining = maxf(0, remaining - delta)
		queue_redraw()

func _draw() -> void:
	if remaining <= 0: return
	for endpoint in endpoints: draw_line(trace_origin, endpoint, Color("eacb88"), 1)
