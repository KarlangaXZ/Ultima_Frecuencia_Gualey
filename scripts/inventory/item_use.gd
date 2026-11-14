extends Node
## Adaptador de consumibles: no mantiene copias de HP ni munición utilizable.
signal feedback(message: String)
@onready var inventory: InventoryComponent = $"../InventoryComponent"
@onready var health: HealthComponent = $"../HealthComponent"
@onready var survival: SurvivalComponent = $"../SurvivalComponent"
@onready var weapon: Node = $"../Weapon"
var _using := false

func can_use(index: int) -> bool:
	var slot := inventory.get_slot(index)
	if health.is_dead() or slot.is_empty(): return false
	var item := slot.item as ItemDefinition
	match item.effect:
		"health": return health.current_health < health.max_health
		"hunger": return survival.hunger < 100
		"thirst": return survival.thirst < 100
		"ammo": return weapon.enabled and int(item.effect_amount) > 0
	return false

func use_slot(index: int) -> bool:
	if _using: return false
	if not can_use(index):
		feedback.emit("No necesitas este objeto ahora.")
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
		"ammo": weapon.add_reserve(int(item.effect_amount) * quantity)
	feedback.emit("Reserva reabastecida: +%d balas." % (int(item.effect_amount) * quantity)
		if item.effect == "ammo" else "Utilizado: " + item.display_name)
	_using = false
	return true
