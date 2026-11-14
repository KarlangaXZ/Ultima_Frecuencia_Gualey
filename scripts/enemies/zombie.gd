extends CharacterBody2D
## IA y cadencia de ataque; salud compartida mediante HealthComponent.
enum State { IDLE, CHASE, ATTACK, DEAD }
signal eliminated

@export var archetype: ZombieArchetype = preload("res://resources/enemies/Common.tres")
var speed: float
var detection_radius: float
var attack_distance: float
var attack_damage: float
var attack_interval: float
# Se reenvía al componente; no hay lógica de salud duplicada.
var max_health: float

@onready var health: HealthComponent = $HealthComponent
@onready var agent: NavigationAgent2D = $NavigationAgent2D
var state: State = State.IDLE
var target: CharacterBody2D
var target_health: HealthComponent
var cooldown: float = 0.0
var repath_time: float = 0.0

func _enter_tree() -> void:
	# Antes de _ready de salud/visual/audio, una sola aplicación desde configuración.
	archetype.apply_to(self)

func _ready() -> void:
	health.max_health = max_health
	health.current_health = max_health
	health.died.connect(_on_died)

func set_target(player: CharacterBody2D) -> void:
	target = player
	target_health = player.get_node("HealthComponent") as HealthComponent
	target_health.died.connect(stop_targeting)

func stop_targeting() -> void:
	target = null
	target_health = null
	velocity = Vector2.ZERO
	if state != State.DEAD:
		state = State.IDLE

func _on_died() -> void:
	state = State.DEAD
	velocity = Vector2.ZERO
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	$CollisionShape2D.set_deferred("disabled", true)
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.25, 0.45)
	# Cadáver desactivado hasta el reinicio; no bloquea disparos ni movimiento.
	eliminated.emit()

func _can_reach_target() -> bool:
	var query := PhysicsRayQueryParameters2D.create(global_position, target.global_position, 1)
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()

func _physics_process(delta: float) -> void:
	cooldown = maxf(0.0, cooldown - delta)
	velocity = Vector2.ZERO
	if state == State.DEAD or not is_instance_valid(target) or target_health.is_dead():
		return
	var distance := global_position.distance_to(target.global_position)
	if distance > detection_radius:
		state = State.IDLE
		return
	if distance <= attack_distance and _can_reach_target():
		state = State.ATTACK
		if cooldown <= 0.0:
			cooldown = attack_interval
			target_health.take_damage(attack_damage)
		return
	state = State.CHASE
	if NavigationServer2D.map_get_iteration_id(agent.get_navigation_map()) == 0:
		return
	repath_time -= delta
	if repath_time <= 0.0:
		agent.target_position = target.global_position
		repath_time = 0.2
	if not agent.is_navigation_finished():
		velocity = global_position.direction_to(agent.get_next_path_position()) * speed
	move_and_slide()
