extends RefCounted
## Prepara una partida rica en estado. Daño/XP extra solo pertenecen a esta fixture.
static func frames(tree: SceneTree, count: int = 2) -> void:
	for index in range(count):
		await tree.physics_frame
		await tree.process_frame
static func close_windows(main: Node) -> void:
	for name in ["InventoryUI", "CharacterUI", "MissionUI", "RadioUI", "PauseUI"]: main.get_node(name).close_window()
static func interact_at(tree: SceneTree, main: Node, point: Vector2) -> void:
	close_windows(main)
	main.get_node("Player").position = point
	await frames(tree)
	main.get_node("Player/Interaction").try_interact()
static func slot_of(inventory: InventoryComponent, id: StringName) -> int:
	for index in range(inventory.capacity):
		var slot := inventory.get_slot(index)
		if not slot.is_empty() and slot.item.id == id: return index
	return -1
static func build(tree: SceneTree, main: Node) -> void:
	# Solo la preparación congela el árbol de esta escena; la restauración prueba IA activa.
	main.set_process(false)
	main.get_node("Player").set_physics_process(false)
	main.get_node("Player/SurvivalComponent").set_physics_process(false)
	main.get_node("Population").set_physics_process(false)
	for enemy in main.get_node("Zombies").get_children(): enemy.set_physics_process(false)
	var player: Node = main.get_node("Player")
	var interaction: Node = player.get_node("Interaction")
	var inventory: InventoryComponent = player.get_node("InventoryComponent")
	main.get_node("Zombies/ZombieA/HealthComponent").take_damage(50)
	main.get_node("Zombies/ZombieB/HealthComponent").take_damage(50)
	await interact_at(tree, main, Vector2(560,810))
	await interact_at(tree, main, Vector2(650,880))
	await interact_at(tree, main, Vector2(600,680))
	await interact_at(tree, main, Vector2(1720,630))
	for entry in [["revolver_case", "weapon_revolver", "revolver_ammo"], ["shotgun_case", "weapon_shotgun", "shotgun_ammo"]]:
		var container: Node = SaveCatalog.find(main.get_node("World"), entry[0])
		await interact_at(tree, main, container.position + Vector2(0,35))
		interaction.transfer_from_container(container, 0)
		player.get_node("ItemUse").use_slot(slot_of(inventory, StringName(entry[1])))
		interaction.transfer_from_container(container, 1)
		player.get_node("ItemUse").use_slot(slot_of(inventory, StringName(entry[2])))
	await interact_at(tree, main, Vector2(770,685))
	interaction.transfer_from_container(SaveCatalog.find(main.get_node("World"), "medical_case"), 0)
	await interact_at(tree, main, Vector2(1320,725))
	interaction.transfer_from_container(SaveCatalog.find(main.get_node("World"), "supply_crate"), 1)
	close_windows(main)
	main.get_node("Population")._physics_process(10.1)
	SaveCatalog.find(main.get_node("Zombies"), "zombie_04").health.take_damage(50)
	main.get_node("Population")._physics_process(3.25)
	for enemy in main.get_node("Zombies").get_children(): enemy.set_physics_process(false)
	var progression: ProgressionComponent = player.get_node("ProgressionComponent")
	progression.add_xp(760 - progression.total_xp())
	for id in SaveCatalog.SKILLS: player.get_node("SkillsComponent").upgrade(StringName(id))
	inventory.add_item(SaveCatalog.ITEMS.pistol_ammo, 18)
	var equipment: EquipmentComponent = player.get_node("Equipment")
	var pistol: Node = equipment.get_weapon(&"pistol")
	pistol.loaded = 7
	pistol.reserve = 31
	var revolver: Node = equipment.get_weapon(&"revolver")
	revolver.loaded = 3
	revolver.reserve = 9
	var shotgun: Node = equipment.get_weapon(&"shotgun")
	shotgun.loaded = 2
	shotgun.reserve = 6
	equipment.switch_to(&"shotgun")
	shotgun.cooldown = 0.4
	shotgun.start_reload()
	shotgun.reload_remaining = 0.7
	player.health.current_health = 43.5
	var survival: SurvivalComponent = player.get_node("SurvivalComponent")
	survival.hunger = 12.25
	survival.thirst = 0.0
	survival._penalty_time = 2.75
	player.position = Vector2(1200,1000)
	player.get_node("Visual").direction_name = "left"
	player.get_node("Aim").rotation = 0.5
	main.survival_time = 321.5
	main.get_node("SaveCoordinator")._refresh_presentation(main)
	player.get_node("Camera2D").reset_smoothing()
	player.get_node("Camera2D").force_update_scroll()
