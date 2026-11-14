extends CanvasLayer
## Presentación y solicitudes. No almacena recursos ni aplica efectos.
signal opened_changed(active: bool)
signal selection_changed
signal use_requested(index: int)
signal transfer_requested(container: LootContainer, index: int)
@onready var window: Control = $Root
@onready var content: VBoxContainer = $Root/Center/Panel/Margin/Content
var inventory: InventoryComponent
var item_user: Node
var container: LootContainer
var selected: int = -1
var _slots: Array[Button] = []
var _loot_slots: Array[Button] = []
var _alive := true
var _slot_style: StyleBoxFlat
var _selected_style: StyleBoxFlat

func _ready() -> void:
	_slot_style = StyleBoxFlat.new()
	_slot_style.bg_color = Color("1b2b2a")
	_slot_style.set_border_width_all(1)
	_slot_style.border_color = Color("52665a")
	_selected_style = _slot_style.duplicate()
	_selected_style.bg_color = Color("33463b")
	_selected_style.border_color = Color("dec787")
	_selected_style.set_border_width_all(2)
	content.get_node("Header/Close").pressed.connect(close_window)
	content.get_node("Body/Details/Use").pressed.connect(func(): use_requested.emit(selected))
	for index in range(12):
		var button := Button.new()
		button.custom_minimum_size = Vector2(130, 100)
		button.add_theme_font_size_override("font_size", 15)
		button.clip_text = true
		button.add_theme_constant_override("icon_max_width", 24)
		button.add_theme_stylebox_override("normal", _slot_style)
		button.add_theme_stylebox_override("hover", _selected_style)
		button.add_theme_stylebox_override("pressed", _selected_style)
		var contents := VBoxContainer.new()
		contents.name = "Contents"
		contents.mouse_filter = Control.MOUSE_FILTER_IGNORE
		contents.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		contents.offset_left = 6
		contents.offset_top = 6
		contents.offset_right = -6
		contents.offset_bottom = -6
		contents.add_theme_constant_override("separation", 2)
		button.add_child(contents)
		var icon := TextureRect.new()
		icon.name = "Icon"
		icon.custom_minimum_size = Vector2(0, 22)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		contents.add_child(icon)
		for label_name in ["Name", "Quantity"]:
			var label := Label.new()
			label.name = label_name
			label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.add_theme_font_size_override("font_size", 13)
			if label_name == "Name":
				label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				label.custom_minimum_size.y = 32
			else: label.add_theme_color_override("font_color", Color("dec787"))
			contents.add_child(label)
		button.pressed.connect(_select.bind(index))
		content.get_node("Body/Bag/Grid").add_child(button)
		_slots.append(button)
		var loot_button := Button.new()
		loot_button.custom_minimum_size = Vector2(330, 46)
		loot_button.add_theme_font_size_override("font_size", 14)
		loot_button.add_theme_constant_override("icon_max_width", 22)
		loot_button.clip_text = true
		loot_button.pressed.connect(func(): transfer_requested.emit(container, index))
		content.get_node("Body/Details/LootScroll/Rows").add_child(loot_button)
		_loot_slots.append(loot_button)

func bind_inventory(source: InventoryComponent, user: Node) -> void:
	inventory = source
	item_user = user
	inventory.changed.connect(refresh)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory") and _alive:
		if window.visible: close_window()
		else: open_inventory()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel") and window.visible:
		close_window()
		get_viewport().set_input_as_handled()

func open_inventory() -> void:
	if not _alive: return
	content.get_node("Feedback").text = ""
	window.show()
	refresh()
	opened_changed.emit(true)
	content.get_node("Header/Close").grab_focus()

func open_container(source: LootContainer) -> void:
	if not _alive: return
	_disconnect_container()
	container = source
	container.inventory.changed.connect(_refresh_loot)
	open_inventory()

func _disconnect_container() -> void:
	if is_instance_valid(container) and container.inventory.changed.is_connected(_refresh_loot):
		container.inventory.changed.disconnect(_refresh_loot)
	container = null

func close_window() -> void:
	_disconnect_container()
	if window.visible:
		window.hide()
		opened_changed.emit(false)

func on_player_died() -> void:
	_alive = false
	close_window()

func _select(index: int) -> void:
	selected = index
	refresh()
	selection_changed.emit()

func refresh() -> void:
	if inventory == null or not window.visible: return
	content.get_node("Header/Capacity").text = "%d / %d ESPACIOS" % [inventory.occupied_slots(), inventory.capacity]
	for index in range(_slots.size()):
		var slot := inventory.get_slot(index)
		var button := _slots[index]
		button.get_node("Contents/Name").text = "VACÍO" if slot.is_empty() else slot.item.display_name
		button.get_node("Contents/Quantity").text = "%02d" % (index + 1) if slot.is_empty() else "×%d" % slot.quantity
		button.get_node("Contents/Icon").texture = null if slot.is_empty() else slot.item.icon
		button.tooltip_text = "Espacio vacío" if slot.is_empty() else slot.item.display_name
		button.add_theme_stylebox_override("normal", _selected_style if index == selected else _slot_style)
	refresh_usage()
	_refresh_loot()

func refresh_usage() -> void:
	if inventory == null or not window.visible: return
	var slot := inventory.get_slot(selected)
	var use_button := content.get_node("Body/Details/Use") as Button
	content.get_node("Body/Details/Description").text = "Selecciona un objeto de tu mochila." if slot.is_empty() else "%s\n%s" % [slot.item.display_name, slot.item.description]
	use_button.text = "PASAR A RESERVA" if not slot.is_empty() and slot.item.effect == "ammo" else "UTILIZAR"
	if not slot.is_empty() and slot.item.effect == "weapon": use_button.text = "INCORPORAR AL ARSENAL"
	use_button.disabled = not item_user.can_use(selected)

func _refresh_loot() -> void:
	if not window.visible: return
	var has_container := is_instance_valid(container)
	content.get_node("Body/Details/LootTitle").text = container.display_name if has_container else ""
	content.get_node("Body/Details/Empty").text = "Contenedor vacío" if has_container and container.inventory.occupied_slots() == 0 else ""
	for index in range(_loot_slots.size()):
		var slot: Dictionary = container.inventory.get_slot(index) if has_container else {}
		var button := _loot_slots[index]
		button.visible = not slot.is_empty()
		if not slot.is_empty():
			button.text = "RECOGER · %s ×%d" % [slot.item.display_name, slot.quantity]
			button.icon = slot.item.icon

func show_feedback(message: String) -> void:
	content.get_node("Feedback").text = message
