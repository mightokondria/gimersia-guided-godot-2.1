extends Node2D

# --- KONFIGURASI ---
@export_group("Required Nodes")
@export var player: CharacterBody2D        
@export var CountdownLabel: Label          
@export var FinishArea: Area2D             

@export_group("Ghost Settings")
# 1. TARIK FILE .JSON DI SINI UNTUK DIMAINKAN GHOST
# 2. DAN FILE INI JUGA YANG AKAN DITIMPA JIKA KAMU TEKAN 'O'
@export_file("*.json") var ghost_source_file: String = ""

# --- VARIABEL INTERNAL ---
var _race_started = false
var _ghost_finished = false
var _replay_index = 0       
var _ghost_node: Node2D = null 
var _replay_data = [] 

func _ready():
	print("\n--- LEVEL INIT (RECORD & PLAY MODE) ---")
	
	# 1. Registrasi Level
	var GM = get_node_or_null("/root/GameManager")
	if GM and has_node("AfterImageContainer"):
		GM.register_level(self)

	# 2. Load Data Ghost (Untuk Playback)
	load_ghost_data_from_file()

	# 3. Setup Node Ghost
	_ghost_node = get_node_or_null("GhostPlayer")
	if _ghost_node:
		# Posisikan di frame awal
		if not _replay_data.is_empty():
			var frame0 = _replay_data[0]
			var p = frame0["p"] 
			_ghost_node.global_position = Vector2(p[0], p[1])
			_ghost_node.modulate.a = 0.5 
	else:
		print("Level: GhostPlayer tidak ditemukan (Mode Solo/Recording).")

	# 4. Freeze Player
	if player and player.has_method("freeze"):
		player.freeze()
	
	# 5. UI Countdown
	start_countdown_sequence()

func _input(event):
	# --- FITUR REKAM DEVELOPER ---
	# Tekan 'O' kapan saja untuk menyimpan rekamam saat ini ke file res://
	if event is InputEventKey and event.pressed and event.keycode == KEY_O:
		save_recording_to_res()

# --- FUNGSI SIMPAN (DEV TOOL) ---
func save_recording_to_res():
	var RM = get_node_or_null("/root/ReplayManager")
	if not RM: 
		print("Error: ReplayManager tidak ada.")
		return
		
	var data = RM.recorded_data
	if data.is_empty():
		print("Level: Data rekaman masih kosong/sedikit.")
		return
		
	# Tentukan path file
	var path = ghost_source_file
	if path == "":
		# Default name jika kosong
		path = "res://replay_" + self.name + ".json"
	
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()
		print(">>> SUKSES! Rekaman disimpan ke: ", path)
		print(">>> PENTING: Klik Kanan Folder -> 'Rescan' agar file muncul/update.")
	else:
		push_error("Gagal menulis file ke " + path)

# --- FUNGSI BACA (PUPPET MASTER) ---
func load_ghost_data_from_file():
	if ghost_source_file != "" and FileAccess.file_exists(ghost_source_file):
		var file = FileAccess.open(ghost_source_file, FileAccess.READ)
		var json = JSON.new()
		if json.parse(file.get_as_text()) == OK:
			_replay_data = json.data
			print("Level: Data Ghost dimuat. Frame count: ", _replay_data.size())
		else:
			print("Level: File JSON rusak/kosong.")
	else:
		print("Level: Tidak ada file ghost yang di-load (Mode Rekam Baru).")

func start_countdown_sequence():
	if CountdownLabel:
		CountdownLabel.text = "READY?"
		CountdownLabel.visible = true
		await get_tree().create_timer(1.0).timeout
		CountdownLabel.text = "3"
		await get_tree().create_timer(1.0).timeout
		CountdownLabel.text = "2"
		await get_tree().create_timer(1.0).timeout
		CountdownLabel.text = "1"
		await get_tree().create_timer(1.0).timeout
		CountdownLabel.text = "GO!"
		CountdownLabel.modulate = Color.GREEN
	
	start_race()
	
	if CountdownLabel:
		await get_tree().create_timer(1.0).timeout
		CountdownLabel.visible = false

func start_race():
	print(">>> 🏁 GO! (Recording Auto-Start) 🏁 <<<")
	_race_started = true
	_replay_index = 0 
	
	if player and player.has_method("unfreeze"):
		player.unfreeze()
		
	# 1. Start Recording Otomatis (PENTING!)
	var RM = get_node_or_null("/root/ReplayManager")
	if RM: RM.start_recording(self.name)

# --- LOGIKA PENGGERAK GHOST ---
func _physics_process(_delta):
	# Playback Ghost (Jika ada data)
	if _race_started and _ghost_node and not _replay_data.is_empty():
		if _replay_index < _replay_data.size():
			var frame = _replay_data[_replay_index]
			var p = frame["p"]
			_ghost_node.global_position = Vector2(p[0], p[1])
			
			var sprite = _ghost_node.get_node_or_null("AnimatedSprite2D")
			if sprite:
				sprite.flip_h = frame["f"]
				var anim = frame["a"]
				if sprite.animation != anim:
					sprite.play(anim)
					sprite.frame = frame["i"]
			
			_replay_index += 1
		elif not _ghost_finished:
			_ghost_finished = true
			print("Level: Ghost Finish.")

	# Cek Finish
	if _race_started and FinishArea and _ghost_node:
		if _ghost_node.global_position.distance_to(FinishArea.global_position) < 50.0 and not _ghost_finished:
			print("DEBUG: Ghost Menyentuh Garis Finish!")
