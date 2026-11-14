class_name SoundEmitter
extends Node2D
## Pool acotado. Solo presentación: no modifica cooldowns ni estado de gameplay.
signal sound_played(id: StringName)
@export var bank: AudioCatalog = preload("res://resources/audio/TechnicalAudio.tres")
@export var enabled := true
@export var positional := false
@export_range(1, 12) var max_voices := 4
@export_range(-60, 0) var volume_db: float = -14.0
var played_counts: Dictionary = {}
var _players: Array[Node] = []
var _cooldowns: Dictionary = {}
var _next_voice := 0

func _ready() -> void:
	for index in range(max_voices):
		var player: Node = AudioStreamPlayer2D.new() if positional else AudioStreamPlayer.new()
		if positional:
			player.max_distance = 800.0
			player.attenuation = 1.5
		add_child(player)
		_players.append(player)

func _process(delta: float) -> void:
	for id in _cooldowns:
		_cooldowns[id] = maxf(0, _cooldowns[id] - delta)

func play_event(id: StringName, minimum_interval: float = 0.0) -> bool:
	if not enabled or not bank.sounds.has(id) or _cooldowns.get(id, 0.0) > 0.00001: return false
	var player: Node = _players[_next_voice]
	_next_voice = (_next_voice + 1) % _players.size()
	player.stop()
	player.stream = bank.sounds[id]
	player.volume_db = volume_db
	# El driver Dummy de pruebas headless no drena voces al cerrar inmediatamente.
	# Allí se verifican eventos; la mezcla real se comprueba en ejecución gráfica.
	if DisplayServer.get_name() != "headless": player.play()
	_cooldowns[id] = maxf(0, minimum_interval)
	played_counts[id] = played_counts.get(id, 0) + 1
	sound_played.emit(id)
	return true

func stop_all() -> void:
	for player in _players: player.stop()

func _exit_tree() -> void:
	for player in _players:
		player.stop()
		player.stream = null

func set_volume(value: float) -> void:
	volume_db = clampf(value, -60, 0)
	for player in _players: player.volume_db = volume_db
