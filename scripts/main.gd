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
	var weapon := $Player/Equipment
	weapon.ammo_changed.connect($HUD.update_ammo)
	weapon.reload_changed.connect($HUD.update_reload)
	weapon.active_changed.connect(_update_equipment)
	weapon.arsenal_changed.connect(func():
		_update_equipment(weapon.active_weapon)
		$InventoryUI.refresh_usage())
	_update_equipment(weapon.active_weapon)
	$HUD.update_reload(false)
	$HUD.update_stats(kills, survival_time)
	for zombie in $Zombies.get_children():
		zombie.set_target($Player)
		zombie.eliminated.connect(_on_eliminated)
	_bind_supplies()

func _bind_supplies() -> void:
	var ui := $InventoryUI
	var survival := $Player/SurvivalComponent
	var interaction := $Player/Interaction
	ui.bind_inventory($Player/InventoryComponent, $Player/ItemUse)
	ui.opened_changed.connect($Player.set_controls_blocked)
	ui.use_requested.connect($Player/ItemUse.use_slot)
	ui.transfer_requested.connect(interaction.transfer_from_container)
	interaction.container_opened.connect(ui.open_container)
	interaction.prompt_changed.connect($HUD.update_interaction)
	interaction.feedback.connect(_supplies_feedback)
	$Player/ItemUse.feedback.connect(_supplies_feedback)
	$Player/HealthComponent.died.connect(ui.on_player_died)
	$Player/HealthComponent.health_changed.connect(func(_current: float, _maximum: float): ui.refresh_usage())
	survival.needs_changed.connect(_update_needs)
	_update_needs(survival.hunger, survival.thirst)

func _update_equipment(weapon: Node) -> void:
	$HUD.update_equipment($Player/Equipment)
	$HUD.update_ammo(weapon.loaded, weapon.reserve)
	$HUD.update_reload(weapon.reloading)

func _update_needs(hunger: float, thirst: float) -> void:
	$HUD.update_needs(hunger, thirst)
	$InventoryUI.refresh_usage()

func _supplies_feedback(message: String) -> void:
	$HUD.show_message(message)
	$InventoryUI.show_feedback(message)

func _process(delta: float) -> void:
	if not game_ended:
		survival_time += delta
		$HUD.update_stats(kills, survival_time)

func _on_eliminated() -> void:
	kills += 1
	$HUD.update_stats(kills, survival_time)

func _retry() -> void:
	get_tree().reload_current_scene()
