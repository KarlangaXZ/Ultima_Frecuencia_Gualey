extends RefCounted
static func inspect(main: Node) -> Dictionary:
	var player: Node = main.get_node("Player")
	var progression: ProgressionComponent = player.get_node("ProgressionComponent")
	var equipment: EquipmentComponent = player.get_node("Equipment")
	var survival: SurvivalComponent = player.get_node("SurvivalComponent")
	var inventory: InventoryComponent = player.get_node("InventoryComponent")
	var missions: MissionTracker = main.get_node("Missions")
	var population: Node = main.get_node("Population")
	var rewards: Node = player.get_node("ProgressionRewards")
	return {
		"Posición y cámara recuperadas": player.position.is_equal_approx(Vector2(1200,1000)) and player.get_node("Camera2D").get_screen_center_position().is_equal_approx(player.position),
		"Salud efectiva y base": player.health.current_health == 43.5 and player.health.max_health == 105 and player.health.base_max_health == 100,
		"Necesidades restauradas": survival.hunger == 12.25 and survival.thirst == 0,
		"Reloj de privación conservado": survival._penalty_time == 2.75,
		"Nivel/XP/puntos": progression.level == 5 and progression.xp == 60 and progression.available_points == 0,
		"Cuatro rangos únicos": SaveCatalog.SKILLS.all(func(id): return player.get_node("SkillsComponent").rank_of(StringName(id)) == 1),
		"Agilidad desde base": is_equal_approx(player.effective_speed(),247.2) and player.speed == 240,
		"Supervivencia desde base": is_equal_approx(survival.consumption_multiplier,0.95) and survival.hunger_seconds_per_point == 30 and survival.thirst_seconds_per_point == 20,
		"Inventario exacto": inventory.count_item(&"medkit") == 3 and inventory.count_item(&"water") == 2 and inventory.count_item(&"food") == 2 and inventory.count_item(&"pistol_ammo") == 18,
		"Objetos de armas consumidos": inventory.count_item(&"weapon_shotgun") == 0 and inventory.count_item(&"weapon_revolver") == 0,
		"Cuatro estados de arma": equipment.get_weapons().size() == 4 and equipment.active_weapon.config.id == &"shotgun",
		"Pistola sin duplicar balas": equipment.get_weapon(&"pistol").loaded == 7 and equipment.get_weapon(&"pistol").reserve == 31,
		"Revólver sin duplicar balas": equipment.get_weapon(&"revolver").loaded == 3 and equipment.get_weapon(&"revolver").reserve == 9,
		"Escopeta sin transferir recarga": player.weapon.loaded == 2 and player.weapon.reserve == 6 and not player.weapon.reloading,
		"Cooldown conservado": is_equal_approx(player.weapon.cooldown,0.4),
		"Manejo desde base": is_equal_approx(player.weapon.effective_reload_duration(),2.304) and player.weapon.config.reload_duration == 2.4,
		"Dos misiones completadas": missions.state_of(&"signal") == 3 and missions.state_of(&"supplies") == 3,
		"Objetivos activos restaurados": missions.state_of(&"broadcast") == 2 and missions.progress_of(&"broadcast",0) == 1 and missions.progress_of(&"broadcast",1) == 0,
		"Premios de misión marcados": main.get_node("Missions/Rewards")._awarded.size() == 2,
		"Radio y generador restaurados": not main.get_node("World/ChapterPoints/Generator").available and main.get_node("World/ChapterPoints/Radio").available,
		"Transmisión textual conservada": main.get_node("Radio").transmission == SaveCatalog.TRANSMISSIONS.power and main.get_node("Radio").index == 0,
		"Recogibles conservados": SaveCatalog.find(main.get_node("World"),"pickup_water") == null and SaveCatalog.find(main.get_node("World"),"pickup_medkit") == null and SaveCatalog.find(main.get_node("World"),"pickup_food") != null,
		"Contenido de contenedor parcial": SaveCatalog.find(main.get_node("World"),"medical_case").inventory.get_slot(0).is_empty() and SaveCatalog.find(main.get_node("World"),"medical_case").inventory.count_item(&"water") == 1,
		"Contenedores de armas agotados": SaveCatalog.find(main.get_node("World"),"revolver_case").inventory.occupied_slots() == 0 and SaveCatalog.find(main.get_node("World"),"shotgun_case").inventory.occupied_slots() == 0,
		"No renacen enemigos": population.total_spawned == 7 and population.active_enemies().size() == 4 and main.get_node("Zombies").get_child_count() == 7,
		"Presupuesto y demora": population.total_budget == 18 and population.active_limit == 6 and is_equal_approx(population._remaining,6.75),
		"Bajas y reloj": main.kills == 3 and main.survival_time == 321.5,
		"Premios de mundo marcados": rewards._zombies.size() == 3 and rewards._containers.size() == 4,
		"Cadáver desactivado": SaveCatalog.find(main.get_node("Zombies"),"zombie_01").state == 3 and SaveCatalog.find(main.get_node("Zombies"),"zombie_01").collision_layer == 0,
		"Restaurar no reproduce sonidos": main.get_node("Audio").ui.played_counts.is_empty() and main.get_node("Audio").combat.played_counts.is_empty(),
		"Interfaces cerradas": not main.get_node("InventoryUI").window.visible and not main.get_node("RadioUI").window.visible and not main.get_node("PauseUI").window.visible,
		"Partida viva": not main.game_ended and not main.get_node("HUD").game_over.visible}
