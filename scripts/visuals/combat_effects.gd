extends Node2D
## Decoración opcional, conectada al resultado ya resuelto del hitscan.
@export var effects_enabled: bool = true
@export var muzzle_texture: Texture2D = preload("res://assets/placeholders/effects/temp_muzzle_flash.svg")
var particles: Array[Dictionary] = []
var flash_origin: Vector2
var flash_angle: float = 0.0
var flash_time: float = 0.0
var last_impact_kind: String = "none"

func _ready() -> void:
	top_level = true
	global_transform = Transform2D.IDENTITY
	z_index = 10
	get_parent().visual_shot.connect(_on_visual_shot)

func _on_visual_shot(origin: Vector2, endpoint: Vector2, kind: String) -> void:
	if not effects_enabled:
		return
	var direction := origin.direction_to(endpoint)
	flash_origin = origin + direction * minf(29.0, origin.distance_to(endpoint))
	flash_angle = direction.angle()
	flash_time = 0.07
	last_impact_kind = kind
	if kind != "none":
		for index in range(8):
			var angle := float(index) * TAU / 8.0
			particles.append({"position": endpoint, "velocity": Vector2.from_angle(angle) * (28.0 + index * 7.0),
				"life": 0.32, "kind": kind})
	queue_redraw()

func _process(delta: float) -> void:
	flash_time = maxf(0.0, flash_time - delta)
	for index in range(particles.size() - 1, -1, -1):
		particles[index].life -= delta
		particles[index].position += particles[index].velocity * delta
		if particles[index].life <= 0.0:
			particles.remove_at(index)
	queue_redraw()

func _draw() -> void:
	if not effects_enabled:
		return
	if flash_time > 0.0:
		draw_set_transform(flash_origin, flash_angle)
		draw_texture_rect(muzzle_texture, Rect2(-13, -13, 26, 26), false)
		draw_set_transform(Vector2.ZERO)
	for particle in particles:
		var color := Color("b85c4b") if particle.kind == "zombie" else Color("e9bf78")
		color.a = particle.life / 0.32
		draw_circle(particle.position, 2.2 if particle.kind == "zombie" else 1.5, color)
