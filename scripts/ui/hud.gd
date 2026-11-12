extends CanvasLayer
signal retry_requested
@export var effects_enabled: bool = true
var previous_health: float = 100.0
var damage_tween: Tween

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
	$Panel/Margin/Content/Ammo.text = "Munición: %d / %d" % [loaded, reserve]

func update_reload(active: bool) -> void:
	$Panel/Margin/Content/Reload.text = "RECARGANDO..." if active else ""

func update_stats(kills: int, seconds: float) -> void:
	$Panel/Margin/Content/Stats.text = "Eliminados: %d · Tiempo: %02d:%02d" % [kills, int(seconds) / 60, int(seconds) % 60]
