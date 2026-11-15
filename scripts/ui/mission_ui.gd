extends ChapterWindow
var tracker: MissionTracker
var body: RichTextLabel
var chapter: Label
const STATES := ["BLOQUEADA", "DISPONIBLE", "ACTIVA", "COMPLETADA"]

func _setup(title: Label) -> void:
	title.text = "MISIONES"
	tracker = get_parent().get_node("Missions")
	chapter = Label.new()
	chapter.text = "CAPÍTULO 1 · LA SEÑAL PERDIDA"
	chapter.add_theme_font_size_override("font_size", 16)
	content.add_child(chapter)
	body = RichTextLabel.new()
	body.custom_minimum_size = Vector2(900, 360)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_font_size_override("normal_font_size", 16)
	content.add_child(body)
	var policy := Label.new()
	policy.text = "J / ESC: cerrar · El mundo sigue activo · Esc → PARTIDAS para guardar."
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
	chapter.text = "CAPÍTULO %d · %s" % [ChapterCatalog.DEFINITIONS[tracker.active_chapter].number,ChapterCatalog.title(tracker.active_chapter).to_upper()]
	var text := ""
	var history := PackedStringArray()
	for id in tracker.completed_chapters():
		text += "CAPÍTULO COMPLETADO · %d: %s\n" % [ChapterCatalog.DEFINITIONS[id].number,ChapterCatalog.title(id)]
	if tracker.chapter_completed(ChapterCatalog.CONVOY):
		text += "Capítulo 4 completado. El convoy fue redirigido deliberadamente a NODO CERO. La identidad del mando sigue oculta. Puedes seguir explorando las cuatro zonas; aún no existe acceso a esa instalación.\n"
	elif tracker.chapter_completed(ChapterCatalog.STATION):
		text += "Capítulo 3 completado. Acceso al Perímetro de evacuación habilitado en la salida norte de la Estación. Investiga El último convoy; puedes explorar las cuatro zonas.\n"
	elif tracker.chapter_completed(ChapterCatalog.MARKET):
		text += "Capítulo 2 completado. Salida a la Estación de comunicaciones habilitada en el Mercado. Puedes regresar a Gualey.\n"
	elif tracker.chapter_completed(ChapterCatalog.FIRST) and ChapterCatalog.MARKET not in tracker.started_chapters:
		text += "Viaja al Mercado abandonado para iniciar Ecos del Mercado.\n"
	if not tracker.legacy_waivers.is_empty():
		var names := tracker.legacy_waivers.map(func(id):return "corredores" if id=="runner" else "resistentes")
		text += "Compatibilidad: amenazas sin ejemplares disponibles reconocidas como despejadas en el guardado anterior (%s). No son bajas nuevas.\n" % ", ".join(names)
	text += "\n"
	for mission in tracker.definitions:
		var state := tracker.state_of(mission.id)
		if state == MissionTracker.State.COMPLETED:
			history.append("✓ %s · %d XP" % [mission.title, mission.reward_xp])
			continue
		text += "C%d · %s · %s · %d XP\n%s\n" % [ChapterCatalog.DEFINITIONS[String(mission.chapter_id)].number,STATES[state], mission.title, mission.reward_xp, mission.description]
		for index in range(mission.objectives.size()):
			var objective := mission.objectives[index]
			text += "  %s  %d / %d\n" % [objective.description, tracker.progress_of(mission.id, index), objective.target]
		text += "\n"
	body.text = text + "HISTORIAL\n" + ("Sin misiones completadas." if history.is_empty() else "\n".join(history))
