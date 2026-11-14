class_name InventoryComponent
extends Node
## Almacenamiento por instancia; las transferencias son completas y atómicas.
signal changed
@export_range(1, 120) var capacity: int = 12
var _slots: Array[Dictionary] = []

func _ready() -> void:
	for index in range(capacity):
		_slots.append({})

func get_slot(index: int) -> Dictionary:
	return _slots[index].duplicate() if index >= 0 and index < _slots.size() else {}

func occupied_slots() -> int:
	var total := 0
	for slot in _slots:
		if not slot.is_empty(): total += 1
	return total

func count_item(id: StringName) -> int:
	var total := 0
	for slot in _slots:
		if not slot.is_empty() and slot.item.id == id: total += slot.quantity
	return total

func space_for(item: ItemDefinition) -> int:
	if item == null or not item.is_valid_definition(): return 0
	var total := 0
	for slot in _slots:
		if slot.is_empty():
			total += item.max_stack
		elif slot.item.id == item.id:
			# Un identificador no puede representar dos definiciones incompatibles.
			if slot.item != item: return 0
			total += maxi(0, item.max_stack - slot.quantity)
	return total

func can_add(item: ItemDefinition, quantity: int) -> bool:
	return quantity > 0 and space_for(item) >= quantity

func _store(item: ItemDefinition, quantity: int) -> void:
	for slot in _slots:
		if not slot.is_empty() and slot.item == item:
			var amount := mini(quantity, item.max_stack - slot.quantity)
			slot.quantity += amount
			quantity -= amount
	for index in range(_slots.size()):
		if quantity == 0: break
		if _slots[index].is_empty():
			var amount := mini(quantity, item.max_stack)
			_slots[index] = {"item": item, "quantity": amount}
			quantity -= amount

func add_item(item: ItemDefinition, quantity: int) -> bool:
	if not can_add(item, quantity): return false
	_store(item, quantity)
	changed.emit()
	return true

func remove_from_slot(index: int, quantity: int) -> bool:
	var slot := get_slot(index)
	if quantity <= 0 or slot.is_empty() or slot.quantity < quantity: return false
	_slots[index].quantity -= quantity
	if _slots[index].quantity == 0: _slots[index] = {}
	changed.emit()
	return true

func remove_item(id: StringName, quantity: int) -> bool:
	if quantity <= 0 or count_item(id) < quantity: return false
	for index in range(_slots.size()):
		var slot := get_slot(index)
		if slot.is_empty() or slot.item.id != id: continue
		var amount := mini(quantity, slot.quantity)
		_slots[index].quantity -= amount
		quantity -= amount
		if _slots[index].quantity == 0: _slots[index] = {}
		if quantity == 0: break
	changed.emit()
	return true

func transfer_slot_to(index: int, destination: InventoryComponent) -> bool:
	var slot := get_slot(index)
	if destination == null or destination == self or slot.is_empty(): return false
	if not destination.can_add(slot.item, slot.quantity): return false
	# Completar ambos estados antes de avisar a cualquier observador.
	destination._store(slot.item, slot.quantity)
	_slots[index] = {}
	changed.emit()
	destination.changed.emit()
	return true
