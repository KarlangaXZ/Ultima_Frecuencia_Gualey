extends Node
## Mantiene un único Player y una sola zona física. Los mapas inactivos son datos.
signal transition_started(destination: String)
signal transition_finished(success: bool)
signal zone_changed(id: String)
var current_zone := "gualey_sector_04"
var unlocked: Array[String] = []
var states: Dictionary = {}
var busy := false
@onready var main: Node = get_parent()
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	main.get_node("Missions").mission_completed.connect(_on_mission)
	sync_exits()
	if not main.restoring: main.get_node("ZoneOverlay").call_deferred("show_location", active_definition().display_name)
func active_definition() -> ZoneDefinition:
	return ZoneCatalog.definition(current_zone)
func _on_mission(mission: MissionDefinition) -> void:
	for id in ZoneCatalog.DEFINITIONS:
		if ZoneCatalog.definition(id).unlock_mission == mission.id and id not in unlocked:
			unlocked.append(id)
	sync_exits()
func sync_exits() -> void:
	for point in main.get_node("World/ChapterPoints").get_children():
		if point is ZoneExit:
			point.available = point.destination == ZoneCatalog.HOME or point.destination in unlocked
			point.destination_label = ZoneCatalog.definition(point.destination).display_name
func request_travel(destination: String, entry: String) -> bool:
	if busy or main.restoring or main.game_ended or main.get_node("Player").controls_blocked: return false
	var zone := ZoneCatalog.definition(destination)
	if zone == null or destination == current_zone or not zone.entries.has(entry): return false
	if destination != ZoneCatalog.HOME and destination not in unlocked: return false
	var point: Vector2 = zone.entries[entry]
	if not ZoneCatalog.point_free(destination,[point.x,point.y]): return false
	if not main.get_node("Population")._initialized: return false
	busy = true
	main.get_node("InterfaceCoordinator").set_transitioning(true)
	transition_started.emit(destination)
	call_deferred("_travel",destination,entry)
	return true
func _travel(destination: String, entry: String) -> void:
	var overlay: Node = main.get_node("ZoneOverlay")
	var zone := ZoneCatalog.definition(destination)
	await overlay.fade_out(zone.display_name)
	states[current_zone] = WorldSaveState.capture(main)
	var global_kills: int = main.kills
	var global_time: float = main.survival_time
	install_world(destination)
	main.get_node("Player").position = zone.entries[entry]
	main.get_node("Player").velocity = Vector2.ZERO
	if states.has(destination):
		WorldSaveState.restore(main,states[destination])
		states.erase(destination)
	else:
		_create_initial_enemies()
		main.get_node("Population").start()
	main.kills = global_kills
	main.survival_time = global_time
	main.get_node("HUD").update_stats(global_kills,global_time)
	var camera: Camera2D = main.get_node("Player/Camera2D")
	camera.reset_smoothing()
	camera.force_update_scroll()
	main.get_node("World/Navigation").enabled = true
	NavigationServer2D.map_force_update(main.get_node("Player").get_world_2d().navigation_map)
	# Inicializar solo población con delta cero: el gameplay continúa congelado.
	main.get_node("Population")._physics_process(0.0)
	main.get_node("Population")._physics_process(0.0)
	main.get_node("Player/Interaction").target = null
	main.get_node("HUD").update_interaction("")
	zone_changed.emit(current_zone)
	await overlay.fade_in(zone.display_name)
	busy = false
	main.get_node("InterfaceCoordinator").set_transitioning(false)
	transition_finished.emit(true)
func install_world(id: String) -> void:
	var old: Node = main.get_node("World")
	old.get_node("Navigation").enabled = false
	main.remove_child(old)
	old.queue_free()
	for zombie in main.get_node("Zombies").get_children():
		zombie.get_parent().remove_child(zombie)
		zombie.queue_free()
	current_zone = id
	var zone := active_definition()
	var world := zone.world_scene.instantiate()
	world.name = "World"
	world.get_node("Navigation").enabled = false
	main.add_child(world)
	# Conservar el orden original: suelo/props antes de Player y Zombies.
	main.move_child(world,0)
	main.get_node("Population").configure_zone(zone)
	main.get_node("Player/Camera2D").limit_right = int(zone.dimensions.x)
	main.get_node("Player/Camera2D").limit_bottom = int(zone.dimensions.y)
	main.get_node("Player/ProgressionRewards")._zombies.clear()
	main.get_node("Player/ProgressionRewards")._containers.clear()
	main.get_node("InventoryUI").container = null
	main.get_node("Missions/Chapter").bind_points()
	sync_exits()
func _create_initial_enemies() -> void:
	var zone := active_definition()
	for index in range(zone.initial_enemies.size()):
		var zombie: Node = load("res://scenes/enemies/Zombie.tscn").instantiate()
		zombie.archetype = zone.archetype_for(index + 1)
		zombie.name = ["ZombieA","ZombieB","ZombieC"][index]
		zombie.set_meta("persistence_id",zone.enemy_prefix + "%02d" % (index + 1))
		zombie.position = zone.initial_enemies[index]
		main.get_node("Zombies").add_child(zombie)
		main._register_zombie(zombie)
func restore_session(id: String, inactive: Dictionary, unlocked_ids: Array) -> void:
	states = inactive.duplicate(true)
	unlocked.assign(unlocked_ids)
	if current_zone != id: install_world(id)
	sync_exits()
