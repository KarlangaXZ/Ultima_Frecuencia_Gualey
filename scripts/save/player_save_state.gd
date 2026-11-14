class_name PlayerSaveState
extends RefCounted
static func capture(player: Node) -> Dictionary:
	var equipment: EquipmentComponent = player.get_node("Equipment")
	var weapons := {}
	for weapon in equipment.get_weapons():
		weapons[String(weapon.config.id)] = {"loaded": weapon.loaded, "reserve": weapon.reserve, "cooldown": weapon.cooldown}
	var survival: SurvivalComponent = player.get_node("SurvivalComponent")
	return {"position": [player.position.x, player.position.y], "base_health": player.health.base_max_health,
		"health": player.health.current_health, "base_speed": player.speed, "hunger": survival.hunger, "thirst": survival.thirst,
		"hunger_period": survival.hunger_seconds_per_point, "thirst_period": survival.thirst_seconds_per_point,
		"penalty_time": survival._penalty_time, "progression": player.get_node("ProgressionComponent").snapshot(),
		"skills": player.get_node("SkillsComponent").snapshot(), "inventory": SaveCatalog.slots(player.get_node("InventoryComponent")),
		"weapons": weapons, "equipped": String(equipment.active_weapon.config.id),
		"facing": player.get_node("Visual").direction_name, "aim": player.get_node("Aim").rotation}

static func restore(player: Node, data: Dictionary) -> void:
	player.position = Vector2(data.position[0], data.position[1])
	player.velocity = Vector2.ZERO
	player.speed = data.base_speed
	player.health.base_max_health = data.base_health
	player.health.max_health = data.base_health
	player.health._max_health_bonus = 0.0
	var progression: ProgressionComponent = player.get_node("ProgressionComponent")
	progression.level = int(data.progression.level)
	progression.xp = int(data.progression.xp)
	progression.available_points = int(data.progression.available_points)
	player.get_node("SkillsComponent")._ranks.clear()
	for id in SaveCatalog.SKILLS: player.get_node("SkillsComponent")._ranks[StringName(id)] = int(data.skills[id])
	SaveCatalog.restore_slots(player.get_node("InventoryComponent"), data.inventory)
	var equipment: EquipmentComponent = player.get_node("Equipment")
	for id in data.weapons:
		if not equipment.owns(StringName(id)): equipment.obtain(SaveCatalog.WEAPONS[id])
		var weapon: Node = equipment.get_weapon(StringName(id))
		weapon.loaded = int(data.weapons[id].loaded)
		weapon.reserve = int(data.weapons[id].reserve)
		weapon.cooldown = data.weapons[id].cooldown
		weapon.reloading = false
		weapon.reload_remaining = 0.0
	equipment.selection_blocked = false
	equipment.switch_to(StringName(data.equipped))
	player.get_node("Stats").refresh()
	player.health.current_health = data.health
	var survival: SurvivalComponent = player.get_node("SurvivalComponent")
	survival.hunger = data.hunger
	survival.thirst = data.thirst
	survival.hunger_seconds_per_point = data.hunger_period
	survival.thirst_seconds_per_point = data.thirst_period
	survival._penalty_time = data.penalty_time
	player.get_node("Visual").last_health = data.health
	player.get_node("Visual").direction_name = data.facing
	player.get_node("Visual").movement_facing = {"up": Vector2.UP, "down": Vector2.DOWN, "left": Vector2.LEFT, "right": Vector2.RIGHT}[data.facing]
	player.get_node("Visual").has_moved = true
	player.get_node("Visual/Sprite").play("idle_" + data.facing)
	player.get_node("Aim").rotation = data.aim
	player.set_controls_blocked(false)
