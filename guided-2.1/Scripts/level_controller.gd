# level_controller.gd (attach ke root scene test-level)
extends Node2D

func _ready():
	# register level nodes ke GameManager (autoload)
	if Engine.has_singleton("GameManager") or has_node("/root/GameManager"):
		GameManager.register_level(self)
		# jika player sudah child:
		GameManager.register_player($player)
