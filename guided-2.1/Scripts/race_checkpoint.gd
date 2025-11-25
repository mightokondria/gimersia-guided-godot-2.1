extends Area2D

# Tarik node UI Popup "Anda Kalah" ke sini lewat Inspector
@export var lose_popup: Control 

# --- DEBUGGING ---
# Centang ini di Inspector untuk mengaktifkan checkpoint.
# Hilangkan centang jika ingin menonaktifkannya saat debugging.
@export var is_active: bool = true 
# -----------------

var is_cleared = false # Penanda apakah player sudah lewat sini dengan aman
var game_over_triggered = false

func _ready():
	# 1. SEMBUNYIKAN POPUP DI AWAL
	if lose_popup:
		lose_popup.visible = false
	
	# 2. SETUP SINYAL OTOMATIS
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	# Jika checkpoint dinonaktifkan atau game sudah berakhir, abaikan
	if not is_active or game_over_triggered:
		return 

	# 1. JIKA PLAYER MASUK (AMAN)
	if body.is_in_group("player"):
		if not is_cleared:
			is_cleared = true
			print("Checkpoint: Player lolos! Aman.")
			# Ubah warna jadi hijau sebagai tanda visual
			modulate = Color.GREEN

	# 2. JIKA GHOST MASUK (BAHAYA)
	# Cek Layer 3 (Ghost)
	elif body.has_method("get_collision_layer_value") and body.get_collision_layer_value(3):
		# Cek apakah player sudah lewat duluan?
		if is_cleared:
			print("Checkpoint: Ghost lewat (tapi player sudah aman).")
		else:
			# Player belum lewat, tapi Ghost sudah sampai -> KALAH!
			print("Checkpoint: Ghost menang di checkpoint ini! PLAYER KALAH.")
			_trigger_defeat()

func _trigger_defeat():
	game_over_triggered = true
	
	# 1. Hentikan Player (FREEZE)
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("freeze"):
		player.freeze()
		
	# 2. Hentikan Ghost (FREEZE)
	# Kita cari node bernama "GhostPlayer" di scene aktif secara rekursif
	var ghost = get_tree().current_scene.find_child("GhostPlayer", true, false)
	if ghost and ghost.has_method("freeze"):
		ghost.freeze()
	else:
		# Fallback jika find_child gagal, coba cari manual di root scene
		var ghost_manual = get_tree().current_scene.get_node_or_null("GhostPlayer")
		if ghost_manual and ghost_manual.has_method("freeze"):
			ghost_manual.freeze()
	
	# 3. Munculkan Popup "Anda Kalah"
	if lose_popup:
		lose_popup.visible = true
	
	# 4. Tunggu sebentar (2 detik) agar pemain menyadari kekalahan
	await get_tree().create_timer(2.0).timeout
	
	# 5. Pindah ke Scene Kalah MENGGUNAKAN TRANSISI
	# Pastikan TransitionScreen sudah dijadikan Autoload di Project Settings
	if TransitionScreen:
		TransitionScreen.transition_to_scene("res://Scenes/Dialog/player_kalah.tscn")
	else:
		# Fallback manual jika lupa pasang Autoload
		push_warning("RaceCheckpoint: TransitionScreen Autoload tidak ditemukan, pindah scene kasar.")
		get_tree().change_scene_to_file("res://Scenes/Dialog/player_kalah.tscn")
