extends Node
## Solo selección de comportamiento. Cadencia y munición siguen en Weapon.
func attack(config: WeaponConfig, origin: Vector2, direction: Vector2, damage: float, shot_range: float) -> void:
	match config.weapon_type:
		"melee": $"../MeleeCombat".attack(config, origin, direction)
		"spread": $"../SpreadCombat".fire(config, origin, direction)
		_: $"../Combat".fire(origin, direction, damage, shot_range)
