# level_controller.gd (attach ke root scene test-level)
extends Node2D

var after_image_container: Node = null
@export var StartPosition: Marker2D 
@export var player: CharacterBody2D

var entered = false

func _ready():
# Opsional: Tunggu sebentar biar loading scene mulus
	await get_tree().create_timer(0.5).timeout
	
	# Panggil fungsi playback dari Autoload
	if ReplayManager:
		ReplayManager.start_playback()
	
	# register level nodes ke GameManager (autoload)
	if Engine.has_singleton("GameManager") or has_node("/root/GameManager"):
		GameManager.register_level(self)
		
	## 1) place player at spawn (if player is child of this level)
	#if player and StartPosition:
		#player.global_position = StartPosition.global_position
		#print("Level: moved player to StartPosition", StartPosition.global_position)
	#else:
		#print("Level: StartPosition or player not found; check node names")
