class_name WeaponConfig
extends Resource
## Configuración compartible; la munición de cada instancia vive en Weapon.
@export var weapon_name: String = "Pistola básica"
@export_range(1, 1000) var capacity: int = 12
@export_range(0, 10000) var initial_reserve: int = 48
@export_range(0.1, 1000.0) var damage: float = 25.0
@export_range(0.01, 60.0) var fire_interval: float = 0.3
@export_range(0.01, 60.0) var reload_duration: float = 1.5
@export_range(1.0, 10000.0) var shot_range: float = 600.0
