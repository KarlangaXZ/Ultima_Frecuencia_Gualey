extends CanvasLayer
## Arranque sin mundo activo; reutiliza SaveFileStore/SaveCoordinator para cargar.
const MAIN:=preload("res://scenes/Main.tscn")
var store:=SaveFileStore.new()
var page: String="home"
var busy:=false
var pending_slot: int=-1
var view: Control
var pages: Dictionary={}
var slot_rows: Array[Dictionary]=[]
var sliders: Dictionary={}
var fullscreen: CheckBox
var status: Label
var confirm: ConfirmationDialog
var start_button: Button
var preview: SoundEmitter
func label(text: String,font_size: int=18) -> Label:
	var result:=Label.new()
	result.text=text
	result.add_theme_font_size_override("font_size",font_size)
	return result
func button(text: String,callback: Callable,primary: bool=false) -> Button:
	var result:=Button.new()
	result.text=text
	result.custom_minimum_size.y=52
	if primary:
		result.add_theme_color_override("font_focus_color",Color("16191e"))
	else:
		for item in [["normal","2c313b"],["hover","3d4653"],["pressed","20252d"]]:
			var style:=StyleBoxFlat.new()
			style.bg_color=Color(item[1])
			style.set_border_width_all(1)
			style.border_color=Color("626873")
			style.set_corner_radius_all(3)
			style.content_margin_left=22
			style.content_margin_right=22
			style.content_margin_top=12
			style.content_margin_bottom=12
			result.add_theme_stylebox_override(item[0],style)
		for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
			result.add_theme_color_override(state,Color("e5e2dc"))
	result.pressed.connect(callback)
	return result
func _ready() -> void:
	MusicDirector.enter_menu(self)
	preview=SoundEmitter.new()
	preview.max_voices=2
	add_child(preview)
	view=Control.new()
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	view.theme=preload("res://assets/ui/SurvivalTheme.tres")
	add_child(view)
	var background:=Control.new()
	background.set_script(preload("res://scripts/ui/title_background.gd"))
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	view.add_child(background)
	var margin:=MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right"]:margin.add_theme_constant_override("margin_"+side,64)
	for side in ["top","bottom"]:margin.add_theme_constant_override("margin_"+side,38)
	view.add_child(margin)
	var layout:=VBoxContainer.new()
	layout.add_theme_constant_override("separation",20)
	margin.add_child(layout)
	var eyebrow:=label("GUALEY",15)
	eyebrow.add_theme_color_override("font_color",Color("c5aa79"))
	layout.add_child(eyebrow)
	var container:=Control.new()
	container.size_flags_vertical=Control.SIZE_EXPAND_FILL
	layout.add_child(container)
	_build_home(container)
	_build_slots(container)
	_build_settings(container)
	status=label("",16)
	status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	status.custom_minimum_size.y=28
	layout.add_child(status)
	layout.add_child(label("SUPERVIVENCIA  ·  EXPLORACIÓN  ·  SEÑALES                                     EN DESARROLLO",13))
	confirm=ConfirmationDialog.new()
	confirm.title="Nueva partida"
	confirm.dialog_text=""
	confirm.ok_button_text="Reemplazar e iniciar"
	confirm.cancel_button_text="Cancelar"
	confirm.confirmed.connect(func():_launch(pending_slot,true,true))
	confirm.canceled.connect(func():pending_slot=-1)
	view.add_child(confirm)
	show_page("home")
func _page(parent: Control,id: String) -> VBoxContainer:
	var box:=VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.add_theme_constant_override("separation",14)
	parent.add_child(box)
	pages[id]=box
	return box
