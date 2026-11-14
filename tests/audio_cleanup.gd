extends RefCounted
## Drenar voces nativas antes de quit en suites aceleradas, sin debilitar aserciones.
static func finish(tree: SceneTree) -> void:
	if DisplayServer.get_name() == "headless": return
	_silence(tree.root)
	# Esperar tiempo real: --fixed-fps acelera el reloj de create_timer.
	var deadline := Time.get_ticks_msec() + 80
	while Time.get_ticks_msec() < deadline:
		await tree.process_frame

static func _silence(node: Node) -> void:
	if node is SoundEmitter:
		node.enabled = false
		node.stop_all()
	if node is AudioStreamPlayer or node is AudioStreamPlayer2D:
		node.stop()
		node.stream = null
	for child in node.get_children(): _silence(child)
