class_name ChapterWindow
extends CanvasLayer
## Base de las dos ventanas nuevas; usa el tema existente y el coordinador único.
signal opened_changed(active: bool)
var window: Control
var panel: PanelContainer
var content: VBoxContainer
var close_button: Button
var _alive := true

func _ready() -> void:
	layer = 2
	window = Control.new()
	window.name = "Root"
	window.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	window.theme = preload("res://assets/ui/SurvivalTheme.tres")
	window.hide()
	add_child(window)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.02, 0.035, 0.04, 0.7)
	window.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	window.add_child(center)
	panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(960, 560)
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	panel.add_child(margin)
	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	margin.add_child(content)
	var header := HBoxContainer.new()
	content.add_child(header)
	var title := Label.new()
	title.name = "Title"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 25)
	title.add_theme_color_override("font_color", Color("dec787"))
	header.add_child(title)
	close_button = Button.new()
	close_button.text = "CERRAR"
	close_button.custom_minimum_size = Vector2(110, 40)
	close_button.pressed.connect(close_window)
	header.add_child(close_button)
	_setup(title)
	get_parent().get_node("Player/HealthComponent").died.connect(on_player_died)

func _setup(_title: Label) -> void:
	pass

func open_panel() -> void:
	if not _alive or window.visible: return
	window.show()
	opened_changed.emit(true)
	close_button.grab_focus()

func close_window() -> void:
	if window.visible:
		window.hide()
		opened_changed.emit(false)

func on_player_died() -> void:
	_alive = false
	close_window()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and window.visible:
		close_window()
		get_viewport().set_input_as_handled()
