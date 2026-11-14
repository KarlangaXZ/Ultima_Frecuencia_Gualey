extends Node2D
## Consulta física de cercanía y visibilidad; no interpreta ni aplica consumibles.
signal prompt_changed(text: String)
signal feedback(message: String)
signal container_opened(container: LootContainer)
signal item_collected(item: ItemDefinition)
signal action_rejected
@export_range(1, 200) var interaction_radius: float = 56.0
@onready var actor: CharacterBody2D = get_parent()
@onready var inventory: InventoryComponent = $"../InventoryComponent"
var target: Area2D
var _last_prompt := ""

func can_access(candidate: Area2D) -> bool:
	if not is_instance_valid(candidate) or not candidate.is_inside_tree() or actor.health.is_dead(): return false
	if actor.global_position.distance_to(candidate.global_position) > interaction_radius: return false
	var ray := PhysicsRayQueryParameters2D.create(actor.global_position, candidate.global_position, 1)
	ray.hit_from_inside = true
	return get_world_2d().direct_space_state.intersect_ray(ray).is_empty()

func nearest_target() -> Area2D:
	var circle := CircleShape2D.new()
	circle.radius = interaction_radius
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = circle
	query.transform = Transform2D(0, actor.global_position)
	query.collision_mask = 8
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var nearest: Area2D
	var distance := INF
	for result in get_world_2d().direct_space_state.intersect_shape(query, 64):
		var candidate := result.collider as Area2D
		if not (candidate is WorldPickup or candidate is LootContainer): continue
		if candidate is WorldPickup and candidate.claimed: continue
		if not can_access(candidate): continue
		var current := actor.global_position.distance_squared_to(candidate.global_position)
		if current < distance:
			nearest = candidate
			distance = current
	return nearest

func _physics_process(_delta: float) -> void:
	target = null if actor.controls_blocked or actor.health.is_dead() else nearest_target()
	var text: String = "E · " + target.interaction_name() if is_instance_valid(target) else ""
	if text != _last_prompt:
		_last_prompt = text
		prompt_changed.emit(text)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		try_interact()
		get_viewport().set_input_as_handled()

func try_interact() -> void:
	if actor.controls_blocked or actor.health.is_dead(): return
	target = nearest_target()
	if target is WorldPickup:
		var pickup := target as WorldPickup
		var message := pickup.try_collect(inventory)
		feedback.emit(message)
		if not message.is_empty():
			if pickup.claimed: item_collected.emit(pickup.item)
			else: action_rejected.emit()
	elif target is LootContainer:
		container_opened.emit(target)

func transfer_from_container(container: LootContainer, index: int) -> bool:
	if not can_access(container):
		feedback.emit("El contenedor está fuera de alcance.")
		action_rejected.emit()
		return false
	var slot := container.inventory.get_slot(index)
	if container.inventory.transfer_slot_to(index, inventory):
		feedback.emit("Suministros guardados en la mochila.")
		item_collected.emit(slot.item)
		return true
	feedback.emit("No se pudo transferir: sin espacio o compartimento vacío.")
	action_rejected.emit()
	return false