func _build_home(parent: Control) -> void:
	var box:=_page(parent,"home")
	var space:=Control.new()
	space.custom_minimum_size.y=55
	box.add_child(space)
	var row:=HBoxContainer.new()
	row.add_theme_constant_override("separation",52)
	box.add_child(row)
	var title:=VBoxContainer.new()
	title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	title.add_theme_constant_override("separation",16)
	row.add_child(title)
	title.add_child(label("ÚLTIMA\nFRECUENCIA",64))
	var name:=label("G U A L E Y",30)
	name.add_theme_color_override("font_color",Color("d70000ff"))
	title.add_child(name)
	title.add_child(label("Una señal entre el ruido.\nUna salida entre los infectados.",21))
	var panel:=PanelContainer.new()
	panel.custom_minimum_size.x=370
	row.add_child(panel)
	var menu:=VBoxContainer.new()
	menu.add_theme_constant_override("separation",18)
	var inset:=MarginContainer.new()
	for side in ["left","right","top","bottom"]:inset.add_theme_constant_override("margin_"+side,24)
	panel.add_child(inset)
	inset.add_child(menu)
	menu.add_child(label("LA SEÑAL SIGUE ACTIVA",16))
	start_button=button("EMPEZAR EL JUEGO",show_page.bind("slots"),true)
	menu.add_child(start_button)
	menu.add_child(button("CONFIGURACIÓN",show_page.bind("settings")))
	menu.add_child(button("SALIR",func():get_tree().quit()))
func _build_slots(parent: Control) -> void:
	var box:=_page(parent,"slots")
	box.add_child(label("Elige tu partida",34))
	box.add_child(label("Continúa tu historia o comienza en una de las tres ranuras.",17))
	for slot in range(1,4):
		var panel:=PanelContainer.new()
		box.add_child(panel)
		var row:=HBoxContainer.new()
		row.add_theme_constant_override("separation",20)
		var inset:=MarginContainer.new()
		for side in ["left","right","top","bottom"]:inset.add_theme_constant_override("margin_"+side,12)
		panel.add_child(inset)
		inset.add_child(row)
		var summary:=label("",18)
		summary.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		summary.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		row.add_child(summary)
		var resume:=button("CONTINUAR",_launch.bind(slot,false,false),true)
		resume.custom_minimum_size.x=180
		row.add_child(resume)
		var fresh:=button("NUEVA PARTIDA",request_new.bind(slot))
		fresh.custom_minimum_size.x=210
		row.add_child(fresh)
		slot_rows.append({"label":summary,"continue":resume,"new":fresh})
	var back:=button("VOLVER",show_page.bind("home"))
	back.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
	box.add_child(back)
func _build_settings(parent: Control) -> void:
	var box:=_page(parent,"settings")
	box.add_theme_constant_override("separation",8)
	box.add_child(label("Configuración",34))
	box.add_child(label("Audio y pantalla · Los cambios de volumen se escuchan al instante.",17))
	for item in [["master","Volumen general"],["music","Música"],["effects","Efectos y zombis"],["ambience","Ambiente"],["interface","Interfaz y radio"]]:
		var row:=HBoxContainer.new()
		box.add_child(row)
		var title:=label(item[1],19)
		title.custom_minimum_size.x=245
		row.add_child(title)
		var slider:=HSlider.new()
		slider.min_value=0
		slider.max_value=100
		slider.step=1
		slider.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		slider.custom_minimum_size.y=30
		row.add_child(slider)
		var value_label:=label("100 %",18)
		value_label.custom_minimum_size.x=80
		row.add_child(value_label)
		slider.value_changed.connect(func(value: float):
			value_label.text="%d %%"%int(value)
			AppPreferences.set_value(item[0],value))
		sliders[item[0]]=slider
	fullscreen=CheckBox.new()
	fullscreen.flat=true
	for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
		fullscreen.add_theme_color_override(state,Color("e5e2dc"))
	fullscreen.add_theme_color_override("checkbox_unchecked_color",Color("bfbab0"))
	fullscreen.add_theme_color_override("checkbox_checked_color",Color("d2b17b"))
	fullscreen.text="Pantalla completa"
	fullscreen.toggled.connect(func(active: bool):AppPreferences.set_value("fullscreen",active))
	box.add_child(fullscreen)
	var previews:=HBoxContainer.new()
	box.add_child(previews)
	for item in [["Effects","pistol_shot","Probar efectos",-12.0],["Ambience","ambience","Probar ambiente",-30.0],["Interface","ui_select","Probar interfaz",-18.0]]:
		var test_button:=button(item[2],func():
			preview.audio_bus=StringName(item[0])
			preview.volume_db=item[3]
			preview.play_event(StringName(item[1]),0.2))
		test_button.add_theme_font_size_override("font_size",16)
		previews.add_child(test_button)
	var buttons:=HBoxContainer.new()
	box.add_child(buttons)
	buttons.add_child(button("RESTABLECER",func():
		AppPreferences.reset_defaults()
		_refresh_settings()))
	buttons.add_child(button("GUARDAR Y VOLVER",_save_settings,true))
