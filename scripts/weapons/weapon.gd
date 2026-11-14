extends Node
## Estado del arma, sin entrada, física de impactos ni referencias al HUD.
signal ammo_changed(loaded: int, reserve: int)
signal reload_changed(active: bool)
signal shot_fired(origin: Vector2, direction: Vector2, damage: float, shot_range: float)
signal melee_attacked(origin: Vector2, direction: Vector2, damage: float, shot_range: float)

@export var config: WeaponConfig
var loaded: int
var reserve: int
var cooldown: float = 0.0
var reload_remaining: float = 0.0
var reloading: bool = false
var enabled: bool = true
var equipped: bool = true

func _ready() -> void:
	loaded = config.capacity if config.initial_loaded < 0 else clampi(config.initial_loaded, 0, config.capacity)
	reserve = config.initial_reserve if config.weapon_type != "melee" else 0

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
	if not enabled or not equipped or reloading or cooldown > 0.00001 or direction.is_zero_approx():
		return false
	if config.weapon_type != "melee":
		if loaded <= 0: return false
		loaded -= 1
	cooldown = config.fire_interval
	if config.weapon_type == "melee":
		melee_attacked.emit(origin, direction.normalized(), config.damage, config.shot_range)
	else:
		ammo_changed.emit(loaded, reserve)
		shot_fired.emit(origin, direction.normalized(), config.damage, config.shot_range)
	return true

func start_reload() -> bool:
	if not enabled or not equipped or config.weapon_type == "melee" or reloading or loaded >= config.capacity or reserve <= 0:
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
	if not enabled or config.weapon_type == "melee" or amount <= 0: return false
	reserve += amount
	ammo_changed.emit(loaded, reserve)
	return true

func set_equipped(active: bool) -> void:
	equipped = active
	if not active and reloading:
		reloading = false
		reload_remaining = 0
		reload_changed.emit(false)
