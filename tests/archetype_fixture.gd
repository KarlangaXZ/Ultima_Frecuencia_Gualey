extends RefCounted
static func frames(tree: SceneTree, count: int = 2) -> void:
	for index in range(count):
		await tree.physics_frame
		await tree.process_frame
static func enter_market(tree: SceneTree, main: Node) -> void:
	var tracker: MissionTracker = main.get_node("Missions")
	main.get_node("Zombies/ZombieA/HealthComponent").take_damage(50)
	main.get_node("Zombies/ZombieB/HealthComponent").take_damage(50)
	for event in [&"inspect_radio",&"recovered_medkit",&"recovered_water",&"power_on",&"send_radio"]:
		tracker.record_event(event,"archetype_fixture")
	main.get_node("ZoneManager").request_travel(ZoneCatalog.MARKET,"from_gualey")
	await main.get_node("ZoneManager").transition_finished
	await frames(tree,3)
static func by_type(main: Node, id: String) -> Node:
	for enemy in main.get_node("Zombies").get_children():
		if String(enemy.archetype.id) == id: return enemy
	return null
static func states(main: Node) -> Dictionary:
	var result := {}
	for enemy in main.get_node("Zombies").get_children():
		result[SaveCatalog.id_of(enemy)] = [String(enemy.archetype.id),enemy.health.current_health,enemy.max_health]
	return result
static func counts(main: Node) -> Dictionary:
	var result := {"base":0,"runner":0,"resistant":0}
	for enemy in main.get_node("Zombies").get_children(): result[String(enemy.archetype.id)] += 1
	return result
