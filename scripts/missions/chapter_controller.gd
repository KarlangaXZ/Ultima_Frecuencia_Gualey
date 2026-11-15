extends Node
## Adaptador narrativo de ambos capítulos; observa resultados, nunca aplica daño.
signal equipment_activated
@onready var tracker: MissionTracker = get_parent()
@onready var main: Node = tracker.get_parent()
@onready var radio: Node = main.get_node("Radio")
@onready var points: Node = main.get_node("World/ChapterPoints")
const FIRST := preload("res://resources/radio/FirstSignal.tres")
const POWER := preload("res://resources/radio/PowerRestored.tres")
const FINAL := preload("res://resources/radio/FirstBroadcast.tres")
const MARKET_RECORD := preload("res://resources/radio/MarketRecord.tres")
const MARKET_COMMS := preload("res://resources/radio/MarketComms.tres")
const MARKET_POWER := preload("res://resources/radio/MarketPower.tres")
const MARKET_FINAL := preload("res://resources/radio/MarketFinal.tres")
const STATION_INTRO := preload("res://resources/radio/StationIntro.tres")
var _observation_time := 0.0

func bind() -> void:
	main.get_node("Player/Interaction").supply_recovered.connect(_on_recovered)
	main.get_node("Player/Interaction").container_opened.connect(_on_container)
	main.get_node("ZoneManager").zone_changed.connect(_on_zone)
	radio.transmission_completed.connect(_on_transmission_completed)
	tracker.mission_completed.connect(_on_completed)
	for zombie in main.get_node("Zombies").get_children():
		_observe_zombie(zombie)
	main.zombie_added.connect(_observe_zombie)
	bind_points()
	tracker.changed.connect(_update_points)
	main.get_node("Player/HealthComponent").died.connect(tracker.stop)
	main.get_node("Player/HealthComponent").died.connect(radio.stop)
	_update_points()

func _observe_zombie(zombie: CharacterBody2D) -> void:
	zombie.eliminated.connect(_on_kill.bind(zombie))

func _on_kill(zombie: CharacterBody2D) -> void:
	tracker.observe_total(&"kills", main.kills)
	if main.get_node("ZoneManager").current_zone != ZoneCatalog.MARKET: return
	var id := String(zombie.archetype.id)
	if id in ["runner","resistant"]:
		tracker.record_event(StringName("market_"+id+"_kills"),SaveCatalog.id_of(zombie))
		if id == "runner": tracker.record_event(&"market_runner_seen","market_presence")

func _on_recovered(item: ItemDefinition, receipt: String) -> void:
	if item.id == &"medkit" or item.id == &"water":
		tracker.record_event(StringName("recovered_" + String(item.id)), receipt)
		if main.get_node("ZoneManager").current_zone == ZoneCatalog.MARKET:
			tracker.record_event(StringName("market_"+String(item.id)),receipt)

func _on_container(container: LootContainer) -> void:
	if main.get_node("ZoneManager").current_zone == ZoneCatalog.MARKET and SaveCatalog.id_of(container)=="market_medical":
		tracker.record_event(&"market_container","market_medical")

func _on_zone(id: String) -> void:
	if not main.restoring and id == ZoneCatalog.MARKET:
		tracker.begin_chapter(ChapterCatalog.MARKET)
	_update_points()

func _on_completed(mission: MissionDefinition) -> void:
	if mission.id == &"market_frequency":
		main.get_node("HUD").show_message("Capítulo 2 completado · Salida a la Estación habilitada")

func _physics_process(delta: float) -> void:
	if not tracker.enabled or main.restoring or int(tracker._totals.get(&"market_runner_seen",0))>0: return
	if main.get_node("ZoneManager").current_zone != ZoneCatalog.MARKET: return
	_observation_time -= delta
	if _observation_time > 0: return
	_observation_time = 0.25
	for zombie in main.get_node("Population").active_enemies():
		if zombie.archetype.id == &"runner" and zombie.state in [1,2]:
			tracker.record_event(&"market_runner_seen","market_presence")
			break

func _on_transmission_completed(value: RadioTransmission) -> void:
	if value == MARKET_FINAL and tracker.accepts(&"market_listen"):
		tracker.record_event(&"market_listen","market_final")
	_update_points()

func _update_points() -> void:
	var receiver := points.get_node_or_null("Radio")
	var generator := points.get_node_or_null("Generator")
	if receiver != null: receiver.available = tracker.accepts(&"inspect_radio") or tracker.accepts(&"send_radio")
	if generator != null: generator.available = tracker.accepts(&"power_on")
	for point in points.get_children():
		if point is MissionPoint and point.point_id==&"station_radio":
			point.available = "station_radio" not in main.get_node("ZoneManager").interactions or radio.transmission==STATION_INTRO
		if point is MissionPoint and String(point.point_id) in ChapterCatalog.POINT_EVENTS:
			point.available = tracker.accepts(StringName(ChapterCatalog.POINT_EVENTS[String(point.point_id)]))
			if point.point_id == &"market_repeater": point.available = point.available or tracker.accepts(&"market_listen")

func bind_points() -> void:
	points = main.get_node("World/ChapterPoints")
	for point in points.get_children():
		if point is MissionPoint and not point.activated.is_connected(_on_point): point.activated.connect(_on_point)
	_update_points()

func _on_point(point: MissionPoint) -> void:
	if not tracker.enabled or main.game_ended: return
	if point.point_id==&"station_radio" and main.get_node("ZoneManager").current_zone==ZoneCatalog.STATION:
		var manager:=main.get_node("ZoneManager")
		if "station_radio" not in manager.interactions:
			manager.interactions.append("station_radio") # Reservar antes de emitir mensaje.
			radio.play(STATION_INTRO)
		elif radio.transmission==STATION_INTRO: radio._emit_message()
		_update_points()
		return
	if String(point.point_id) in ChapterCatalog.POINT_EVENTS:
		var event := StringName(ChapterCatalog.POINT_EVENTS[String(point.point_id)])
		if tracker.accepts(event):
			tracker.record_event(event,String(point.point_id))
			match point.point_id:
				&"market_record": radio.play(MARKET_RECORD)
				&"market_comms": radio.play(MARKET_COMMS)
				&"market_power":
					equipment_activated.emit()
					radio.play(MARKET_POWER)
				&"market_repeater":
					equipment_activated.emit()
					radio.play(MARKET_FINAL)
		elif point.point_id == &"market_repeater" and tracker.accepts(&"market_listen"):
			if radio.transmission == MARKET_FINAL: radio._emit_message()
			else: radio.play(MARKET_FINAL)
		return
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
