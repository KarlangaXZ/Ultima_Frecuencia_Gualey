class_name ProgressionComponent
extends Node
## XP dentro del nivel y puntos disponibles; ningún almacenamiento persistente.
signal changed
signal leveled_up(level: int, points_gained: int)
@export_range(1, 100) var initial_level: int = 1
@export_range(0, 1000000) var initial_xp: int = 0
@export_range(1, 100) var max_level: int = 10
@export_range(1, 1000000) var first_requirement: int = 100
@export_range(0, 1000000) var requirement_increment: int = 50
@export_range(1, 100) var points_per_level: int = 1
var level: int = 1
var xp: int = 0
var available_points: int = 0
var enabled := true

func _ready() -> void:
	level = clampi(initial_level, 1, maxi(1, max_level))
	add_xp(initial_xp)

func required_xp() -> int:
	return 0 if level >= max_level else maxi(1, first_requirement + (level - 1) * requirement_increment)

func total_xp() -> int:
	var total := xp
	for previous in range(1, level):
		total += maxi(1, first_requirement + (previous - 1) * requirement_increment)
	return total

func add_xp(amount: int) -> bool:
	if not enabled or amount <= 0 or level >= max_level: return false
	xp += amount
	var gained := 0
	while level < max_level and xp >= required_xp():
		xp -= required_xp()
		level += 1
		gained += maxi(1, points_per_level)
	available_points += gained
	# El nivel máximo no almacena XP sin uso ni puntos extra.
	if level >= max_level: xp = 0
	changed.emit()
	if gained > 0: leveled_up.emit(level, gained)
	return true

func spend_point() -> bool:
	if not enabled or available_points <= 0: return false
	available_points -= 1
	changed.emit()
	return true

func stop() -> void:
	enabled = false
	changed.emit()

func snapshot() -> Dictionary:
	return {"level": level, "xp": xp, "available_points": available_points}
