class_name AudioCatalog
extends Resource
## Banco sustituible en inspector. Los WAV técnicos originales no son audio final.
@export var sounds: Dictionary[StringName, AudioStream] = {
	&"inventory_open": preload("res://assets/placeholders/audio/inventory_open.wav"),
	&"inventory_close": preload("res://assets/placeholders/audio/inventory_close.wav"),
	&"ui_select": preload("res://assets/placeholders/audio/ui_select.wav"),
	&"pickup_supply": preload("res://assets/placeholders/audio/pickup_supply.wav"),
	&"pickup_ammo": preload("res://assets/placeholders/audio/pickup_ammo.wav"),
	&"item_use": preload("res://assets/placeholders/audio/item_use.wav"),
	&"invalid": preload("res://assets/placeholders/audio/invalid.wav"),
	&"container_open": preload("res://assets/placeholders/audio/container_open.wav"),
	&"pistol_shot": preload("res://assets/placeholders/audio/pistol_shot.wav"),
	&"revolver_shot": preload("res://assets/placeholders/audio/revolver_shot.wav"),
	&"shotgun_shot": preload("res://assets/placeholders/audio/shotgun_shot.wav"),
	&"reload": preload("res://assets/placeholders/audio/reload.wav"),
	&"machete_swing": preload("res://assets/placeholders/audio/machete_swing.wav"),
	&"machete_hit": preload("res://assets/placeholders/audio/machete_hit.wav"),
	&"dry_fire": preload("res://assets/placeholders/audio/dry_fire.wav"),
	&"zombie_groan": preload("res://assets/placeholders/audio/zombie_groan.wav"),
	&"zombie_attack": preload("res://assets/placeholders/audio/zombie_attack.wav"),
	&"zombie_hurt": preload("res://assets/placeholders/audio/zombie_hurt.wav"),
	&"zombie_death": preload("res://assets/placeholders/audio/zombie_death.wav"),
	&"ambience": preload("res://assets/placeholders/audio/ambience.wav"),
}
