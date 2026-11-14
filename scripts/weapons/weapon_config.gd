class_name WeaponConfig
extends Resource
## Configuración compartible; la munición de cada instancia vive en Weapon.
@export var id: StringName = &"pistol"
@export_enum("hitscan", "spread", "melee") var weapon_type: String = "hitscan"
@export var ammo_type: StringName = &"pistol"
@export var icon: Texture2D
@export var visual: Texture2D
@export_range(-1, 1000) var initial_loaded: int = -1
@export_range(1, 32) var pellet_count: int = 1
@export_range(0, 180) var spread_degrees: float = 0.0
@export_range(1, 180) var melee_arc_degrees: float = 90.0
@export var weapon_name: String = "Pistola básica"
@export_range(0, 1000) var capacity: int = 12
@export_range(0, 10000) var initial_reserve: int = 48
@export_range(0.1, 1000.0) var damage: float = 25.0
@export_range(0.01, 60.0) var fire_interval: float = 0.3
@export_range(0.01, 60.0) var reload_duration: float = 1.5
@export_range(1.0, 10000.0) var shot_range: float = 600.0
