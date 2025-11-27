extends Node2D

var bgm_gameplay = preload("res://Audio/BGM/outdoor_background_music_final.mp3")

@onready var static_camera = $StaticCamera
@onready var final_camera = $FinalCamera
@onready var player = $player
@onready var bottom_dialogue = $BottomDialogue
# Asumsi kamu punya InvisibleWalls, kalau tidak ada baris ini bisa dihapus
@onready var invisible_walls = $InvisibleWalls 


func _ready():
	AudioManager.play_music(bgm_gameplay)

func _on_cutscene_trigger_body_entered(body):
	if body == player:
		# --- 1. SETUP KAMERA (Jalan duluan tidak masalah) ---
		var player_cam = player.get_node_or_null("Camera2D")
		
		if player_cam:
			var start_pos = player_cam.global_position
			var start_zoom = player_cam.zoom
			
			# Lepas kamera dari player
			player_cam.top_level = true
			player_cam.global_position = start_pos
			
			if player_cam.position_smoothing_enabled:
				player_cam.position_smoothing_enabled = false
			
			# Tween ke posisi Static Camera (Sensei)
			var tween = create_tween()
			tween.set_trans(Tween.TRANS_SINE)
			tween.set_ease(Tween.EASE_IN_OUT)
			
			tween.tween_property(
				player_cam, 
				"global_position", 
				static_camera.global_position, 
				1.5
			)
			tween.parallel().tween_property(
				player_cam,
				"zoom",
				static_camera.zoom,
				1.5
			)
		
		# --- 2. PERBAIKAN LOGIKA PHYSICS (ANTI MELAYANG) ---
		
		# Cek: Apakah player sedang di udara?
		if not player.is_on_floor():
			# Loop tunggu sampai kaki nyentuh tanah
			while not player.is_on_floor():
				# Opsional: Paksa velocity X jadi 0 biar dia jatuh lurus ke bawah (gak bisa gerak kiri/kanan pas jatuh)
				if "velocity" in player:
					player.velocity.x = 0
				
				# Tunggu 1 frame, biarkan gravitasi di script player tetap jalan
				await get_tree().process_frame
		
		# --- SETELAH MENDARAT ---
		
		# Pastikan berhenti total biar gak 'ngesot'
		if "velocity" in player:
			player.velocity = Vector2.ZERO
			
		# BARU SEKARANG aman dimatikan physics-nya
		player.set_physics_process(false)
		
		# Mainkan animasi Idle
		# Pastikan nama node animasinya benar (AnimatedSprite2D)
		if player.has_node("AnimatedSprite2D"):
			player.get_node("AnimatedSprite2D").play("idle")
		
		# (Opsional) Nyalakan Invisible Walls jika pakai metode kandang
		if invisible_walls:
			invisible_walls.process_mode = Node.PROCESS_MODE_INHERIT
		
		# --- 3. MULAI DIALOG ---
		
		# Tunggu Tween kamera selesai (1.5 detik) + buffer dikit (0.1 detik)
		await get_tree().create_timer(1.6).timeout
		
		# Data Dialog
		var dialog_data = [
	{
		"name": "Cat",
		"text": "Sensei, Aku sudah menajamkan cakarku, tapi aku tidak melihat satu pun musuh di sini."
	},
	{
		"name": "Sensei",
		"text": "Simpan cakarmu. Di jalan yang akan kita tempuh, kekerasan tidak akan menyelamatkanmu."
	},
	{
		"name": "Cat",
		"text": "Kalau tidak ada musuh, lalu apa gunanya latihan ini? Apa yang harus kukalahkan?"
	},
	{
		"name": "Sensei",
		"text": "Kau akan mengalahkan keterbatasanmu sendiri. Dinding yang tinggi, jurang yang lebar, dan rasa takutmu untuk melompat."
	},
	{
		"name": "Cat",
		"text": "Hanya melompat dan lari? Terdengar mudah."
	},
	{
		"name": "Sensei",
		"text": "Mudah diucapkan, sulit dilakukan. Di luar pintu dojo ini, dunia tidak akan menunggumu."
	},
	{
		"name": "Sensei",
		"text": "Aku akan memandu jalan di depan. Tugasmu hanya satu: Ikuti gerakanku, dan jangan pernah berhenti."
	},
	{
		"name": "Cat",
		"text": "Baiklah. Tunjukkan jalannya, Sensei."
	}
]     
		
		# Jalankan Dialog
		bottom_dialogue.start_dialogue(dialog_data)

# Fungsi ini dipanggil otomatis saat sinyal 'dialogue_finished' terpancar dari script BottomDialogue

func _on_bottom_dialogue_dialogue_finished() -> void:
	print("Dialog selesai, kamera pindah ke final spot...")
		# Contoh logika pindah scene:
	get_tree().change_scene_to_file("res://Scenes/Stages-real/tutorial_real.tscn")
