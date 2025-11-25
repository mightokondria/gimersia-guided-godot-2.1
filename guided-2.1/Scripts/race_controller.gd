extends Node2D

# --- KONFIGURASI NODE (Drag & Drop dari Scene Tree ke Inspector) ---
@export_group("Required Nodes")
@export var StartPosition: Marker2D       # Posisi awal Player
@export var player: CharacterBody2D       # Node Player Asli
@export var FinishArea: Area2D            # Area Garis Finish (Opsional untuk deteksi jarak)
@export var CountdownLabel: Label         # Label UI untuk angka 3, 2, 1 (Wajib ada di CanvasLayer)

@export_group("Replay Settings")
@export var custom_replay_id: String = "" # Isi manual jika ingin memaksa load file tertentu (misal "BossFight")

# --- VARIABEL INTERNAL ---
var _race_started = false
var _ghost_finished = false

func _ready():
	print("\n--- LEVEL INIT ---")
	
	# 1. REGISTRASI LEVEL (Agar fitur After Image & Respawn Duri jalan)
	if GameManager:
		if has_node("AfterImageContainer"):
			GameManager.register_level(self)
		else:
			push_warning("Level: Lupa nambahin node 'AfterImageContainer'! Efek bayangan gak bakal muncul.")

	# 2. BEKUKAN PLAYER (Freeze)
	# Kita kunci player biar nggak curi start sebelum hitungan selesai
	if player and player.has_method("freeze"):
		player.freeze()
		print("Level: Player dikunci (Freeze).")
	
	# 3. PERSIAPAN UI COUNTDOWN
	if CountdownLabel:
		CountdownLabel.text = "READY?"
		CountdownLabel.visible = true
	else:
		push_warning("Level: CountdownLabel belum dipasang di Inspector!")

	# 4. LOAD DATA GHOST (TAPI JANGAN JALAN DULU)
	if ReplayManager:
		# Beri jeda sangat singkat agar node GhostPlayer siap menerima sinyal
		await get_tree().create_timer(0.1).timeout
		
		# Tentukan ID mana yang mau di-load
		var id_to_use = self.name # Default: Nama Node Root (misal "Level1")
		
		# Cek override manual
		if custom_replay_id != "":
			id_to_use = custom_replay_id
		# Cek jika ini scene utama
		elif get_tree().current_scene == self:
			id_to_use = get_tree().current_scene.name
			
		print("Level: Meminta Ghost memuat data [", id_to_use, "]...")
		
		# Panggil start_playback. 
		# Ghost akan menerima data tapi DIAM SAJA karena di script ghost_player.gd 
		# variabel 'is_race_started' masih false.
		ReplayManager.start_playback(id_to_use)
		
		# 5. MULAI HITUNG MUNDUR
		start_countdown_sequence()

# --- LOGIKA COUNTDOWN ---
func start_countdown_sequence():
	if not CountdownLabel:
		# Kalau lupa pasang label, langsung gas aja biar gak softlock
		print("Level: Label gak ada, skip countdown.")
		start_race()
		return
		
	# Tunggu 1 detik untuk tulisan "READY?"
	await get_tree().create_timer(1.0).timeout
	
	# Hitung Mundur
	CountdownLabel.text = "3"
	# Suara beep bisa ditaruh di sini (misal: AudioStreamPlayer.play())
	await get_tree().create_timer(1.0).timeout
	
	CountdownLabel.text = "2"
	await get_tree().create_timer(1.0).timeout
	
	CountdownLabel.text = "1"
	await get_tree().create_timer(1.0).timeout
	
	CountdownLabel.text = "GO!"
	# Modulate warna jadi hijau biar seru
	CountdownLabel.modulate = Color.GREEN
	
	# MULAI BALAPAN!
	start_race()
	
	# Hilangkan tulisan GO setelah 1 detik
	await get_tree().create_timer(1.0).timeout
	CountdownLabel.visible = false

# --- LOGIKA START ---
func start_race():
	print(">>> 🏁 BALAPAN DIMULAI! 🏁 <<<")
	_race_started = true
	
	# 1. Lepaskan Player
	if player and player.has_method("unfreeze"):
		player.unfreeze()
		
	# 2. Lepaskan Ghost
	# Kita cari node bernama "GhostPlayer" di scene ini
	var ghost = get_node_or_null("GhostPlayer")
	if ghost:
		if ghost.has_method("start_race"):
			ghost.start_race() # Fungsi ini mengubah is_race_started = true di Ghost
		else:
			push_warning("Level: Node GhostPlayer ditemukan tapi gak punya fungsi start_race(). Cek script ghost!")
	else:
		print("Level: Tidak ada Ghost di scene ini (Mungkin mode latihan sendiri).")

# --- LOGIKA LOOPING (Opsional) ---
func _process(_delta):
	# Deteksi Jarak Manual (Backup jika Collision Area2D gagal mendeteksi Ghost)
	# Ini berguna untuk debugging visual di output console
	if _race_started and not _ghost_finished and FinishArea:
		var ghost = get_node_or_null("GhostPlayer")
		if ghost:
			var distance = ghost.global_position.distance_to(FinishArea.global_position)
			
			# Jika jarak sangat dekat (kurang dari 50 pixel)
			if distance < 50.0:
				print("DEBUG: Ghost berada sangat dekat dengan Finish Area (Jarak: ", distance, ")")
				_ghost_finished = true
