extends Node
# Autoload: ReplayManager

# Path dasar. Nanti jadinya: "user://replay_NamaScene.json"
const BASE_PATH = "user://replay_" 
const EXTENSION = ".json"

var current_replay_id = "default" 

var recorded_data = []
var is_recording = false
var is_playing = false
var current_frame = 0
var playback_data = []

signal replay_data_loaded(data)

# --- HELPER PATH ---
func get_file_path(id: String) -> String:
	# Membersihkan karakter aneh jika ada, biar aman untuk nama file
	var clean_id = id.replace(" ", "_").replace(".", "")
	return BASE_PATH + clean_id + EXTENSION

func set_replay_id(id: String):
	current_replay_id = id
	print("ReplayManager: Target ID diatur ke -> ", current_replay_id)

# --- FUNGSI REKAM ---

func start_recording(specific_id: String = ""):
	if specific_id != "":
		set_replay_id(specific_id)
		
	recorded_data.clear()
	is_recording = true
	print("ReplayManager: Merekam data untuk [", current_replay_id, "]...")

func record_frame(position: Vector2, flip_h: bool, anim_name: String, frame_idx: int):
	if is_recording:
		var frame = {
			"p": [position.x, position.y],
			"f": flip_h,
			"a": anim_name,
			"i": frame_idx
		}
		recorded_data.append(frame)

func stop_recording():
	is_recording = false
	print("ReplayManager: Stop rekam. Total frame: ", recorded_data.size())

# --- FUNGSI SAVE (DINAMIS) ---

func save_replay_to_disk():
	if recorded_data.is_empty():
		print("ReplayManager: Data kosong, batal simpan.")
		return false
		
	stop_recording()
	
	# Simpan sesuai ID saat ini
	var path = get_file_path(current_replay_id)
	
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(recorded_data)
		file.store_string(json_string)
		print("ReplayManager: SUKSES simpan ke ", path)
		return true
	else:
		push_error("ReplayManager: Gagal tulis file ke ", path)
		return false

# --- FUNGSI LOAD (DINAMIS) ---

func load_replay_from_disk(specific_id: String = "") -> bool:
	var id_to_load = current_replay_id
	if specific_id != "":
		id_to_load = specific_id
		
	var path = get_file_path(id_to_load)
	
	if not FileAccess.file_exists(path):
		print("ReplayManager: File replay tidak ditemukan: ", path)
		return false

	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		var parsed_data = JSON.parse_string(json_string)
		
		if parsed_data is Array:
			playback_data = parsed_data
			# Update current ID agar sinkron
			current_replay_id = id_to_load
			print("ReplayManager: Data [", id_to_load, "] dimuat. Size: ", playback_data.size())
			return true
	return false

# --- FUNGSI PLAYBACK ---

func start_playback(specific_id: String = ""):
	# Jika ID spesifik diminta, load dulu file-nya
	if specific_id != "":
		load_replay_from_disk(specific_id)
	
	if playback_data.is_empty():
		# Coba load ID default kalau kosong
		if not load_replay_from_disk():
			print("ReplayManager: Gagal playback, data kosong.")
			return

	current_frame = 0
	is_playing = true
	print("ReplayManager: Playback [", current_replay_id, "] dimulai...")
	
	emit_signal("replay_data_loaded", playback_data)

func get_next_frame():
	if not is_playing or current_frame >= playback_data.size():
		stop_playback()
		return null

	var frame_data = playback_data[current_frame]
	current_frame += 1
	return frame_data

func stop_playback():
	is_playing = false
	current_frame = 0
	print("ReplayManager: Playback selesai.")

# --- HELPER RESET ---

func clear_recorded_data():
	recorded_data.clear()
	is_recording = false

func delete_replay_file(specific_id: String = ""):
	var id_to_del = current_replay_id if specific_id == "" else specific_id
	var path = get_file_path(id_to_del)
	
	# FIX: Menggunakan DirAccess.remove_absolute() yang benar untuk Godot 4
	if FileAccess.file_exists(path):
		var err = DirAccess.remove_absolute(path)
		if err == OK:
			print("ReplayManager: File dihapus -> ", path)
		else:
			print("ReplayManager: Gagal menghapus file (Error code: ", err, ")")
	else:
		print("ReplayManager: File tidak ditemukan, tidak ada yang dihapus -> ", path)
