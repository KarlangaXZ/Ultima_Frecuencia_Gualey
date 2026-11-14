extends ChapterWindow
var tracker: MissionTracker
var body: RichTextLabel
const STATES := ["BLOQUEADA", "DISPONIBLE", "ACTIVA", "COMPLETADA"]

func _setup(title: Label) -> void:
	title.text = "MISIONES"
	tracker = get_parent().get_node("Missions")
	var chapter := Label.new()
	chapter.text = "CAPÍTULO 1 · LA SEÑAL PERDIDA"
	chapter.add_theme_font_size_override("font_size", 16)
	content.add_child(chapter)
	body = RichTextLabel.new()
	body.custom_minimum_size = Vector2(900, 360)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_font_size_override("normal_font_size", 16)
	content.add_child(body)
	var policy := Label.new()
	policy.text = "J / ESC: cerrar · El mundo sigue activo · Progreso solo durante esta partida."
	policy.add_theme_font_size_override("font_size", 13)
	content.add_child(policy)
	tracker.changed.connect(refresh)
	refresh()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("missions") and _alive:
		if window.visible: close_window()
		else: open_panel()
		get_viewport().set_input_as_handled()
	else: super._input(event)

func refresh() -> void:
	var text := ""
	var history := PackedStringArray()
	for mission in tracker.definitions:
		var state := tracker.state_of(mission.id)
		if state == MissionTracker.State.COMPLETED:
			history.append("✓ %s · %d XP" % [mission.title, mission.reward_xp])
			continue
		text += "%s · %s · %d XP\n%s\n" % [STATES[state], mission.title, mission.reward_xp, mission.description]
		for index in range(mission.objectives.size()):
			var objective := mission.objectives[index]
			text += "  %s  %d / %d\n" % [objective.description, tracker.progress_of(mission.id, index), objective.target]
		text += "\n"
	if tracker.active_mission() == null and history.size() == tracker.definitions.size():
		text = "CAPÍTULO COMPLETADO\nLa primera transmisión está en el aire. Puedes seguir explorando.\nEl siguiente capítulo está pendiente.\n\n"
	body.text = text + "HISTORIAL\n" + ("Sin misiones completadas." if history.is_empty() else "\n".join(history))
