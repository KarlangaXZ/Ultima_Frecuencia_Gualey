extends Node
## Adaptador de La señal perdida. No conserva copias de bajas ni inventario.
@onready var tracker: MissionTracker = get_parent()
@onready var main: Node = tracker.get_parent()
@onready var radio: Node = main.get_node("Radio")
@onready var points: Node = main.get_node("World/ChapterPoints")
const FIRST := preload("res://resources/radio/FirstSignal.tres")
const POWER := preload("res://resources/radio/PowerRestored.tres")
const FINAL := preload("res://resources/radio/FirstBroadcast.tres")

func bind() -> void:
	main.get_node("Player/Interaction").supply_recovered.connect(_on_recovered)
	for zombie in main.get_node("Zombies").get_children():
		_observe_zombie(zombie)
	main.zombie_added.connect(_observe_zombie)
	for point in points.get_children(): point.activated.connect(_on_point)
	tracker.changed.connect(_update_points)
	main.get_node("Player/HealthComponent").died.connect(tracker.stop)
	main.get_node("Player/HealthComponent").died.connect(radio.stop)
	_update_points()

func _observe_zombie(zombie: CharacterBody2D) -> void:
	zombie.eliminated.connect(_on_kill)

func _on_kill() -> void:
	tracker.observe_total(&"kills", main.kills)

func _on_recovered(item: ItemDefinition, receipt: String) -> void:
	if item.id == &"medkit" or item.id == &"water":
		tracker.record_event(StringName("recovered_" + String(item.id)), receipt)

func _update_points() -> void:
	points.get_node("Radio").available = tracker.accepts(&"inspect_radio") or tracker.accepts(&"send_radio")
	points.get_node("Generator").available = tracker.accepts(&"power_on")

func _on_point(point: MissionPoint) -> void:
	if not tracker.enabled or main.game_ended: return
	if point.point_id == &"radio":
		if tracker.accepts(&"inspect_radio"):
			tracker.record_event(&"inspect_radio", "chapter_radio")
			radio.play(FIRST)
		elif tracker.accepts(&"send_radio"):
			tracker.record_event(&"send_radio", "chapter_broadcast")
			radio.play(FINAL)
	elif point.point_id == &"generator" and tracker.accepts(&"power_on"):
		tracker.record_event(&"power_on", "chapter_generator")
		radio.play(POWER)
