class_name MissionObjective
extends Resource
## Evento semántico; histórico permite reconocer logros anteriores a la activación.
@export var event_key: StringName
@export_multiline var description: String
@export_range(1, 10000) var target: int = 1
@export var historical := false
