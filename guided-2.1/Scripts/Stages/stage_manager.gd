extends Node2D

# Referensi node di dalam scene ini
@export var StartPosition: Marker2D 
@export var player: CharacterBody2D

# --- REPLAY SYSTEM CONFIG ---
# Isi ini di Inspector jika ingin ID khusus (misal: "Level_1_Tutorial")
# Jika kosong, akan otomatis pakai nama scene.
@export var custom_replay_id: String = "" 

func _ready():
	# 1. REGISTER LEVEL KE GAMEMANAGER (Sangat Penting!)
	# Ini memberitahu GameManager: "Hei, akulah level yang aktif sekarang.
	# Ambil referensi StartPosition, transition, dll dariku!"
	if has_node("/root/GameManager"):
		GameManager.register_level(self)
	else:
		push_error("StageManager: GameManager Autoload tidak ditemukan!")

	# 2. SETUP START POSITION PLAYER
	# Kita lakukan ini manual di sini sebagai jaminan ganda (selain di GameManager)
	if player and StartPosition:
		player.global_position = StartPosition.global_position
		# Reset velocity agar player tidak 'terbang' jika spawn di udara
		player.velocity = Vector2.ZERO 
		print("StageManager: Player dipindahkan ke StartPosition ->", StartPosition.global_position)
	else:
		if not player: push_warning("StageManager: Player belum di-assign di Inspector.")
		if not StartPosition: push_warning("StageManager: StartPosition belum di-assign di Inspector.")

	# 3. START PLAYBACK GHOST (Replay System)
	# Pastikan ReplayManager ada sebelum memanggilnya
	if has_node("/root/ReplayManager"):
		var ReplayManager = get_node("/root/ReplayManager")
		
		# Beri sedikit jeda agar scene benar-benar siap
		await get_tree().create_timer(0.1).timeout
		
		# --- LOGIKA ID REPLAY ---
		var id_to_use = self.name # Default: Nama node root scene ini
		
		# Prioritas 1: Custom ID dari Inspector
		if custom_replay_id != "":
			id_to_use = custom_replay_id
			
		# Prioritas 2: Nama file scene (jika ini scene utama)
		elif get_tree().current_scene == self:
			# Mengambil nama file scene tanpa path dan ekstensi
			# Contoh: "res://Levels/Level1.tscn" -> "Level1"
			id_to_use = scene_file_path.get_file().get_basename()
			
		print("StageManager: Memulai Ghost Replay untuk ID [", id_to_use, "]")
		
		# Pastikan ReplayManager punya fungsi start_playback
		if ReplayManager.has_method("start_playback"):
			ReplayManager.start_playback(id_to_use)
	else:
		# Info saja, tidak error jika memang replay manager belum dipasang
		# print("StageManager: ReplayManager tidak aktif.")
		pass
