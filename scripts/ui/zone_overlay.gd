extends CanvasLayer
signal black_reached
var curtain: ColorRect
var title: Label
var banner: Label
var _banner_tween: Tween
func _ready() -> void:
	layer = 8
	process_mode = Node.PROCESS_MODE_ALWAYS
	curtain = ColorRect.new()
	curtain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	curtain.color = Color.BLACK
	curtain.hide()
	add_child(curtain)
	title = Label.new()
	title.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size",30)
	curtain.add_child(title)
	banner = Label.new()
	banner.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	banner.offset_left = -350
	banner.offset_right = 350
	banner.offset_top = 112
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.add_theme_font_size_override("font_size",23)
	banner.add_theme_color_override("font_color",Color("dec787"))
	banner.add_theme_color_override("font_shadow_color",Color.BLACK)
	banner.add_theme_constant_override("shadow_offset_x",2)
	banner.add_theme_constant_override("shadow_offset_y",2)
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.hide()
	add_child(banner)
func fade_out(label: String) -> void:
	banner.hide()
	title.text = label.to_upper()
	curtain.modulate.a = 0
	curtain.show()
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(curtain,"modulate:a",1.0,0.2)
	await tween.finished
	black_reached.emit()
func fade_in(label: String) -> void:
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(curtain,"modulate:a",0.0,0.2)
	await tween.finished
	curtain.hide()
	show_location(label)
func show_location(label: String) -> void:
	if _banner_tween != null: _banner_tween.kill()
	banner.text = label.to_upper()
	banner.modulate.a = 1
	banner.show()
	_banner_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_STOP)
	_banner_tween.tween_interval(2.0)
	_banner_tween.tween_property(banner,"modulate:a",0.0,0.5)