func _refresh_settings() -> void:
	for key in sliders:sliders[key].value=AppPreferences.values[key]
	fullscreen.set_pressed_no_signal(AppPreferences.values.fullscreen)
func _save_settings() -> void:
	var error:=AppPreferences.save_settings()
	if error!=OK:
		status.text="No se pudo guardar la configuración: "+error_string(error)
		return
	show_page("home")
func show_page(id: String) -> void:
	if busy:return
	page=id
	for key in pages:pages[key].visible=key==id
	status.text=""
	if id=="slots":refresh_slots()
	if id=="settings":_refresh_settings()
	if id=="home":start_button.grab_focus()
func refresh_slots() -> void:
	for index in range(3):
		var result:=store.read_slot(index+1)
		var text: String="RANURA %d · VACÍA"%(index+1)
		if result.has("data"):
			text="RANURA %d · NIVEL %d\n%s · %s\n%s UTC%s"%[index+1,result.data.player.progression.level,ChapterCatalog.title(result.data.chapter),ZoneCatalog.definition(result.data.map).display_name,String(result.data.saved_at).replace("T"," ").trim_suffix("Z")," · Respaldo" if result.recovered else ""]
		elif store.occupied(index+1):text="RANURA %d · NO DISPONIBLE\n%s"%[index+1,result.error]
		slot_rows[index].label.text=text
		slot_rows[index]["continue"].disabled=not result.has("data")
func request_new(slot: int) -> void:
	if busy:return
	if store.occupied(slot):
		pending_slot=slot
		confirm.dialog_text="La ranura %d está ocupada. ¿Quieres reemplazarla con una partida nueva? Se conservará un respaldo de la partida válida anterior."%slot
		confirm.popup_centered(Vector2i(610,180))
	else:_launch(slot,true,false)
func _prepare() -> Node:
	var main: Node=MAIN.instantiate()
	main.name="LaunchPreparation"
	main.restoring=true
	main.process_mode=Node.PROCESS_MODE_DISABLED
	main.hide()
	main.get_node("World/Navigation").enabled=false
	get_tree().root.add_child(main)
	main.get_node("PauseUI").set_process_input(false)
	for node in main.find_children("*","CanvasLayer",true,false):node.hide()
	main.get_node("SaveCoordinator").store.directory=store.directory
	return main
func _launch(slot: int,fresh: bool,confirmed: bool) -> void:
	if busy or slot<1 or slot>3:return
	busy=true
	status.text="Preparando partida…"
	var tree:=get_tree()
	var main:=_prepare()
	var saves: Node=main.get_node("SaveCoordinator")
	var result: Dictionary
	if fresh:
		main.get_node("World/Navigation").enabled=true
		main.get_node("Population").start()
		for i in range(4):
			await tree.physics_frame
			await tree.process_frame
			NavigationServer2D.map_force_update(main.get_node("Player").get_world_2d().navigation_map)
			main.get_node("Population")._physics_process(0)
			if main.get_node("Population")._initialized:break
		main.restoring=false
		result=saves.save_slot(slot,confirmed)
		if result.has("ok"):
			main.name="Main"
			tree.current_scene=main
			main.process_mode=Node.PROCESS_MODE_INHERIT
			main.get_node("PauseUI").set_process_input(true)
			main.show()
			for node in main.find_children("*","CanvasLayer",true,false):node.show()
			main.get_node("Player").set_controls_blocked(false)
			if DisplayServer.get_name()!="headless":main.get_node("Audio").ambience.play()
			MusicDirector.enter_gameplay(main)
			main.get_node("ZoneOverlay").show_location(ZoneCatalog.definition(ZoneCatalog.HOME).display_name)
	else:
		# La escena de apoyo ya terminó _ready sin arrancar simulación/ambiente.
		main.restoring=false
		result=saves.load_slot(slot)
	if result.has("error"):
		tree.root.remove_child(main)
		main.queue_free()
		busy=false
		status.text=result.error
		return
	# SaveCoordinator carga mediante su candidato validado; el menú se retira solo
	# después del éxito. Ninguna ranura ni escena se reemplaza en caso de error.
	tree.root.remove_child(self)
	queue_free()
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not busy:
		if page!="home":show_page("home")
		get_viewport().set_input_as_handled()
