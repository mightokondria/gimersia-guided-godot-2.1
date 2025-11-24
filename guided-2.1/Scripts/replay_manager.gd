extends Node
# File ini harus diatur sebagai Autoload (Singleton)

const SAVE_PATH = "user://player_replay.json"

var recorded_data = []
var is_recording = false
var is_playing = false
var current_frame = 0
var playback_speed = 1.0
var playback_data = []

# Sinyal untuk memberitahu Ghost Player bahwa ada data baru
signal replay_data_loaded(data)

# --- FUNGSI REKAM (RECORDING) ---

func start_recording():
	recorded_data.clear()
	is_recording = true
	print("ReplayManager: Merekam pergerakan dimulai...")

func record_frame(position: Vector2, flip_h: bool):
	if is_recording:
		var frame = {
			"p": [position.x, position.y], # Posisi (X, Y)
			"f": flip_h                  # Flip Horizontal
			}
		recorded_data.append(frame)

func stop_recording():
	is_recording = false
	print("ReplayManager: Merekam selesai. Total frame: ", recorded_data.size())

# --- FUNGSI PENYIMPANAN KE DISK ---

func save_replay_to_disk():
	if recorded_data.is_empty():
		print("ReplayManager: Tidak ada data untuk disimpan.")
		return false
		
	stop_recording()
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(recorded_data)
		file.store_string(json_string)
		print("ReplayManager: Data replay berhasil disimpan di ", SAVE_PATH)
		return true
	else:
		push_error("ReplayManager: Gagal menyimpan file ke ", SAVE_PATH)
		return false

# --- FUNGSI MEMUAT DARI DISK ---

func load_replay_from_disk() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		print("ReplayManager: File replay tidak ditemukan di ", SAVE_PATH)
		return false

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		var parsed_data = JSON.parse_string(json_string)
		
		if parsed_data is Array:
			playback_data = parsed_data
			print("ReplayManager: Data replay berhasil dimuat. Total frame: ", playback_data.size())
			return true
		else:
			push_error("ReplayManager: Gagal mem-parse JSON.")
			return false
	else:
		push_error("ReplayManager: Gagal memuat file.")
		return false

# --- FUNGSI PUTAR ULANG (PLAYBACK) ---

func start_playback():
	if playback_data.is_empty():
		if not load_replay_from_disk():
			print("ReplayManager: Gagal memulai playback karena tidak ada data.")
			return

	current_frame = 0
	is_playing = true
	print("ReplayManager: Memulai playback...")
	
	# Kirim sinyal ke GhostPlayer untuk mengaktifkan dirinya
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
