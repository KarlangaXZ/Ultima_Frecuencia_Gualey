extends CharacterBody2D
## Locomoción. La salud pertenece al componente independiente.

@export var speed: float = 240.0
@onready var health: HealthComponent = $HealthComponent
@onready var weapon: Node = $Weapon

func _ready() -> void:
	weapon.shot_fired.connect($Combat.fire)
	health.died.connect(weapon.disable)

func _physics_process(_delta: float) -> void:
	if health.is_dead():
		velocity = Vector2.ZERO
		return
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * speed
	move_and_slide()
	var aim_direction := global_position.direction_to(get_global_mouse_position())
	$Aim.rotation = aim_direction.angle()
	if Input.is_action_just_pressed("reload"):
		weapon.start_reload()
	if Input.is_action_pressed("shoot"):
		weapon.try_fire(global_position, aim_direction)
