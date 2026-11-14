extends Node
## Única concesión por evento. Registro por instancia, reservado antes de notificar.
@export_range(0, 10000) var zombie_xp := 30
@export_range(0, 10000) var container_xp := 20
@onready var progression: ProgressionComponent = $"../ProgressionComponent"
@onready var health: HealthComponent = $"../HealthComponent"
var _zombies: Dictionary = {}
var _containers: Dictionary = {}

func _ready() -> void:
	health.died.connect(progression.stop)

func zombie_eliminated(source: Node) -> bool:
	if not is_instance_valid(source) or health.is_dead() or not progression.enabled: return false
	var source_health := source.get_node_or_null("HealthComponent") as HealthComponent
	if source_health == null or not source_health.is_dead(): return false
	var id := source.get_instance_id()
	if _zombies.has(id): return false
	_zombies[id] = true
	return progression.add_xp(zombie_xp)

func container_opened(source: LootContainer) -> bool:
	if not is_instance_valid(source) or health.is_dead() or not progression.enabled: return false
	if source.inventory.occupied_slots() == 0: return false
	var id := source.get_instance_id()
	if _containers.has(id): return false
	_containers[id] = true
	return progression.add_xp(container_xp)
