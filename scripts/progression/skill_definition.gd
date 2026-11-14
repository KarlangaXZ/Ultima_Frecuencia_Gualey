class_name SkillDefinition
extends Resource
@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export_range(1, 5) var max_rank := 5
@export_enum("max_health", "movement", "reload", "consumption") var modifier: String
@export var per_rank: float
