extends RefCounted
const FRAMES:=preload("res://tests/archetype_fixture.gd")
static func interact(tree: SceneTree, main: Node, position: Vector2) -> void:
	preload("res://tests/save_fixture.gd").close_windows(main)
	main.get_node("Player").position=position
	await FRAMES.frames(tree,2)
	main.get_node("Player/Interaction").try_interact()
	await FRAMES.frames(tree,2)
static func finish_radio(main: Node) -> void:
	while main.get_node("Radio").transmission!=null:main.get_node("Radio").advance()
static func complete_market(tree: SceneTree, main: Node) -> void:
	# Preparación aislada: el recorrido --station del capítulo 2 prueba historia
	# completa con locomoción. Aquí se acelera el acceso para probar el mapa/IA.
	await FRAMES.enter_market(tree,main)
	for p in [Vector2(580,890),Vector2(600,960),Vector2(530,1215)]:await interact(tree,main,p)
	preload("res://tests/save_fixture.gd").close_windows(main)
	FRAMES.by_type(main,"runner").health.take_damage(500)
	FRAMES.by_type(main,"resistant").health.take_damage(500)
	for name in ["Stall","Evacuation","Record","Comms","Power","Repeater"]:
		var point: Node=main.get_node("World/ChapterPoints/"+name)
		await interact(tree,main,point.position+Vector2(0,30))
		finish_radio(main)
	await FRAMES.frames(tree,2)
static func travel(tree: SceneTree, destination: String, entry: String) -> bool:
	var manager:=tree.current_scene.get_node("ZoneManager")
	if not manager.request_travel(destination,entry):return false
	await manager.transition_finished
	await FRAMES.frames(tree,3)
	return true
static func enter(tree: SceneTree) -> bool:
	await complete_market(tree,tree.current_scene)
	return await travel(tree,ZoneCatalog.STATION,"from_market")
