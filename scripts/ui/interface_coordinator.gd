extends Node
## Un único bloqueo derivado de las ventanas visibles, sin pausas globales.
@onready var main: Node = get_parent()

func _ready() -> void:
	for name in ["InventoryUI", "CharacterUI", "MissionUI", "RadioUI"]:
		main.get_node(name).opened_changed.connect(_window_changed.bind(name))

func _window_changed(active: bool, source: String) -> void:
	if active:
		for name in ["InventoryUI", "CharacterUI", "MissionUI", "RadioUI"]:
			if name != source: main.get_node(name).close_window()
	_refresh_block()

func _refresh_block() -> void:
	var blocked := false
	for name in ["InventoryUI", "CharacterUI", "MissionUI", "RadioUI"]:
		blocked = blocked or main.get_node(name).window.visible
	main.get_node("Player").set_controls_blocked(blocked)
	main.get_node("ObjectiveHUD").visible = not blocked and not main.get_node("Player/HealthComponent").is_dead()
