extends CanvasLayer
var tracker: MissionTracker
var title: Label
var objective_label: Label

func _ready() -> void:
	layer = 1
	tracker = get_parent().get_node("Missions")
	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.theme = preload("res://assets/ui/SurvivalTheme.tres")
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	panel.offset_left = -356
	panel.offset_right = -16
	panel.offset_top = 16
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + side, 12)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(box)
	title = Label.new()
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color("dec787"))
	box.add_child(title)
	objective_label = Label.new()
	objective_label.custom_minimum_size.x = 290
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_label.add_theme_font_size_override("font_size", 13)
	box.add_child(objective_label)
	for label in [title, objective_label]: label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tracker.changed.connect(refresh)
	get_parent().get_node("Player/HealthComponent").died.connect(hide)
	refresh()

func refresh() -> void:
	var mission := tracker.active_mission()
	if mission == null:
		var completed := not tracker.definitions.is_empty()
		for entry in tracker.definitions:
			if tracker.state_of(entry.id) != MissionTracker.State.COMPLETED: completed = false
		title.text = "CAPÍTULO COMPLETADO" if completed else "SIN MISIÓN ACTIVA"
		objective_label.text = "Sigue explorando · J: historial" if completed else "J: consultar misiones"
		return
	title.text = mission.title + " · J"
	for index in range(mission.objectives.size()):
		var objective := mission.objectives[index]
		var current := tracker.progress_of(mission.id, index)
		if current < objective.target:
			objective_label.text = "%s (%d/%d)" % [objective.description, current, objective.target]
			return
