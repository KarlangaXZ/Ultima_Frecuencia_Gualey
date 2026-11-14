class_name ZoneExit
extends Area2D
@export var destination: String
@export var entry: String
var available := false:
	set(value):
		available = value
		queue_redraw()
var destination_label := "Salida"
func interaction_name() -> String:
	return "Viajar a " + destination_label if available else "Salida cerrada · completa La señal perdida"
func try_activate(interaction: Node) -> bool:
	if not available or interaction.actor.controls_blocked or not interaction.can_access(self): return false
	return interaction.actor.get_parent().get_node("ZoneManager").request_travel(destination, entry)
func _draw() -> void:
	var color := Color("dec787") if available else Color("667b70")
	draw_circle(Vector2.ZERO,30,Color("142729"))
	draw_arc(Vector2.ZERO,29,0,TAU,32,color,2)
	draw_line(Vector2(-16,0),Vector2(16,0),color,4)
	draw_polyline(PackedVector2Array([Vector2(4,-12),Vector2(16,0),Vector2(4,12)]),color,4)
