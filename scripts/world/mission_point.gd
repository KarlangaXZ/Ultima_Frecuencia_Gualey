class_name MissionPoint
extends Area2D
## Punto transitable; la consulta de interacción existente valida radio y World.
signal activated(point: MissionPoint)
@export var point_id: StringName
@export var display_name: String
var available := false:
	set(value):
		available = value
		queue_redraw()

func interaction_name() -> String:
	return display_name + ("" if available else " (sin acción disponible)")

func try_activate(interaction: Node) -> bool:
	if not available or interaction.actor.controls_blocked or not interaction.can_access(self): return false
	available = false
	activated.emit(self)
	return true

func _draw() -> void:
	var accent := Color("dec787") if available else Color("667b70")
	draw_circle(Vector2.ZERO, 27, Color("152526"))
	draw_arc(Vector2.ZERO, 28, 0, TAU, 32, accent, 2)
	if point_id == &"radio":
		draw_rect(Rect2(-17, -10, 34, 23), Color("40544b"))
		draw_line(Vector2(10, -10), Vector2(15, -27), accent, 2)
		draw_circle(Vector2(-7, 2), 6, Color("122021"))
		draw_line(Vector2(3, -3), Vector2(12, -3), accent, 2)
	else:
		draw_rect(Rect2(-20, -17, 40, 34), Color("40544b"))
		draw_polyline(PackedVector2Array([Vector2(2,-12), Vector2(-7,2), Vector2(5,2), Vector2(-2,13)]), accent, 3)
