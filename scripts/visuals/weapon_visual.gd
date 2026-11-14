extends Node
## Sustitución del dibujo del arma y conexión de animaciones existentes.
func bind_equipment(equipment: EquipmentComponent) -> void:
	equipment.active_changed.connect(_on_active_changed)

func _on_active_changed(weapon: Node) -> void:
	var actor := get_parent()
	actor.get_node("Visual").bind_weapon(weapon)
	actor.get_node("Aim/Barrel").texture = weapon.config.visual
