extends Control
## Presentación dibujada en Godot: asfalto, silueta urbana y una señal de radio.
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("14171c"))
	var scale:=size/Vector2(1280,720)
	for i in range(12):
		var x: float=(i*123-25)*scale.x
		var height: float=(130+(i*47)%170)*scale.y
		draw_rect(Rect2(x,size.y-height,100*scale.x,height),Color("1c2128"))
		for y in range(3):draw_rect(Rect2(x+18*scale.x,size.y-height+(26+y*38)*scale.y,9*scale.x,14*scale.y),Color("343433"))
	draw_polygon(PackedVector2Array([Vector2(470,720)*scale,Vector2(675,380)*scale,Vector2(765,380)*scale,Vector2(1070,720)*scale]),PackedColorArray([Color("22262b")]))
	for i in range(5):
		var y: float=(465+i*60)*scale.y
		draw_line(Vector2(720*scale.x,y),Vector2(733*scale.x,y+25*scale.y),Color("8d7651"),3)
	var origin:=Vector2(690,180)*scale
	draw_line(origin+Vector2(0,80)*scale,origin+Vector2(0,200)*scale,Color("52606c"),3)
	for radius in [55,90,125]:draw_arc(origin,radius*scale.x,-0.9,0.9,40,Color("bda06e",0.13),2)
	for y in range(0,int(size.y),6):draw_line(Vector2(0,y),Vector2(size.x,y),Color(0,0,0,0.055),1)
