extends Node2D

@export var StartPosition: Marker2D 
@export var player: CharacterBody2D

# --- SOLUSI 2: VARIABLE CUSTOM ---
# Variabel ini akan muncul di Inspector.
# Isi ini jika Anda malas me-rename Root Node setiap kali bikin level.
# Contoh isi: "BossFight_01" -> file: "replay_BossFight_01.json"
@export var custom_replay_id: String = "" 
# ---------------------------------

func _ready():
	# 1. Register Level (Wajib untuk fitur After Image & Spike)
	if GameManager and has_node("AfterImageContainer"):
		GameManager.register_level(self)

	# 2. START PLAYBACK GHOST
	if ReplayManager:
		# Opsional: Tunggu sebentar agar scene stabil
		await get_tree().create_timer(0.1).timeout
		
		# --- LOGIKA PEMILIHAN ID ---
		# Default: Gunakan nama node ini (misal "Node2D" atau "Level1")
		var id_to_use = self.name 
		
		# Cek Prioritas 1: Apakah Custom ID diisi di Inspector?
		if custom_replay_id != "":
			id_to_use = custom_replay_id
			print("Level: Menggunakan Custom ID -> ", id_to_use)
			
		# Cek Prioritas 2: Jika tidak diisi, dan ini adalah scene utama, pakai nama file scene
		elif get_tree().current_scene == self:
			id_to_use = get_tree().current_scene.name
			
		print("Level: Meminta Ghost untuk ID [", id_to_use, "]...")
		ReplayManager.start_playback(id_to_use)
	
	# 3. Teleport Player ke Start Position
	if player and StartPosition:
		player.global_position = StartPosition.global_position
		print("Level: moved player to StartPosition", StartPosition.global_position)
	else:
		if not player: print("⚠️ Level: Player belum di-assign di Inspector.")
		if not StartPosition: print("⚠️ Level: StartPosition belum di-assign di Inspector.")
