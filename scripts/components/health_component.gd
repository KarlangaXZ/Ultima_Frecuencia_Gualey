class_name HealthComponent
extends Node
## Fuente única de salud para cualquier personaje.
signal health_changed(current: float, maximum: float)
signal died

@export_range(1.0, 10000.0) var max_health: float = 100.0
var current_health: float
var base_max_health: float
var _max_health_bonus := 0.0

func _ready() -> void:
	base_max_health = max_health
	current_health = max_health

func set_max_health_bonus(amount: float) -> void:
	if is_dead() or is_equal_approx(amount, _max_health_bonus): return
	_max_health_bonus = maxf(0, amount)
	max_health = base_max_health + _max_health_bonus
	current_health = minf(current_health, max_health)
	health_changed.emit(current_health, max_health)

func is_dead() -> bool:
	return current_health <= 0.0

func heal(amount: float) -> float:
	if amount <= 0 or is_dead(): return 0
	var restored := minf(amount, max_health - current_health)
	if restored > 0:
		current_health += restored
		health_changed.emit(current_health, max_health)
	return restored

func take_damage(amount: float) -> void:
	if amount <= 0.0 or is_dead():
		return
	current_health = maxf(0.0, current_health - amount)
	health_changed.emit(current_health, max_health)
	if is_dead():
		died.emit()
