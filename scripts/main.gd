extends Node2D
## Coordina señales entre personajes y presentación.
var kills: int = 0
var survival_time: float = 0.0
var game_ended: bool = false

func _ready() -> void:
	var health := $Player/HealthComponent as HealthComponent
	health.health_changed.connect($HUD.update_health)
	health.died.connect($HUD.show_game_over)
	health.died.connect(func(): game_ended = true)
	$HUD.retry_requested.connect(_retry)
	$HUD.update_health(health.current_health, health.max_health)
	var weapon := $Player/Weapon
	weapon.ammo_changed.connect($HUD.update_ammo)
	weapon.reload_changed.connect($HUD.update_reload)
	$HUD.update_ammo(weapon.loaded, weapon.reserve)
	$HUD.update_reload(false)
	$HUD.update_stats(kills, survival_time)
	for zombie in $Zombies.get_children():
		zombie.set_target($Player)
		zombie.eliminated.connect(_on_eliminated)

func _process(delta: float) -> void:
	if not game_ended:
		survival_time += delta
		$HUD.update_stats(kills, survival_time)

func _on_eliminated() -> void:
	kills += 1
	$HUD.update_stats(kills, survival_time)

func _retry() -> void:
	get_tree().reload_current_scene()
