extends CanvasLayer
signal opened_changed(active: bool)
@onready var window: Control = $Root
@onready var content: VBoxContainer = $Root/Center/Panel/Margin/Content
var actor: Node
var progression: ProgressionComponent
var skills: SkillsComponent
var _alive := true
var _rows: Dictionary = {}

func _ready() -> void:
	content.get_node("Header/Close").pressed.connect(close_window)

func bind_player(player: Node) -> void:
	actor = player
	progression = player.get_node("ProgressionComponent")
	skills = player.get_node("SkillsComponent")
	for skill in skills.definitions:
		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(580, 64)
		row.add_theme_constant_override("separation", 12)
		var description := Label.new()
		description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		description.custom_minimum_size.x = 360
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description.text = skill.display_name + "\n" + skill.description
		description.add_theme_font_size_override("font_size", 14)
		row.add_child(description)
		var rank := Label.new()
		rank.custom_minimum_size.x = 40
		row.add_child(rank)
		var upgrade := Button.new()
		upgrade.custom_minimum_size = Vector2(140, 44)
		upgrade.text = "MEJORAR"
		upgrade.add_theme_font_size_override("font_size", 15)
		upgrade.pressed.connect(func(): skills.upgrade(skill.id))
		row.add_child(upgrade)
		content.get_node("Body/Skills").add_child(row)
		_rows[skill.id] = {"rank": rank, "button": upgrade}
	progression.changed.connect(refresh)
	skills.skill_acquired.connect(func(_id: StringName, _rank: int): refresh())
	actor.get_node("HealthComponent").health_changed.connect(func(_current: float, _maximum: float): refresh())
	actor.get_node("Equipment").active_changed.connect(func(_weapon: Node): refresh())
	actor.get_node("HealthComponent").died.connect(on_player_died)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("character") and _alive:
		if window.visible: close_window()
		else: open_panel()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel") and window.visible:
		close_window()
		get_viewport().set_input_as_handled()

func open_panel() -> void:
	if not _alive or actor == null: return
	if window.visible:
		refresh()
		return
	window.show()
	refresh()
	opened_changed.emit(true)
	content.get_node("Header/Close").grab_focus()

func close_window() -> void:
	if window.visible:
		window.hide()
		opened_changed.emit(false)

func on_player_died() -> void:
	_alive = false
	close_window()

func refresh() -> void:
	if not window.visible or progression == null: return
	var required := progression.required_xp()
	content.get_node("Summary").text = "Nivel %d  ·  XP %s  ·  Total: %d  ·  Puntos disponibles: %d" % [
		progression.level, "%d / %d" % [progression.xp, required] if required > 0 else "MÁXIMO",
		progression.total_xp(), progression.available_points]
	var bar := content.get_node("XPBar") as ProgressBar
	bar.max_value = required if required > 0 else 1
	bar.value = progression.xp if required > 0 else 1
	var health: HealthComponent = actor.get_node("HealthComponent")
	var survival: SurvivalComponent = actor.get_node("SurvivalComponent")
	var weapon: Node = actor.get_node("Equipment").active_weapon
	var reload_text := "No aplica" if weapon.config.weapon_type == "melee" else "%.2f s" % weapon.effective_reload_duration()
	content.get_node("Body/Stats/Values").text = "Salud: %.0f / %.0f HP\nBase máxima: %.0f HP\n\nVelocidad: %.1f px/s\nBase: %.0f px/s\n\nRecarga activa: %s\n\nConsumo de necesidades: %.0f %%\nHambre: 1 punto / %.2f s\nSed: 1 punto / %.2f s" % [
		health.current_health, health.max_health, health.base_max_health, actor.effective_speed(), actor.speed,
		reload_text, survival.consumption_multiplier * 100,
		survival.hunger_seconds_per_point / survival.consumption_multiplier,
		survival.thirst_seconds_per_point / survival.consumption_multiplier]
	for skill in skills.definitions:
		_rows[skill.id].rank.text = "%d / %d" % [skills.rank_of(skill.id), skill.max_rank]
		_rows[skill.id].button.disabled = not skills.can_upgrade(skill.id)
