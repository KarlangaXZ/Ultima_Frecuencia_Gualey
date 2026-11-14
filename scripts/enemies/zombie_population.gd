extends Node
## Único propietario de apariciones adicionales. Incluye los tres actores originales.
signal spawned(zombie: CharacterBody2D)
@export_range(1, 10) var active_limit: int = 6
@export_range(1, 20) var total_budget: int = 18
@export_range(1, 60) var replacement_interval: float = 10.0
@export var minimum_player_distance: float = 320.0
@export var screen_margin: float = 96.0
@export var spawn_points := PackedVector2Array([
	Vector2(1600,450), Vector2(1960,700), Vector2(1800,1250),
	Vector2(1320,1210), Vector2(650,1250), Vector2(320,950),
	Vector2(950,370), Vector2(1500,750), Vector2(1900,560),
	Vector2(2100,850), Vector2(1000,1050), Vector2(1200,350),
	Vector2(550,350), Vector2(350,900), Vector2(1500,1150)])
const ZOMBIE := preload("res://scenes/enemies/Zombie.tscn")
@onready var main: Node = get_parent()
@onready var actor: CharacterBody2D = main.get_node("Player")
@onready var actors: Node2D = main.get_node("Zombies")
var total_spawned := 0
var running := false
var _started := false
var _initialized := false
var _remaining := 0.0
var _cursor := 0
var _living: Dictionary = {}

func start() -> void:
	if _started: return
	_started = true
	running = not actor.health.is_dead()
	actor.health.died.connect(stop)
	for zombie in actors.get_children():
		total_spawned += 1
		if not zombie.health.is_dead(): _track(zombie)
	total_budget = maxi(total_budget, total_spawned)
	_remaining = replacement_interval

func stop() -> void:
	running = false

func active_enemies() -> Array[Node]:
	var result: Array[Node] = []
	for zombie in _living.values():
		if is_instance_valid(zombie) and not zombie.health.is_dead(): result.append(zombie)
	return result

func _track(zombie: Node) -> void:
	var id := zombie.get_instance_id()
	_living[id] = zombie
	zombie.eliminated.connect(func(): _living.erase(id))
	zombie.tree_exiting.connect(func(): _living.erase(id))

func is_valid_spawn(point: Vector2) -> bool:
	if actor.global_position.distance_to(point) < minimum_player_distance: return false
	var on_screen := actors.get_canvas_transform() * point
	if get_viewport().get_visible_rect().grow(screen_margin).has_point(on_screen): return false
	var navigation_map := actor.get_world_2d().navigation_map
	if NavigationServer2D.map_get_iteration_id(navigation_map) == 0: return false
	if NavigationServer2D.map_get_closest_point(navigation_map, point).distance_to(point) > 2: return false
	var path := NavigationServer2D.map_get_path(navigation_map, point, actor.global_position, true)
	if path.is_empty() or path[-1].distance_to(actor.global_position) > 30: return false
	var shape := CircleShape2D.new()
	shape.radius = 26
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0, point)
	query.collision_mask = 7
	if not actor.get_world_2d().direct_space_state.intersect_shape(query).is_empty(): return false
	for zombie in active_enemies():
		if zombie.global_position.distance_to(point) < 96: return false
	for important in main.get_node("World/ChapterPoints").get_children():
		if important.global_position.distance_to(point) < 96: return false
	return true

func _spawn_one() -> bool:
	if not running or actor.health.is_dead() or active_enemies().size() >= active_limit or total_spawned >= total_budget: return false
	for offset in range(spawn_points.size()):
		var index := (_cursor + offset) % spawn_points.size()
		var point := spawn_points[index]
		if not is_valid_spawn(point): continue
		# Reservar presupuesto antes de notificar o añadir el actor al árbol.
		total_spawned += 1
		_cursor = (index + 1) % spawn_points.size()
		var zombie := ZOMBIE.instantiate() as CharacterBody2D
		zombie.name = "PopulationZombie%02d" % total_spawned
		zombie.set_meta("persistence_id", "zombie_%02d" % total_spawned)
		zombie.position = actors.to_local(point)
		actors.add_child(zombie)
		_track(zombie)
		spawned.emit(zombie)
		return true
	return false

func restore_population(data: Dictionary) -> void:
	_started = true
	_initialized = true
	running = true
	total_spawned = int(data.spawned)
	_remaining = data.remaining
	_cursor = int(data.cursor)
	_living.clear()
	actor.health.died.connect(stop)
	for zombie in actors.get_children():
		if not zombie.health.is_dead(): _track(zombie)

func _physics_process(delta: float) -> void:
	if not running or actor.health.is_dead(): return
	if NavigationServer2D.map_get_iteration_id(actor.get_world_2d().navigation_map) == 0: return
	if not _initialized:
		while active_enemies().size() < mini(active_limit, total_budget):
			if not _spawn_one(): break
		_initialized = active_enemies().size() >= mini(active_limit, total_budget) or total_spawned >= total_budget
		return
	if active_enemies().size() >= active_limit:
		_remaining = replacement_interval
		return
	_remaining -= delta
	if _remaining <= 0:
		_spawn_one()
		_remaining = replacement_interval
