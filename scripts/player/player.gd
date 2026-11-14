extends CharacterBody2D
## Locomoción. La salud pertenece al componente independiente.

@export var speed: float = 240.0
@onready var health: HealthComponent = $HealthComponent
@onready var weapon: Node = $Weapon
var controls_blocked := false
var _require_shoot_release := false

func set_controls_blocked(active: bool) -> void:
	controls_blocked = active
	$Equipment.selection_blocked = active
	_require_shoot_release = true
	if active: velocity = Vector2.ZERO

func _ready() -> void:
	$Equipment.active_changed.connect(_on_active_changed)
	$Equipment.attack_performed.connect($WeaponCombat.attack)
	$WeaponVisual.bind_equipment($Equipment)
	$Equipment.initialize(weapon)
	health.died.connect($Equipment.disable_all)

func _on_active_changed(active: Node) -> void:
	weapon = active
	_require_shoot_release = true

func _unhandled_input(event: InputEvent) -> void:
	if health.is_dead() or controls_blocked: return
	if event.is_action_pressed("weapon_next"):
		$Equipment.cycle(1)
	elif event.is_action_pressed("weapon_previous"):
		$Equipment.cycle(-1)

func _physics_process(_delta: float) -> void:
	if health.is_dead() or controls_blocked:
		velocity = Vector2.ZERO
		return
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * speed
	move_and_slide()
	var aim_direction := global_position.direction_to(get_global_mouse_position())
	$Aim.rotation = aim_direction.angle()
	for index in range(4):
		if Input.is_action_just_pressed("weapon_" + str(index + 1)):
			$Equipment.switch_to(EquipmentComponent.ORDER[index])
	if not Input.is_action_pressed("shoot"):
		_require_shoot_release = false
	if Input.is_action_just_pressed("reload"):
		weapon.start_reload()
	if Input.is_action_pressed("shoot") and not _require_shoot_release:
		weapon.try_fire(global_position, aim_direction)
