extends "res://scripts/world/urban_obstacle.gd"
## Arte geométrico técnico; misma huella serializada que usa la navegación.
@export_enum("wall","fence","tower","rack","generator","transformer","checkpoint","car","building","barricade","crate") var kind := "wall"
func _draw() -> void:
	var area:=Rect2(-$CollisionShape2D.shape.size/2,$CollisionShape2D.shape.size)
	if kind=="car":
		_draw_car(area)
		return
	if kind=="building":
		_draw_building(area)
		return
	draw_rect(area,Color("18262f"))
	draw_rect(area.grow(-3),surface_color)
	match kind:
		"fence":
			for x in range(int(area.position.x),int(area.end.x),16):
				draw_line(Vector2(x,area.position.y),Vector2(minf(x+16,area.end.x),area.end.y),Color("a9abb0"),1)
		"tower":
			draw_rect(area.grow(-10),Color("526770"),false,5)
			draw_line(area.position,area.end,Color("b5b8c0"),8)
			draw_line(Vector2(area.position.x,area.end.y),Vector2(area.end.x,area.position.y),Color("b5b8c0"),8)
			draw_circle(Vector2.ZERO,48,Color("243c4b"))
			draw_arc(Vector2.ZERO,44,0,TAU,40,Color("c3c2ba"),5)
			draw_line(Vector2(-32,0),Vector2(32,0),Color("d8cb8b"),3)
			draw_line(Vector2(0,-32),Vector2(0,32),Color("d8cb8b"),3)
		"rack","transformer","generator":
			for y in range(int(area.position.y)+12,int(area.end.y)-6,18):
				draw_rect(Rect2(area.position.x+8,y,area.size.x-16,9),Color("333d4c"))
				draw_circle(Vector2(area.end.x-16,y+4),2,Color("77b7a8"))
		"checkpoint":
			draw_rect(area.grow(-12),Color("414953"))
			draw_rect(area.grow(-18),Color("8ca6a7"),false,3)
		"barricade":
			for x in range(int(area.position.x)+4,int(area.end.x)-12,24):
				draw_rect(Rect2(x,area.position.y+3,12,area.size.y-6),Color("c0a85b"))
		"crate":draw_rect(area.grow(-8),Color("b3a47a"),false,2)
	if not sign_text.is_empty() and kind!="fence":
		draw_string(ThemeDB.fallback_font,Vector2(area.position.x+7,area.end.y-8),sign_text,HORIZONTAL_ALIGNMENT_LEFT,area.size.x-14,13,Color("e5dbb0"))
