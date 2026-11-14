extends Node
## Reserva la recompensa antes de emitir XP: no puede cobrarse por reentrada.
@onready var main: Node = get_parent().get_parent()
@onready var tracker: MissionTracker = get_parent()
var _awarded: Dictionary = {}

func _ready() -> void:
	tracker.mission_completed.connect(award)

func award(mission: MissionDefinition) -> bool:
	if mission == null or not tracker.definitions.has(mission): return false
	if tracker.state_of(mission.id) != MissionTracker.State.COMPLETED: return false
	var progression: ProgressionComponent = main.get_node("Player/ProgressionComponent")
	if not tracker.enabled or not progression.enabled or main.get_node("Player/HealthComponent").is_dead(): return false
	if _awarded.has(mission.id): return false
	_awarded[mission.id] = true
	return progression.add_xp(mission.reward_xp)
