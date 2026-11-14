extends CanvasLayer
signal retry_requested
@export var effects_enabled: bool = true
var previous_health: float = 100.0
var damage_tween: Tween
var _message_remaining: float = 0.0
var _melee := false

@onready var bar: ProgressBar = $Panel/Margin/Content/HealthBar
@onready var value_label: Label = $Panel/Margin/Content/HealthValue
@onready var game_over: Control = $GameOver

func _ready() -> void:
	$GameOver/Center/Panel/Margin/Content/Retry.pressed.connect(func(): retry_requested.emit())

func update_health(current: float, maximum: float) -> void:
	bar.max_value = maximum
	bar.value = current
	value_label.text = "%d / %d" % [current, maximum]
	if current < previous_health and effects_enabled:
		if damage_tween != null:
			damage_tween.kill()
		$DamageFlash.color.a = 0.18
		damage_tween = create_tween()
		damage_tween.tween_property($DamageFlash, "color:a", 0.0, 0.25)
	previous_health = current

func show_game_over() -> void:
	game_over.show()
	$GameOver/Center/Panel/Margin/Content/Retry.grab_focus()

func update_ammo(loaded: int, reserve: int) -> void:
	$Panel/Margin/Content/Ammo.text = "CUERPO A CUERPO" if _melee else "Munición: %d / %d" % [loaded, reserve]

func update_equipment(equipment: EquipmentComponent) -> void:
	var config: WeaponConfig = equipment.active_weapon.config
	_melee = config.weapon_type == "melee"
	$Panel/Margin/Content/WeaponRow/Icon.texture = config.icon
	$Panel/Margin/Content/WeaponRow/Name.text = config.weapon_name
	var shortcuts: Array[String] = []
	for index in range(4):
		var id := equipment.ORDER[index]
		var label := "%d %s" % [index + 1, ["M", "P", "R", "E"][index]]
		if not equipment.owns(id): label += "—"
		if id == config.id: label = "[" + label + "]"
		shortcuts.append(label)
	$Panel/Margin/Content/Arsenal.text = "  ·  ".join(shortcuts)

func update_reload(active: bool) -> void:
	$Panel/Margin/Content/Reload.text = "RECARGANDO..." if active else ""
	$Panel/Margin/Content/Reload.visible = active

func update_stats(kills: int, seconds: float) -> void:
	$Panel/Margin/Content/Stats.text = "Eliminados: %d · Tiempo: %02d:%02d" % [kills, int(seconds) / 60, int(seconds) % 60]

func update_needs(hunger: float, thirst: float) -> void:
	$Panel/Margin/Content/Needs.text = "Hambre: %d · Sed: %d" % [ceili(hunger), ceili(thirst)]
	$Panel/Margin/Content/Needs.modulate = Color("f5b576") if minf(hunger, thirst) <= 20 else Color.WHITE

func update_interaction(text: String) -> void:
	$InteractionPrompt.text = text

func show_message(message: String) -> void:
	$Feedback.text = message
	_message_remaining = 3.0

func _process(delta: float) -> void:
	if _message_remaining > 0:
		_message_remaining = maxf(0, _message_remaining - delta)
		if _message_remaining == 0: $Feedback.text = ""
