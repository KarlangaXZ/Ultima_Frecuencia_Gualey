extends Node
## Observador de eventos reales. Sin autoload, consultas físicas ni efectos de juego.
@export_range(-60, 0) var ui_volume_db: float = -18.0
@export_range(-60, 0) var combat_volume_db: float = -12.0
@export_range(-60, 0) var ambience_volume_db: float = -30.0
@export var ambience_enabled := true
var ui: SoundEmitter
var combat: SoundEmitter
var ambience: AudioStreamPlayer
var _inventory_open := false
var ambience_paused := false
@onready var main: Node = get_parent()
@onready var actor: Node = main.get_node("Player")

func _ready() -> void:
	ui = _make_emitter("UI", ui_volume_db, 4)
	combat = _make_emitter("Combat", combat_volume_db, 4)
	var inventory_ui := main.get_node("InventoryUI")
	inventory_ui.opened_changed.connect(_on_inventory_changed)
	inventory_ui.selection_changed.connect(func(): ui.play_event(&"ui_select"))
	main.get_node("CharacterUI").opened_changed.connect(func(active: bool):
		ui.play_event(&"inventory_open" if active else &"inventory_close"))
	actor.get_node("ProgressionComponent").leveled_up.connect(func(_level: int, _points: int): ui.play_event(&"pickup_supply"))
	actor.get_node("SkillsComponent").skill_acquired.connect(func(_id: StringName, _rank: int): ui.play_event(&"item_use"))
	main.get_node("MissionUI").opened_changed.connect(func(active: bool):
		ui.play_event(&"inventory_open" if active else &"inventory_close"))
	# Un aviso electrónico existente por mensaje; sin voz ni doble sonido al abrir.
	main.get_node("Radio").message_changed.connect(func(_sender: String, _message: String, _index: int, _total: int): ui.play_event(&"ui_select"))
	actor.get_node("Interaction").item_collected.connect(_on_collected)
	actor.get_node("Interaction").action_rejected.connect(_on_rejected)
	actor.get_node("ItemUse").item_used.connect(func(_item: ItemDefinition): ui.play_event(&"item_use"))
	actor.get_node("ItemUse").action_rejected.connect(_on_rejected)
	actor.get_node("Equipment").attack_performed.connect(_on_attack)
	actor.get_node("Equipment").reload_changed.connect(_on_reload)
	actor.get_node("Equipment").empty_triggered.connect(_on_empty)
	ambience = AudioStreamPlayer.new()
	ambience.name = "Ambience"
	var stream := ui.bank.sounds[&"ambience"].duplicate() as AudioStream
	if stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = int(stream.get_length() * stream.mix_rate)
	elif stream is AudioStreamOggVorbis or stream is AudioStreamMP3:
		stream.loop = true
	ambience.stream = stream
	ambience.volume_db = ambience_volume_db
	add_child(ambience)
	if ambience_enabled and not main.restoring and DisplayServer.get_name() != "headless": ambience.play()

func _make_emitter(label: String, gain: float, voices: int) -> SoundEmitter:
	var emitter := SoundEmitter.new()
	emitter.name = label
	emitter.volume_db = gain
	emitter.max_voices = voices
	add_child(emitter)
	return emitter

func _on_inventory_changed(active: bool) -> void:
	if active == _inventory_open: return
	_inventory_open = active
	if not active:
		ui.play_event(&"inventory_close")
	else:
		var inventory_ui := main.get_node("InventoryUI")
		ui.play_event(&"container_open" if is_instance_valid(inventory_ui.container) else &"inventory_open")

func _on_collected(item: ItemDefinition) -> void:
	ui.play_event(&"pickup_ammo" if item.effect == "ammo" else &"pickup_supply")

func _on_rejected() -> void:
	ui.play_event(&"invalid", 0.2)

func _combat_allowed() -> bool:
	return not actor.controls_blocked and not actor.health.is_dead()

func _on_attack(config: WeaponConfig, _origin: Vector2, _direction: Vector2, _damage: float, _range: float) -> void:
	if not _combat_allowed(): return
	if config.weapon_type == "melee":
		combat.play_event(&"machete_swing")
		if actor.get_node("MeleeCombat").hit_count > 0: combat.play_event(&"machete_hit")
	else:
		combat.play_event(StringName(String(config.id) + "_shot"))

func _on_reload(active: bool) -> void:
	if active and _combat_allowed(): combat.play_event(&"reload")

func _on_empty() -> void:
	if _combat_allowed(): combat.play_event(&"dry_fire", 0.3)

func set_ambience_paused(active: bool) -> void:
	ambience_paused = active
	ambience.stream_paused = active

func set_ambience_volume(value: float) -> void:
	ambience_volume_db = clampf(value, -60, 0)
	ambience.volume_db = ambience_volume_db

func _exit_tree() -> void:
	if is_instance_valid(ambience):
		ambience.stop()
		ambience.stream = null
