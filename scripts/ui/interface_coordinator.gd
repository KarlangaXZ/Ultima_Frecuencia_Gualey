extends Node
## Un único bloqueo derivado de las ventanas visibles, sin pausas globales.
@onready var main: Node = get_parent()

func _ready() -> void:
	main.get_node("InventoryUI").opened_changed.connect(_inventory_changed)
	main.get_node("CharacterUI").opened_changed.connect(_character_changed)

func _inventory_changed(active: bool) -> void:
	if active: main.get_node("CharacterUI").close_window()
	_refresh_block()

func _character_changed(active: bool) -> void:
	if active: main.get_node("InventoryUI").close_window()
	_refresh_block()

func _refresh_block() -> void:
	main.get_node("Player").set_controls_blocked(main.get_node("InventoryUI").window.visible or main.get_node("CharacterUI").window.visible)
