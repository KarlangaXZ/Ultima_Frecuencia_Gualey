extends ChapterWindow
var saves: Node
var status: Label
var confirm_button: Button
var rows: Array[Dictionary] = []
var pending_slot := -1

func _setup(title: Label) -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	title.text = "PAUSA · PARTIDAS"
	content.add_theme_constant_override("separation", 10)
	close_button.text = "CONTINUAR"
	saves = get_parent().get_node("SaveCoordinator")
	var help := Label.new()
	help.text = "Tres ranuras manuales · El mundo se detiene mientras este menú está abierto."
	help.add_theme_font_size_override("font_size", 15)
	content.add_child(help)
	for slot in range(1, 4):
		var row := HBoxContainer.new()
		row.custom_minimum_size.y = 78
		row.add_theme_constant_override("separation", 12)
		var summary := Label.new()
		summary.custom_minimum_size.x = 540
		summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		summary.add_theme_font_size_override("font_size", 16)
		row.add_child(summary)
		var save := Button.new()
		save.text = "GUARDAR"
		save.custom_minimum_size.x = 140
		save.add_theme_font_size_override("font_size", 16)
		save.pressed.connect(_save.bind(slot))
		row.add_child(save)
		var restore := Button.new()
		restore.text = "CARGAR"
		restore.custom_minimum_size.x = 120
		restore.add_theme_font_size_override("font_size", 16)
		restore.pressed.connect(_load.bind(slot))
		row.add_child(restore)
		content.add_child(row)
		rows.append({"label": summary, "save": save, "load": restore})
	status = Label.new()
	status.custom_minimum_size = Vector2(860, 36)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.add_theme_font_size_override("font_size", 15)
	status.add_theme_color_override("font_color", Color("dec787"))
	content.add_child(status)
	confirm_button = Button.new()
	confirm_button.text = "CONFIRMAR REEMPLAZO"
	confirm_button.hide()
	confirm_button.pressed.connect(_confirm)
	content.add_child(confirm_button)
	var policy := Label.new()
	policy.text = "ESC: continuar · Cargar cancela la recarga en curso sin transferir munición."
	policy.add_theme_font_size_override("font_size", 13)
	content.add_child(policy)

func _input(event: InputEvent) -> void:
	if get_parent().get_node("ZoneManager").busy: return
	if not event.is_action_pressed("ui_cancel"): return
	if window.visible: close_window()
	else:
		for name in ["InventoryUI", "CharacterUI", "MissionUI", "RadioUI"]:
			if get_parent().get_node(name).window.visible: return
		open_panel()
	get_viewport().set_input_as_handled()

func open_panel() -> void:
	status.text = ""
	pending_slot = -1
	confirm_button.hide()
	refresh_slots()
	super.open_panel()

func close_window() -> void:
	pending_slot = -1
	if is_instance_valid(confirm_button): confirm_button.hide()
	super.close_window()

func on_player_died() -> void:
	# Permite cargar desde Game Over; guardar sigue rechazado por el coordinador.
	close_window()

func refresh_slots() -> void:
	for index in range(3):
		var result: Dictionary = saves.store.read_slot(index + 1)
		var label := "Ranura %d · Vacía" % (index + 1)
		if result.has("data"):
			label = "Ranura %d · Nivel %d · La señal perdida\n%s · %s UTC%s" % [index + 1, result.data.player.progression.level,
				ZoneCatalog.definition(result.data.map).display_name, String(result.data.saved_at).replace("T", " ").trim_suffix("Z"), " · Respaldo" if result.recovered else ""]
		elif saves.store.occupied(index + 1): label = "Ranura %d · %s" % [index + 1, result.error]
		rows[index].label.text = label
		rows[index].save.disabled = get_parent().game_ended
		rows[index].load.disabled = not saves.store.occupied(index + 1)

func _save(slot: int) -> void:
	var result: Dictionary = saves.save_slot(slot)
	if result.get("confirmation_required", false):
		pending_slot = slot
		status.text = "La ranura %d está ocupada. Confirma para reemplazarla; se conservará un respaldo." % slot
		confirm_button.show()
	else:
		pending_slot = -1
		confirm_button.hide()
		status.text = "Partida guardada en ranura %d." % slot if result.has("ok") else result.error
	refresh_slots()

func _confirm() -> void:
	if pending_slot < 1: return
	var result: Dictionary = saves.save_slot(pending_slot, true)
	status.text = "Partida guardada." if result.has("ok") else result.error
	pending_slot = -1
	confirm_button.hide()
	refresh_slots()

func _load(slot: int) -> void:
	var result: Dictionary = saves.load_slot(slot)
	if result.has("error"): status.text = result.error
