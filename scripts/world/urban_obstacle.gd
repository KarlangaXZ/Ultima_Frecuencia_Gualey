extends StaticBody2D
## Presentación provisional cenital. La huella procede de la colisión serializada.
## No crea física, navegación ni lógica de interacción.
@export_enum("building", "car", "dumpster", "barricade", "pole") var appearance: String = "building"
@export var surface_color := Color("678a85")
@export var sign_text: String = ""

func _draw() -> void:
	var shape := $CollisionShape2D.shape as RectangleShape2D
	var area := Rect2(-shape.size / 2.0, shape.size)
	draw_rect(area, Color("182326"))
	match appearance:
		"building":
			_draw_building(area)
		"car":
			_draw_car(area)
		"dumpster":
			draw_rect(area.grow(-3), surface_color)
			draw_rect(area.grow(-8), Color("344642"))
			draw_line(area.position + Vector2(8, 12), area.end - Vector2(8, area.size.y - 12), Color("8a9280"), 3)
			for point in [Vector2(-13, 8), Vector2(11, 14)]:
				draw_circle(point, 10, Color("222b29"))
				draw_line(point, point + Vector2(4, -6), Color("666d5b"), 2)
		"barricade":
			draw_rect(area.grow(-2), Color("6e6450"))
			for x in range(int(area.position.x) + 4, int(area.end.x) - 12, 24):
				draw_rect(Rect2(x, area.position.y + 4, 12, area.size.y - 8), Color("bba96c"))
			draw_line(area.position + Vector2(3, 3), area.end - Vector2(3, 3), Color("333c37"), 3)
		"pole":
			draw_rect(area.grow(-1), Color("a99e85"))
			draw_circle(Vector2.ZERO, 3, Color("4e5148"))

func _draw_building(area: Rect2) -> void:
	draw_rect(area.grow(-3), surface_color.darkened(0.25))
	draw_rect(area.grow(-9), surface_color)
	# Techo plano de concreto, pretil, parches y tanque de agua vistos desde arriba.
	for y in range(int(area.position.y) + 24, int(area.end.y) - 20, 32):
		draw_line(Vector2(area.position.x + 14, y), Vector2(area.end.x - 14, y), surface_color.darkened(0.12), 1)
	var tank := area.position + Vector2(38, 38)
	draw_circle(tank, 19, Color("253331"))
	draw_arc(tank, 15, 0, TAU, 24, Color("68746b"), 2)
	draw_rect(Rect2(area.end - Vector2(66, 53), Vector2(38, 24)), Color("8b9181"))
	for x in range(5, 35, 6):
		draw_line(area.end - Vector2(66 - x, 50), area.end - Vector2(66 - x, 33), Color("505f59"), 2)
	draw_polyline(PackedVector2Array([Vector2(10, -20), Vector2(22, -4), Vector2(15, 10), Vector2(33, 24)]), surface_color.darkened(0.3), 2)
	# Letrero horizontal sobre la cubierta/entrada; sin una fachada que tape actores.
	if not sign_text.is_empty():
		var font := ThemeDB.fallback_font
		var font_size := 15
		var width := minf(font.get_string_size(sign_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x + 24, area.size.x - 28)
		var plate := Rect2(-width / 2, area.end.y - 37, width, 26)
		draw_rect(plate, Color("293d3a"))
		draw_rect(plate, Color("baad7f"), false, 1)
		draw_string(font, plate.position + Vector2(10, 18), sign_text, HORIZONTAL_ALIGNMENT_LEFT, width - 16, font_size, Color("e0d6ac"))

func _draw_car(area: Rect2) -> void:
	var body := area.grow(-5)
	draw_rect(body, surface_color)
	var cabin := Rect2(area.position + area.size * Vector2(0.30, 0.13), area.size * Vector2(0.42, 0.74))
	draw_rect(cabin, Color("253b40"))
	draw_rect(cabin.grow(-5), surface_color.darkened(0.2))
	draw_line(cabin.position, cabin.end, Color("8b9a91"), 1)
	draw_line(cabin.position + Vector2(cabin.size.x, 0), cabin.position + Vector2(0, cabin.size.y), Color("8b9a91"), 1)
	for x in [area.position.x + 8, area.end.x - 24]:
		draw_rect(Rect2(x, area.position.y, 16, 5), Color("111b1e"))
		draw_rect(Rect2(x, area.end.y - 5, 16, 5), Color("111b1e"))
	draw_rect(Rect2(area.end.x - 13, area.position.y + 12, 7, 10), Color("aa9e75"))
	draw_rect(Rect2(area.position.x + 6, area.end.y - 22, 7, 10), Color("82534a"))
	draw_circle(area.position + Vector2(24, 24), 8, Color("875b3e"))
