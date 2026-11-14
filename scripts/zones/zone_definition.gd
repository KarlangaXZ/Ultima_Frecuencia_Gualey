class_name ZoneDefinition
extends Resource
@export var id: String
@export var display_name: String
@export var unlock_mission: StringName
@export var world_scene: PackedScene
@export var dimensions := Vector2(2400,1600)
@export var entries: Dictionary[String, Vector2] = {}
@export var container_ids: Array[String] = []
@export var pickup_ids: Array[String] = []
@export var enemy_prefix := "zombie_"
@export var initial_enemies := PackedVector2Array()
@export var spawn_points := PackedVector2Array()
@export_range(3,6) var active_limit := 6
@export_range(3,18) var total_budget := 18
@export var replacement_interval := 10.0
@export var enemy_weights: Dictionary[String,int] = {"base":100}
func archetype_for(ordinal: int) -> ZombieArchetype:
	return ZombieArchetypes.choose(enemy_weights,ordinal)
