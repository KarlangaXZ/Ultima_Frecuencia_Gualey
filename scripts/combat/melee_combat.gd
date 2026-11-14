extends Node2D
## Impacto instantáneo frontal: una salud por enemigo, siempre con visibilidad World.
var hit_count := 0
var origin := Vector2.ZERO
var facing := Vector2.RIGHT
var attack_range := 55.0
var arc := PI / 2
var remaining := 0.0

func _ready() -> void:
	top_level = true
	global_transform = Transform2D.IDENTITY

func attack(config: WeaponConfig, start: Vector2, direction: Vector2) -> void:
	origin = start
	facing = direction.normalized()
	attack_range = config.shot_range
	arc = deg_to_rad(config.melee_arc_degrees)
	hit_count = 0
	var circle := CircleShape2D.new()
	circle.radius = attack_range
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = circle
	query.transform = Transform2D(0, origin)
	query.collision_mask = 4
	var seen := {}
	var space := get_world_2d().direct_space_state
	for result in space.intersect_shape(query, 64):
		var enemy := result.collider as Node2D
		if seen.has(enemy.get_instance_id()): continue
		seen[enemy.get_instance_id()] = true
		var distance := origin.distance_to(enemy.global_position)
		if distance > attack_range or absf(facing.angle_to(enemy.global_position - origin)) > arc / 2: continue
		var wall := PhysicsRayQueryParameters2D.create(origin, enemy.global_position, 1)
		wall.hit_from_inside = true
		if not space.intersect_ray(wall).is_empty(): continue
		var health := enemy.get_node_or_null("HealthComponent") as HealthComponent
		if health != null and not health.is_dead():
			health.take_damage(config.damage)
			hit_count += 1
	remaining = 0.12
	queue_redraw()

func _process(delta: float) -> void:
	if remaining > 0:
		remaining = maxf(0, remaining - delta)
		queue_redraw()

func _draw() -> void:
	if remaining <= 0: return
	draw_arc(origin, attack_range, facing.angle() - arc / 2, facing.angle() + arc / 2, 20, Color("c9d0b2"), 3, true)
