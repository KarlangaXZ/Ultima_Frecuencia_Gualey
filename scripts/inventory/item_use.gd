extends Node
## Adaptador de consumibles: no mantiene copias de HP ni munición utilizable.
signal feedback(message: String)
signal item_used(item: ItemDefinition)
signal action_rejected
@onready var inventory: InventoryComponent = $"../InventoryComponent"
@onready var health: HealthComponent = $"../HealthComponent"
@onready var survival: SurvivalComponent = $"../SurvivalComponent"
@onready var equipment: EquipmentComponent = $"../Equipment"
var _using := false

func can_use(index: int) -> bool:
	var slot := inventory.get_slot(index)
	if health.is_dead() or slot.is_empty(): return false
	var item := slot.item as ItemDefinition
	match item.effect:
		"health": return health.current_health < health.max_health
		"hunger": return survival.hunger < 100
		"thirst": return survival.thirst < 100
		"ammo":
			var recipient := equipment.ammo_weapon(item.ammo_type)
			return recipient != null and recipient.enabled and int(item.effect_amount) > 0
		"weapon": return equipment.can_obtain(item.weapon_config)
	return false

func use_slot(index: int) -> bool:
	if _using: return false
	if not can_use(index):
		var blocked_slot := inventory.get_slot(index)
		var message := "No necesitas este objeto ahora."
		if not blocked_slot.is_empty() and blocked_slot.item.effect == "ammo" and equipment.ammo_weapon(blocked_slot.item.ammo_type) == null:
			message = "Necesitas obtener el arma de este tipo de munición."
		elif not blocked_slot.is_empty() and blocked_slot.item.effect == "weapon":
			message = "No se puede incorporar: arma ya poseída o no disponible."
		feedback.emit(message)
		action_rejected.emit()
		return false
	_using = true
	var slot := inventory.get_slot(index)
	var item := slot.item as ItemDefinition
	var quantity: int = slot.quantity if item.effect == "ammo" else 1
	if not inventory.remove_from_slot(index, quantity):
		_using = false
		return false
	match item.effect:
		"health": health.heal(item.effect_amount)
		"hunger", "thirst": survival.restore_need(item.effect, item.effect_amount)
		"ammo": equipment.ammo_weapon(item.ammo_type).add_reserve(int(item.effect_amount) * quantity)
		"weapon": equipment.obtain(item.weapon_config)
	var message := "Utilizado: " + item.display_name
	if item.effect == "ammo": message = "Reserva reabastecida: +%d balas." % (int(item.effect_amount) * quantity)
	elif item.effect == "weapon": message = "Arsenal: " + item.display_name + ". Selecciona con 1–4 al cerrar."
	feedback.emit(message)
	item_used.emit(item)
	_using = false
	return true
