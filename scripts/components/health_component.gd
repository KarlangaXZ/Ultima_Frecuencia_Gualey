class_name HealthComponent
extends Node
## Fuente única de salud para cualquier personaje.
signal health_changed(current: float, maximum: float)
signal died

@export_range(1.0, 10000.0) var max_health: float = 100.0
var current_health: float

func _ready() -> void:
	current_health = max_health

func is_dead() -> bool:
	return current_health <= 0.0

func take_damage(amount: float) -> void:
	if amount <= 0.0 or is_dead():
		return
	current_health = maxf(0.0, current_health - amount)
	health_changed.emit(current_health, max_health)
	if is_dead():
		died.emit()
