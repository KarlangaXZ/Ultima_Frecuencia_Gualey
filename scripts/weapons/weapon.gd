extends Node
## Estado del arma, sin entrada, física de impactos ni referencias al HUD.
signal ammo_changed(loaded: int, reserve: int)
signal reload_changed(active: bool)
signal shot_fired(origin: Vector2, direction: Vector2, damage: float, shot_range: float)

@export var config: WeaponConfig
var loaded: int
var reserve: int
var cooldown: float = 0.0
var reload_remaining: float = 0.0
var reloading: bool = false
var enabled: bool = true

func _ready() -> void:
	loaded = config.capacity
	reserve = config.initial_reserve

func _physics_process(delta: float) -> void:
	if not enabled:
		return
	cooldown = maxf(0.0, cooldown - delta)
	if reloading:
		reload_remaining = maxf(0.0, reload_remaining - delta)
		if reload_remaining <= 0.0:
			var transferred := mini(config.capacity - loaded, reserve)
			loaded += transferred
			reserve -= transferred
			reloading = false
			ammo_changed.emit(loaded, reserve)
			reload_changed.emit(false)

func try_fire(origin: Vector2, direction: Vector2) -> bool:
	if not enabled or reloading or cooldown > 0.00001 or loaded <= 0 or direction.is_zero_approx():
		return false
	loaded -= 1
	cooldown = config.fire_interval
	ammo_changed.emit(loaded, reserve)
	shot_fired.emit(origin, direction.normalized(), config.damage, config.shot_range)
	return true

func start_reload() -> bool:
	if not enabled or reloading or loaded >= config.capacity or reserve <= 0:
		return false
	reloading = true
	reload_remaining = config.reload_duration
	reload_changed.emit(true)
	return true

func disable() -> void:
	enabled = false
	reload_remaining = 0.0
	if reloading:
		reloading = false
		reload_changed.emit(false)

func add_reserve(amount: int) -> bool:
	if not enabled or amount <= 0: return false
	reserve += amount
	ammo_changed.emit(loaded, reserve)
	return true
