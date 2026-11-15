class_name ZombieArchetype
extends Resource
## Configuración inmutable. Las variantes multiplican la definición común.
@export var id: StringName = &"base"
@export var display_name := "Zombi común"
@export var base_archetype: ZombieArchetype
@export var base_health := 50.0
@export var base_speed := 105.0
@export var base_damage := 10.0
@export var health_multiplier := 1.0
@export var speed_multiplier := 1.0
@export var damage_multiplier := 1.0
@export var detection_radius := 250.0
@export var attack_distance := 35.0
@export var attack_interval := 1.5
@export var xp_reward := 30
@export var visual_library: SpriteFrames
@export var tint := Color.WHITE
@export var marker_color := Color.TRANSPARENT
@export_range(0.5,2.0) var audio_pitch := 1.0
@export_range(-12,0) var audio_gain_db := 0.0
@export var groan_interval_multiplier := 1.0
@export var audio_bank: AudioCatalog
func health_value() -> float:
	return (base_archetype.health_value() if base_archetype != null else base_health) * health_multiplier
func speed_value() -> float:
	return (base_archetype.speed_value() if base_archetype != null else base_speed) * speed_multiplier
func damage_value() -> float:
	return (base_archetype.damage_value() if base_archetype != null else base_damage) * damage_multiplier
func reference_speed() -> float:
	return base_archetype.reference_speed() if base_archetype != null else base_speed
func frames() -> SpriteFrames:
	return visual_library if visual_library != null else base_archetype.frames()
func sound_bank() -> AudioCatalog:
	return audio_bank if audio_bank != null else base_archetype.sound_bank()
func apply_to(actor: Node) -> void:
	actor.speed = speed_value()
	actor.max_health = health_value()
	actor.attack_damage = damage_value()
	actor.attack_interval = attack_interval
	actor.attack_distance = attack_distance
	actor.detection_radius = detection_radius
	actor.get_node("HealthComponent").max_health = actor.max_health
	actor.get_node("Visual").animation_library = frames()
