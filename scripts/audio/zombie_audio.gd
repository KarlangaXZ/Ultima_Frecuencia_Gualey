extends Node2D
## Observa salud y renovaciones de cooldown, igual que la capa visual; no toca IA.
@export_range(-60, 0) var volume_db: float = -18.0
@export var groans_enabled := true
var emitter: SoundEmitter
var _last_health: float
var _previous_cooldown: float = 0
var _groan_remaining: float
@onready var actor: Node = get_parent()

func _ready() -> void:
	emitter = SoundEmitter.new()
	emitter.positional = true
	emitter.max_voices = 3
	emitter.volume_db = volume_db
	add_child(emitter)
	_last_health = actor.max_health
	_groan_remaining = 3.0 + actor.get_index() * 1.7
	actor.get_node("HealthComponent").health_changed.connect(_on_health_changed)
	actor.get_node("HealthComponent").died.connect(_on_died)

func _process(delta: float) -> void:
	if actor.health.is_dead(): return
	var cooldown: float = actor.cooldown
	if actor.state == 2 and cooldown > _previous_cooldown + 0.00001:
		emitter.play_event(&"zombie_attack", 0.1)
	_previous_cooldown = cooldown
	if not groans_enabled or not is_instance_valid(actor.target): return
	_groan_remaining -= delta
	if _groan_remaining <= 0:
		emitter.play_event(&"zombie_groan")
		_groan_remaining = 12.0 + actor.get_index() * 1.1

func _on_health_changed(current: float, _maximum: float) -> void:
	if current > 0 and current < _last_health: emitter.play_event(&"zombie_hurt", 0.12)
	_last_health = current

func _on_died() -> void:
	emitter.stop_all()
	emitter.play_event(&"zombie_death")
