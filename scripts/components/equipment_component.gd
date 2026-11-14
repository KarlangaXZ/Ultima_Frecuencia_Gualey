class_name EquipmentComponent
extends Node
## Propiedad y estado por arma. No replica municiones ni consulta la física.
signal active_changed(weapon: Node)
signal arsenal_changed
signal empty_triggered
signal ammo_changed(loaded: int, reserve: int)
signal reload_changed(active: bool)
signal attack_performed(config: WeaponConfig, origin: Vector2, direction: Vector2, damage: float, shot_range: float)
const ORDER: Array[StringName] = [&"machete", &"pistol", &"revolver", &"shotgun"]
var _weapons: Dictionary = {}
var active_weapon: Node
var _enabled := true
var selection_blocked := false

func initialize(pistol: Node) -> void:
	if active_weapon != null: return
	_register(pistol)
	active_weapon = pistol
	obtain(preload("res://resources/weapons/Machete.tres"))
	active_changed.emit(pistol)

func owns(id: StringName) -> bool:
	return _weapons.has(id)

func get_weapon(id: StringName) -> Node:
	return _weapons.get(id)

func get_weapons() -> Array[Node]:
	var result: Array[Node] = []
	for weapon in _weapons.values(): result.append(weapon)
	return result

func can_obtain(config: WeaponConfig) -> bool:
	return _enabled and config != null and config.id in ORDER and not owns(config.id)

func obtain(config: WeaponConfig) -> bool:
	if not can_obtain(config): return false
	var weapon := Node.new()
	weapon.set_script(preload("res://scripts/weapons/weapon.gd"))
	weapon.config = config
	weapon.equipped = false
	add_child(weapon)
	_register(weapon)
	arsenal_changed.emit()
	return true

func _register(weapon: Node) -> void:
	_weapons[weapon.config.id] = weapon
	weapon.shot_fired.connect(_on_attack.bind(weapon))
	weapon.melee_attacked.connect(_on_attack.bind(weapon))
	weapon.empty_triggered.connect(func():
		if _enabled and weapon == active_weapon: empty_triggered.emit())
	weapon.ammo_changed.connect(func(loaded: int, reserve: int):
		if weapon == active_weapon: ammo_changed.emit(loaded, reserve))
	weapon.reload_changed.connect(func(active: bool):
		if weapon == active_weapon: reload_changed.emit(active))

func _on_attack(origin: Vector2, direction: Vector2, damage: float, shot_range: float, weapon: Node) -> void:
	if _enabled and weapon == active_weapon:
		attack_performed.emit(weapon.config, origin, direction, damage, shot_range)

func switch_to(id: StringName) -> bool:
	if not _enabled or selection_blocked or not owns(id): return false
	var next: Node = _weapons[id]
	if next == active_weapon: return false
	active_weapon.set_equipped(false)
	active_weapon = next
	active_weapon.set_equipped(true)
	active_changed.emit(active_weapon)
	ammo_changed.emit(active_weapon.loaded, active_weapon.reserve)
	reload_changed.emit(active_weapon.reloading)
	return true

func cycle(step: int) -> void:
	var index := ORDER.find(active_weapon.config.id)
	for offset in range(1, ORDER.size() + 1):
		var candidate: StringName = ORDER[posmod(index + offset * step, ORDER.size())]
		if owns(candidate):
			switch_to(candidate)
			return

func ammo_weapon(type: StringName) -> Node:
	for weapon in _weapons.values():
		if weapon.config.weapon_type != "melee" and weapon.config.ammo_type == type: return weapon
	return null

func disable_all() -> void:
	_enabled = false
	for weapon in _weapons.values(): weapon.disable()
