class_name MissionDefinition
extends Resource
@export var id: StringName
@export var title: String
@export_multiline var description: String
@export var prerequisites: Array[StringName] = []
@export var objectives: Array[MissionObjective] = []
@export_range(0, 10000) var reward_xp := 0
@export var sequential := false
@export var auto_activate := true
