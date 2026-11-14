extends SceneTree
var checks := 0
var failures := 0
var notifications := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var inventory := InventoryComponent.new()
	root.add_child(inventory)
	inventory.changed.connect(func(): notifications += 1)
	var medkit := load("res://resources/items/Medkit.tres") as ItemDefinition
	var ammo := load("res://resources/items/PistolAmmo.tres") as ItemDefinition
	var water := load("res://resources/items/Water.tres") as ItemDefinition
	var food := load("res://resources/items/Food.tres") as ItemDefinition
	for item in [medkit, ammo, water, food]:
		check(item.is_valid_definition() and item.icon != null, "Definición e icono: " + String(item.id))
	check(inventory.capacity == 12 and inventory.occupied_slots() == 0, "Doce espacios vacíos")
	check(not inventory.add_item(medkit, 0) and not inventory.add_item(medkit, -1), "No agregar cantidades no positivas")
	check(not inventory.add_item(null, 1), "No agregar recursos nulos")
	check(inventory.add_item(ammo, 61), "Apilar 61 balas")
	check(inventory.get_slot(0).quantity == 60 and inventory.get_slot(1).quantity == 1, "Máximo 60 por pila")
	check(inventory.count_item(ammo.id) == 61 and inventory.occupied_slots() == 2, "Consulta total sin duplicación")
	var copy := inventory.get_slot(0)
	copy.quantity = -100
	check(inventory.get_slot(0).quantity == 60, "La consulta no expone cantidades mutables")
	check(not inventory.remove_from_slot(-1, 1) and not inventory.remove_from_slot(12, 1), "Índices fuera de rango")
	check(not inventory.remove_from_slot(0, -1) and not inventory.remove_from_slot(0, 61), "Retirada inválida no muta pila")
	check(not inventory.remove_item(ammo.id, 62) and inventory.count_item(ammo.id) == 61, "Retirada total atómica")
	check(inventory.remove_item(ammo.id, 60) and inventory.count_item(ammo.id) == 1, "Retirada entre pilas")
	check(inventory.remove_item(ammo.id, 1) and inventory.occupied_slots() == 0, "Liberación de espacios vacíos")
	check(inventory.add_item(medkit, 60) and inventory.occupied_slots() == 12, "Capacidad exacta de doce pilas")
	check(not inventory.can_add(water, 1) and not inventory.add_item(water, 1), "Rechazo de tipo nuevo con mochila llena")
	check(not inventory.add_item(medkit, 1) and inventory.count_item(medkit.id) == 60, "Sin exceso en inventario lleno")
	check(inventory.remove_from_slot(0, 1) and inventory.space_for(medkit) == 1, "Hueco parcial reutilizable")
	var before := notifications
	check(not inventory.add_item(medkit, 2) and notifications == before, "Sin inserción parcial ni señal falsa")
	check(inventory.add_item(medkit, 1) and inventory.get_slot(0).quantity == 5, "Reapilar hueco existente")
	var impostor := medkit.duplicate() as ItemDefinition
	impostor.max_stack = 999
	check(not inventory.add_item(impostor, 1), "Identificador duplicado con otra definición rechazado")
	var source := InventoryComponent.new()
	root.add_child(source)
	check(source.add_item(food, 3), "Contenedor con recursos finitos")
	check(not source.transfer_slot_to(0, inventory) and source.count_item(food.id) == 3, "Transferencia llena conserva origen")
	check(not source.transfer_slot_to(0, source) and not source.transfer_slot_to(0, null), "Destinos inválidos")
	check(inventory.remove_from_slot(0, 5), "Liberar una pila")
	check(source.transfer_slot_to(0, inventory) and source.count_item(food.id) == 0 and inventory.count_item(food.id) == 3, "Transferencia sin duplicación")
	check(not source.transfer_slot_to(0, inventory) and inventory.count_item(food.id) == 3, "Repetir transferencia vacía no duplica")
	check(source.add_item(water, 2), "Nuevo contenido de prueba")
	inventory.remove_from_slot(1, 5)
	# La señal del origen puede intentar repetir la operación: el estado ya está cerrado.
	source.changed.connect(func(): source.transfer_slot_to(0, inventory))
	check(source.transfer_slot_to(0, inventory) and inventory.count_item(water.id) == 2, "Transferencia reentrante sigue siendo única")
	check(not inventory.remove_item(food.id, -2) and not inventory.remove_item(food.id, 0), "No retirar cero o cantidades negativas")
	source.queue_free()
	inventory.queue_free()
	await process_frame
	print("Resultado inventario: ", checks, " comprobaciones, ", failures, " fallos")
	quit(0 if failures == 0 else 1)
