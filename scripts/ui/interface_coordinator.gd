extends Node
## Un único bloqueo derivado de las ventanas visibles, sin pausas globales.
@onready var main: Node = get_parent()
var _paused := false
var _previous_ambience_pause := false
var transitioning := false

func set_transitioning(active: bool) -> void:
	transitioning = active
	_refresh_block()

func _ready() -> void:
	for name in ["InventoryUI", "CharacterUI", "MissionUI", "RadioUI", "PauseUI"]:
		main.get_node(name).opened_changed.connect(_window_changed.bind(name))

func _window_changed(active: bool, source: String) -> void:
	if active:
		for name in ["InventoryUI", "CharacterUI", "MissionUI", "RadioUI", "PauseUI"]:
			if name != source: main.get_node(name).close_window()
	_refresh_block()

func _refresh_block() -> void:
	var blocked := transitioning
	for name in ["InventoryUI", "CharacterUI", "MissionUI", "RadioUI", "PauseUI"]:
		blocked = blocked or main.get_node(name).window.visible
	main.get_node("Player").set_controls_blocked(blocked)
	main.get_node("ObjectiveHUD").visible = not blocked and not main.get_node("Player/HealthComponent").is_dead()
	var paused: bool = main.get_node("PauseUI").window.visible or transitioning
	if paused != _paused:
		if paused: _previous_ambience_pause = main.get_node("Audio").ambience_paused
		main.get_node("Audio").set_ambience_paused(true if paused else _previous_ambience_pause)
		get_tree().paused = paused
		_paused = paused
