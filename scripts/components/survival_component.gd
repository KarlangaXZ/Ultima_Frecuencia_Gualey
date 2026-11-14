class_name SurvivalComponent
extends Node
## Un único reloj de penalización aunque hambre y sed estén a cero a la vez.
signal needs_changed(hunger: float, thirst: float)
@export var health_path: NodePath = ^"../HealthComponent"
@export_range(0.1, 3600.0) var hunger_seconds_per_point: float = 30.0
@export_range(0.1, 3600.0) var thirst_seconds_per_point: float = 20.0
@export_range(0.1, 3600.0) var penalty_interval: float = 5.0
@export_range(0.0, 1000.0) var penalty_damage: float = 2.0
var hunger: float = 100.0
var thirst: float = 100.0
var _penalty_time: float = 0.0
var _active: bool = true
@onready var health: HealthComponent = get_node(health_path)

func _ready() -> void:
	health.died.connect(func(): _active = false)

func _physics_process(delta: float) -> void:
	advance(delta)

func advance(delta: float) -> void:
	if not _active or health.is_dead() or delta <= 0: return
	var hunger_period := maxf(0.1, hunger_seconds_per_point)
	var thirst_period := maxf(0.1, thirst_seconds_per_point)
	var until_empty := minf(hunger * hunger_period, thirst * thirst_period)
	hunger = clampf(hunger - delta / hunger_period, 0, 100)
	thirst = clampf(thirst - delta / thirst_period, 0, 100)
	needs_changed.emit(hunger, thirst)
	if hunger > 0 and thirst > 0:
		_penalty_time = 0
		return
	_penalty_time += maxf(0, delta - until_empty)
	var period := maxf(0.1, penalty_interval)
	while _penalty_time + 0.00001 >= period and not health.is_dead():
		_penalty_time = maxf(0, _penalty_time - period)
		health.take_damage(penalty_damage)

func restore_need(need: String, amount: float) -> float:
	if not _active or health.is_dead() or amount <= 0: return 0
	var recovered := 0.0
	if need == "hunger":
		recovered = minf(amount, 100 - hunger)
		hunger = clampf(hunger + recovered, 0, 100)
	elif need == "thirst":
		recovered = minf(amount, 100 - thirst)
		thirst = clampf(thirst + recovered, 0, 100)
	if recovered > 0:
		if hunger > 0 and thirst > 0: _penalty_time = 0
		needs_changed.emit(hunger, thirst)
	return recovered
