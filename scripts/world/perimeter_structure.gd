extends "res://scripts/world/urban_obstacle.gd"
## Arte técnico sustituible. Lee la huella serializada; nunca crea colisiones.
@export_enum("fence","booth","barrier","bus","tent","medical","ambulance","shelter","comms","generator","inspection","cargo","luggage") var kind: String="barrier"
func _draw() -> void:
	var a:=Rect2(-$CollisionShape2D.shape.size/2,$CollisionShape2D.shape.size)
	draw_rect(a,Color("2b2b2e"))
	draw_rect(a.grow(-3),surface_color)
	match kind:
		"bus":
			draw_rect(a.grow(-12),surface_color.darkened(0.15))
			draw_rect(Rect2(a.position+Vector2(16,12),Vector2(a.size.x-32,34)),Color("314346"))
			for y in range(int(a.position.y)+65,int(a.end.y)-35,42):
				for x in [a.position.x+5,a.end.x-15]:draw_rect(Rect2(x,y,10,26),Color("33484b"))
			for y in [a.position.y+42,a.end.y-55]:
				for x in [a.position.x,a.end.x-8]:draw_rect(Rect2(x,y,8,25),Color("172123"))
			draw_rect(Rect2(-25,-24,50,48),surface_color.lightened(0.12))
		"ambulance":
			_draw_car(a)
			draw_rect(Rect2(-24,-7,48,14),Color("a34538"))
			draw_rect(Rect2(-7,-24,14,48),Color("a34538"))
		"tent","shelter":
			draw_line(Vector2(a.position.x,0),Vector2(a.end.x,0),surface_color.lightened(0.2),5)
			for p in [a.position,Vector2(a.position.x,a.end.y),a.end,Vector2(a.end.x,a.position.y)]:draw_line(p,Vector2.ZERO,surface_color.darkened(0.23),2)
			if kind=="tent":
				draw_rect(Rect2(-28,-8,56,16),Color("934b3d"))
				draw_rect(Rect2(-8,-28,16,56),Color("934b3d"))
		"fence":
			for x in range(int(a.position.x),int(a.end.x),18):draw_line(Vector2(x,a.position.y),Vector2(minf(x+18,a.end.x),a.end.y),Color("aaa9a6"),1)
		"barrier":
			for x in range(int(a.position.x)+4,int(a.end.x)-14,32):draw_rect(Rect2(x,a.position.y+3,15,a.size.y-6),Color("d4ae67"))
		"medical":
			for x in range(int(a.position.x)+15,int(a.end.x)-40,80):
				draw_rect(Rect2(x,a.position.y+12,55,a.size.y-24),Color("e0d7ba"))
				draw_rect(Rect2(x+5,a.position.y+17,45,12),Color("9b9278"))
		"booth","inspection":
			draw_rect(a.grow(-13),Color("3e4651"))
			draw_rect(a.grow(-21),surface_color.darkened(0.1),false,3)
		"comms","generator":
			for y in range(int(a.position.y)+13,int(a.end.y)-15,24):draw_rect(Rect2(a.position.x+10,y,a.size.x-20,12),Color("3d4a5d"))
			if kind=="comms":draw_line(Vector2(0,-a.size.y/2),Vector2(0,-a.size.y/2+70),Color("d7c694"),4)
		"cargo":
			for x in range(int(a.position.x)+12,int(a.end.x)-10,24):draw_line(Vector2(x,a.position.y+8),Vector2(x,a.end.y-8),surface_color.darkened(0.25),3)
		"luggage":
			for x in range(int(a.position.x)+5,int(a.end.x)-20,30):draw_rect(Rect2(x,a.position.y+8,24,a.size.y-16),surface_color.darkened(0.3))
	if not sign_text.is_empty():draw_string(ThemeDB.fallback_font,Vector2(a.position.x+8,a.end.y-10),sign_text,HORIZONTAL_ALIGNMENT_LEFT,a.size.x-16,13,Color("f1e1b3"))
