extends RefCounted
const F := preload("res://tests/station_fixture.gd")
const ARC := preload("res://tests/archetype_fixture.gd")
static func freeze(main: Node) -> void:
	for z in main.get_node("Zombies").get_children(): z.set_physics_process(false)
static func enter(tree: SceneTree) -> bool:
	var success := await preload("res://tests/perimeter_fixture.gd").enter(tree)
	freeze(tree.current_scene)
	F.finish_radio(tree.current_scene)
	return success
static func point(tree: SceneTree, name: String, finish := true) -> void:
	var main := tree.current_scene
	await F.interact(tree,main,main.get_node("World/ChapterPoints/"+name).position+Vector2(0,30))
	if finish: F.finish_radio(main)
static func to_final(tree: SceneTree) -> void:
	for name in ["Checkpoint","Register","Authorization","BusInspection","EvacuationVehicle",
		"DestinationLog","MedicalInspection","QuarantineLog","SafetyInspection","Comms","TransferOrder"]:
		await point(tree,name)
	await point(tree,"RadioLink",false)
