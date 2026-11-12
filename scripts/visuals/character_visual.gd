extends Node2D
## Solo presentación: observa velocidad/estado y salud. No escribe gameplay.
@export var sheet: Texture2D
## Biblioteca opcional de arte final; respeta nombres estado_dirección.
@export var animation_library: SpriteFrames
@export var library_scale: Vector2 = Vector2(0.4, 0.4)
@export var library_offset: Vector2 = Vector2(0, -56)
@export var rotate_library_with_actor: bool = false
@export var is_zombie: bool = false
@export var effects_enabled: bool = true
@onready var actor: CharacterBody2D = get_parent()
@onready var sprite: AnimatedSprite2D = $Sprite
var health: HealthComponent
var last_health: float
var flash_remaining: float = 0.0
var direction_name: String = "down"
var dead: bool = false
var fallback_scale: Vector2
var fallback_offset: Vector2
var barrel: Sprite2D
var fallback_barrel_position: Vector2
var last_mouse_position: Vector2
var movement_facing: Vector2 = Vector2.DOWN
var has_moved: bool = false

func _ready() -> void:
	fallback_scale = sprite.scale
	fallback_offset = sprite.offset
	barrel = actor.get_node_or_null("Aim/Barrel") as Sprite2D
	if barrel != null:
		fallback_barrel_position = barrel.position
	health = actor.get_node("HealthComponent") as HealthComponent
	last_health = health.max_health
	health.health_changed.connect(_on_health_changed)
	health.died.connect(_on_death)
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for state_name in ["idle", "walk", "attack", "death"]:
		var indexes: Array
		match state_name:
			"idle": indexes = [0, 1]
			"walk": indexes = [2, 3, 4, 5]
			"attack": indexes = [6, 7]
			_: indexes = [8, 9, 10, 11]
		for facing in ["down", "up", "left", "right"]:
			var animation_name := StringName(state_name + "_" + facing)
			frames.add_animation(animation_name)
			frames.set_animation_loop(animation_name, state_name != "death")
			frames.set_animation_speed(animation_name, 2.0 if state_name == "idle" else 10.0)
			for index: int in indexes:
				var texture := AtlasTexture.new()
				texture.atlas = sheet
				texture.region = Rect2(index * 64, 0, 64, 64)
				frames.add_frame(animation_name, texture)
	# Sobrescribir solo animaciones disponibles, conservando el atlas existente.
	if animation_library != null:
		for animation_name in animation_library.get_animation_names():
			if animation_library.get_frame_count(animation_name) == 0:
				continue
			if frames.has_animation(animation_name):
				frames.remove_animation(animation_name)
			frames.add_animation(animation_name)
			frames.set_animation_loop(animation_name, animation_library.get_animation_loop(animation_name))
			frames.set_animation_speed(animation_name, animation_library.get_animation_speed(animation_name))
			for index in range(animation_library.get_frame_count(animation_name)):
				frames.add_frame(animation_name, animation_library.get_frame_texture(animation_name, index),
					animation_library.get_frame_duration(animation_name, index))
	sprite.sprite_frames = frames
	sprite.play("idle_down")
	_update_sprite_transform()

func _update_sprite_transform() -> void:
	var uses_library := animation_library != null and animation_library.has_animation(sprite.animation) \
		and animation_library.get_frame_count(sprite.animation) > 0
	sprite.scale = library_scale if uses_library else fallback_scale
	sprite.offset = library_offset if uses_library else fallback_offset
	if uses_library and not rotate_library_with_actor:
		rotation = 0.0
	if barrel != null:
		# Solo desplaza el dibujo a la mano; Aim y el origen físico no cambian.
		barrel.position = Vector2(9, -18).rotated(-actor.get_node("Aim").rotation) \
			if uses_library and not rotate_library_with_actor else fallback_barrel_position

func _on_health_changed(current: float, _maximum: float) -> void:
	if current < last_health and effects_enabled:
		flash_remaining = 0.18
	last_health = current

func _on_death() -> void:
	dead = true
	sprite.play("death_" + direction_name)
	# Restablecer la orientación del atlas provisional al salir de un idle fijo.
	if not is_zombie:
		rotation = actor.get_node("Aim").rotation - PI / 2.0
	_update_sprite_transform()
	var aim := actor.get_node_or_null("Aim") as Node2D
	if aim != null:
		aim.hide()

func _process(delta: float) -> void:
	flash_remaining = maxf(0.0, flash_remaining - delta)
	sprite.modulate = Color(2.0, 0.65, 0.5) if flash_remaining > 0.0 else Color.WHITE
	if dead:
		return
	var direction := actor.velocity
	if not is_zombie:
		var aim_angle: float = actor.get_node("Aim").rotation
		var mouse_position := get_viewport().get_mouse_position()
		if actor.velocity.length_squared() > 1.0:
			direction = actor.velocity
			movement_facing = direction
			has_moved = true
		elif not has_moved or not mouse_position.is_equal_approx(last_mouse_position):
			direction = Vector2.RIGHT.rotated(aim_angle)
			movement_facing = direction
		else:
			direction = movement_facing
		last_mouse_position = mouse_position
	elif is_instance_valid(actor.get("target")) and actor.get("state") == 2:
		direction = actor.global_position.direction_to(actor.get("target").global_position)
	if not direction.is_zero_approx():
		rotation = direction.angle() - PI / 2.0
		if absf(direction.x) > absf(direction.y):
			direction_name = "right" if direction.x > 0.0 else "left"
		else:
			direction_name = "down" if direction.y > 0.0 else "up"
	var state_name := "walk" if actor.velocity.length_squared() > 1.0 else "idle"
	if is_zombie and actor.get("state") == 2:
		state_name = "attack"
	var animation_name := state_name + "_" + direction_name
	if sprite.animation != animation_name:
		sprite.play(animation_name)
	_update_sprite_transform()
