extends Node2D

@export var StartPosition: Marker2D 
@export var player: CharacterBody2D

# Variabel 'after_image_container' tidak perlu dideklarasikan di sini 
# karena GameManager mencarinya langsung di tree sebagai child node.

func _ready():
	# 1. Register Level ke GameManager
	if GameManager:
		# DEBUG: Cek manual apakah node container ada sebelum lapor ke GameManager
		if has_node("AfterImageContainer"):
			print("✅ Level Controller: Node 'AfterImageContainer' ditemukan. Mendaftarkan ke GameManager...")
			GameManager.register_level(self)
		else:
			push_error("❌ Level Controller: Node 'AfterImageContainer' TIDAK DITEMUKAN di scene ini! Fitur bayangan tidak akan jalan.")
	
	# 2. Replay System (Ghost)
	if ReplayManager:
		# Opsional: Delay sedikit
		# await get_tree().create_timer(0.1).timeout
		ReplayManager.start_playback()
		
	# 3. Teleport Player ke Start Position
	if player and StartPosition:
		player.global_position = StartPosition.global_position
		print("Level: moved player to StartPosition", StartPosition.global_position)
	else:
		if not player: print("⚠️ Level: Player belum di-assign di Inspector.")
		if not StartPosition: print("⚠️ Level: StartPosition belum di-assign di Inspector.")


func _on_child_entered_tree(node: Node) -> void:
	pass # Replace with function body.
