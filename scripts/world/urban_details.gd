extends Node2D
## Cables aéreos decorativos entre postes sólidos. Nunca intervienen en navegación.
@export var cable_color := Color("182425", 0.65)

func _draw() -> void:
	var poles := [Vector2(365, 660), Vector2(1030, 350), Vector2(2040, 640), Vector2(2040, 1300)]
	for index in range(poles.size() - 1):
		var start: Vector2 = poles[index]
		var end: Vector2 = poles[index + 1]
		for offset in [Vector2.ZERO, Vector2(0, 5)]:
			var points := PackedVector2Array()
			for step in range(17):
				var t := step / 16.0
				points.append(start.lerp(end, t) + offset + Vector2(0, sin(t * PI) * 24))
			draw_polyline(points, cable_color, 1.0, true)
