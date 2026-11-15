extends Node
## Música global: una voz, dos partituras. Nunca controla estado de gameplay.
const PATHS := {"menu":"res://assets/music/menu_last_frequency.wav", "gameplay":"res://assets/music/gameplay_streets.wav"}
const LEVELS := {"menu":-14.0, "gameplay":-20.0}
const FADE_SECONDS := 0.65
var player: AudioStreamPlayer
var context := ""
var requested := ""
var envelope_db := -60.0
var duck_db := 0.0
var duck_target := 0.0
var starts := 0
var _owner: WeakRef
var _streams: Dictionary = {}
var _fade: Tween
var _duck: Tween

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	player = AudioStreamPlayer.new()
	player.name = "Music"
	player.bus = &"Music"
	add_child(player)
	for key: String in PATHS:
		var stream := load(PATHS[key]).duplicate() as AudioStream
		if stream is AudioStreamWAV:
			stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			stream.loop_begin = 0
			stream.loop_end = roundi(stream.get_length() * stream.mix_rate)
		elif stream is AudioStreamOggVorbis:
			stream.loop = true
		_streams[key] = stream

func enter_menu(owner: Node) -> void:
	_enter("menu", owner)

func enter_gameplay(owner: Node) -> void:
	_enter("gameplay", owner)

func _enter(target: String, owner: Node) -> void:
	_owner = weakref(owner)
	var pause_ui := owner.get_node_or_null("PauseUI")
	var radio_ui := owner.get_node_or_null("RadioUI")
	set_mix(owner, pause_ui != null and pause_ui.window.visible, radio_ui != null and radio_ui.window.visible)
	if requested == target: return
	requested = target
	if is_instance_valid(_fade): _fade.kill()
	_fade = create_tween()
	if not context.is_empty() and context != target:
		_fade.tween_property(self, "envelope_db", -60.0, FADE_SECONDS)
		_fade.tween_callback(_start.bind(target))
	elif context.is_empty():
		_start(target)
	_fade.tween_property(self, "envelope_db", 0.0, FADE_SECONDS)

func _start(target: String) -> void:
	player.stop()
	context = target
	player.stream = _streams[target]
	envelope_db = -60.0
	_apply_volume()
	starts += 1
	# Igual que SoundEmitter: Dummy valida estado, la prueba nativa valida señal.
	if DisplayServer.get_name() != "headless": player.play()

func set_mix(owner: Node, paused: bool, radio: bool) -> void:
	if _owner == null or _owner.get_ref() != owner: return
	var target := -12.0 if radio else (-6.0 if paused else 0.0)
	if target == duck_target: return
	duck_target = target
	if is_instance_valid(_duck): _duck.kill()
	_duck = create_tween()
	_duck.tween_property(self, "duck_db", target, 0.25)

func _process(_delta: float) -> void:
	_apply_volume()

func _apply_volume() -> void:
	if is_instance_valid(player): player.volume_db = LEVELS.get(context, -20.0) + envelope_db + duck_db

func _exit_tree() -> void:
	if is_instance_valid(_fade): _fade.kill()
	if is_instance_valid(_duck): _duck.kill()
	if is_instance_valid(player):
		player.stop()
		player.stream = null
	_streams.clear()
