extends Node2D

@onready var static_camera = $StaticCamera
@onready var final_camera = $FinalCamera
@onready var player = $player
@onready var bottom_dialogue = $BottomDialogue
# Asumsi kamu punya InvisibleWalls, kalau tidak ada baris ini bisa dihapus
@onready var invisible_walls = $InvisibleWalls 
@onready var press_any_key = $PressAnyKey

# Variabel untuk mengecek apakah cutscene sudah benar-benar selesai
var is_cutscene_finished = false

func _ready():
	# Pastikan teks "Press Any Key" tersembunyi saat mulai
	if press_any_key:
		press_any_key.visible = false

func _on_cutscene_trigger_body_entered(body):
	if body == player:
		# --- 1. SETUP KAMERA ---
		var player_cam = player.get_node_or_null("Camera2D")
		
		if player_cam:
			var start_pos = player_cam.global_position
			
			# Lepas kamera dari player
			player_cam.top_level = true
			player_cam.global_position = start_pos
			
			if player_cam.position_smoothing_enabled:
				player_cam.position_smoothing_enabled = false
			
			# Tween ke posisi Static Camera (Sensei)
			var tween = create_tween()
			tween.set_trans(Tween.TRANS_SINE)
			tween.set_ease(Tween.EASE_IN_OUT)
			
			tween.tween_property(player_cam, "global_position", static_camera.global_position, 1.5)
			tween.parallel().tween_property(player_cam, "zoom", static_camera.zoom, 1.5)
		
		# --- 2. PERBAIKAN LOGIKA PHYSICS (ANTI MELAYANG) ---
		
		# Cek: Apakah player sedang di udara?
		if not player.is_on_floor():
			# Loop tunggu sampai kaki nyentuh tanah
			while not player.is_on_floor():
				if "velocity" in player:
					player.velocity.x = 0
				
				# PERBAIKAN: Gunakan physics_frame agar sinkron dengan collision check
				await get_tree().physics_frame
		
		# --- SETELAH MENDARAT ---
		
		# Pastikan berhenti total
		if "velocity" in player:
			player.velocity = Vector2.ZERO
			
		# Matikan physics
		player.set_physics_process(false)
		
		# Mainkan animasi Idle
		if player.has_node("AnimatedSprite2D"):
			player.get_node("AnimatedSprite2D").play("idle")
		
		# Nyalakan Invisible Walls
		if invisible_walls:
			invisible_walls.process_mode = Node.PROCESS_MODE_INHERIT
		
		# --- 3. MULAI DIALOG ---
		
		# Tunggu Tween kamera selesai
		await get_tree().create_timer(1.6).timeout
		
		# Data Dialog
		var dialog_data = [
			{"name": "Sensei", "text": "Lihatlah ke belakang. Rintangan yang dulu tampak mustahil, kini hanya menjadi jejak langkahmu."},
			{"name": "Cat", "text": "Semua berkat teknik yang Sensei ajarkan. Aku akhirnya berhasil melampauimu di rintangan terakhir ini."},
			{"name": "Sensei", "text": "Kau tidak hanya melampauiku. Kau telah menyempurnakan setiap gerakan yang kuajarkan. Tidak ada lagi yang tersisa untuk kuajarkan."},
			{"name": "Cat", "text": "Lalu, ke mana arah selanjutnya? Skill apa lagi yang menantiku di depan? Aku siap untuk stage berikutnya."},
			{"name": "Sensei", "text": "Tidak ada stage selanjutnya. Tugas seorang pemandu berakhir saat sang murid sudah mampu berdiri sendiri."},
			{"name": "Cat", "text": "Jadi... mulai sekarang aku tidak lagi mengejar bayanganmu?"},
			{"name": "Sensei", "text": "Benar. Sekarang giliranmu untuk menentukan garis finish-mu sendiri. Pergilah, tunjukkan jalan baru yang belum pernah kulihat."},
			{"name": "Cat", "text": "Saya mengerti. Terima kasih atas bimbingannya selama ini... Sensei."}
		]
		
		# Jalankan Dialog
		bottom_dialogue.start_dialogue(dialog_data)

# Fungsi ini dipanggil otomatis saat sinyal 'dialogue_finished' terpancar
func _on_bottom_dialogue_dialogue_finished() -> void:
	print("Dialog selesai, kamera pindah ke final spot...")
	
	var player_cam = player.get_node_or_null("Camera2D")
	
	if player_cam:
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_SINE)
		tween.set_ease(Tween.EASE_IN_OUT)
		
		var duration = 2.0
		
		# 1. Pindah Posisi ke Final Camera
		tween.tween_property(player_cam, "global_position", final_camera.global_position, duration)
		
		# 2. Pindah Zoom
		tween.parallel().tween_property(player_cam, "zoom", final_camera.zoom, duration)
		
		# Tunggu tween selesai
		await tween.finished
		
		print("Cutscene Tamat. Menunggu input player...")
		
		# Tampilkan teks "Press Any Key"
		_show_press_any_key()
		
		# PERBAIKAN: Aktifkan flag agar input keyboard bisa dibaca
		is_cutscene_finished = true

# --- PERBAIKAN: INPUT HANDLING TERPISAH ---
func _input(event):
	# Hanya jalankan jika cutscene sudah selesai DAN tombol ditekan
	if is_cutscene_finished:
		if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
			# Mencegah input ganda (spam tombol)
			is_cutscene_finished = false 
			_go_to_main_menu()

func _show_press_any_key():
	if press_any_key:
		press_any_key.visible = true
		press_any_key.modulate.a = 0
		
		# Animasi blinking "Press Any Key"
		var tween = create_tween().set_loops()
		tween.tween_property(press_any_key, "modulate:a", 1.0, 0.7)
		tween.tween_property(press_any_key, "modulate:a", 0.3, 0.7)

func _go_to_main_menu():
	print("Pindah ke Main Menu")
	# Fade out
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	
	# Tunggu tween selesai baru pindah scene
	await tween.finished
	get_tree().change_scene_to_file("res://Jesril/UI/UI-Scene/ui120/Mainmenu2.tscn")
