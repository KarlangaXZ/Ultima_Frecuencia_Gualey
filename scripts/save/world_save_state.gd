class_name WorldSaveState
extends RefCounted
static func capture(main: Node) -> Dictionary:
	var containers := {}
	var pickups := {}
	for id in SaveCatalog.CONTAINERS:
		var container: Node = SaveCatalog.find(main.get_node("World"), id)
		containers[id] = {"opened": container.opened, "slots": SaveCatalog.slots(container.inventory)}
	for id in SaveCatalog.PICKUPS:
		var pickup: Node = SaveCatalog.find(main.get_node("World"), id)
		pickups[id] = is_instance_valid(pickup) and not pickup.claimed
	var zombies := []
	for zombie in main.get_node("Zombies").get_children():
		zombies.append({"id": SaveCatalog.id_of(zombie), "type": "base", "position": [zombie.position.x, zombie.position.y],
			"health": zombie.health.current_health, "cooldown": zombie.cooldown})
	var population: Node = main.get_node("Population")
	var rewards: Node = main.get_node("Player/ProgressionRewards")
	return {"containers": containers, "pickups": pickups, "zombies": zombies,
		"population": {"spawned": population.total_spawned, "remaining": population._remaining, "cursor": population._cursor},
		"rewarded_zombies": rewards._zombies.keys(), "rewarded_containers": rewards._containers.keys(),
		"kills": main.kills, "survival_time": main.survival_time}

static func restore(main: Node, data: Dictionary) -> void:
	for id in SaveCatalog.CONTAINERS:
		var container: Node = SaveCatalog.find(main.get_node("World"), id)
		container.opened = data.containers[id].opened
		SaveCatalog.restore_slots(container.inventory, data.containers[id].slots)
	for id in SaveCatalog.PICKUPS:
		if not data.pickups[id]:
			var pickup: Node = SaveCatalog.find(main.get_node("World"), id)
			pickup.get_parent().remove_child(pickup)
			pickup.queue_free()
	var actors: Node = main.get_node("Zombies")
	for zombie in actors.get_children():
		actors.remove_child(zombie)
		zombie.queue_free()
	for saved in data.zombies:
		var zombie: Node = load("res://scenes/enemies/Zombie.tscn").instantiate()
		var ordinal := int(String(saved.id).trim_prefix("zombie_"))
		zombie.name = ["ZombieA", "ZombieB", "ZombieC"][ordinal - 1] if ordinal <= 3 else "PopulationZombie%02d" % ordinal
		zombie.set_meta("persistence_id", saved.id)
		zombie.position = Vector2(saved.position[0], saved.position[1])
		actors.add_child(zombie)
		main._register_zombie(zombie)
		zombie.health.current_health = saved.health
		zombie.cooldown = saved.cooldown
		zombie.get_node("Audio")._last_health = saved.health
		zombie.get_node("Visual").last_health = saved.health
		if saved.health <= 0:
			# Cadáver sin died/eliminated: ninguna recompensa ni sonido de muerte.
			zombie.state = 3
			zombie.stop_targeting()
			zombie.collision_layer = 0
			zombie.collision_mask = 0
			zombie.get_node("CollisionShape2D").disabled = true
			zombie.modulate.a = 0.25
			var visual: Node = zombie.get_node("Visual")
			visual.dead = true
			visual.sprite.animation = "death_down"
			visual.sprite.stop()
			visual.sprite.frame = visual.sprite.sprite_frames.get_frame_count("death_down") - 1
	var population: Node = main.get_node("Population")
	population.restore_population(data.population)
	var rewards: Node = main.get_node("Player/ProgressionRewards")
	rewards._zombies.clear()
	rewards._containers.clear()
	for id in data.rewarded_zombies: rewards._zombies[id] = true
	for id in data.rewarded_containers: rewards._containers[id] = true
	main.kills = int(data.kills)
	main.survival_time = data.survival_time
