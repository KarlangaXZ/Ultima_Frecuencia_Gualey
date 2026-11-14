extends ChapterWindow
var radio: Node
var sender_label: Label
var message_label: Label
var next_button: Button

func _setup(title: Label) -> void:
	title.text = "RADIO"
	panel.custom_minimum_size = Vector2(820, 320)
	radio = get_parent().get_node("Radio")
	sender_label = Label.new()
	sender_label.add_theme_font_size_override("font_size", 15)
	sender_label.add_theme_color_override("font_color", Color("dec787"))
	content.add_child(sender_label)
	message_label = Label.new()
	message_label.custom_minimum_size = Vector2(760, 110)
	message_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.add_theme_font_size_override("font_size", 19)
	content.add_child(message_label)
	next_button = Button.new()
	next_button.text = "E · SIGUIENTE"
	next_button.pressed.connect(radio.advance)
	content.add_child(next_button)
	radio.message_changed.connect(_show_message)
	radio.finished.connect(close_window)

func _show_message(sender: String, message: String, index: int, total: int) -> void:
	sender_label.text = "%s · %d / %d" % [sender, index, total]
	message_label.text = message
	next_button.text = "E · CERRAR" if index == total else "E · SIGUIENTE"
	open_panel()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and window.visible:
		radio.advance()
		get_viewport().set_input_as_handled()
	else: super._input(event)
