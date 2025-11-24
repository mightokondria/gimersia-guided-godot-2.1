extends CharacterBody2D

# Kita HAPUS variabel "ReplayManager" di sini agar tidak bentrok (shadowing)
# Ganti dengan nama variabel khusus untuk script ini:
var _active_manager = null 

var playback_data = []
var time_per_frame = 1.0 / 60.0
var accumulator = 0.0
var is_playing = false
var current_frame_index = 0

@onready var animated_sprite = $AnimatedSprite2D 

func _ready():
	print("[GHOST] Sedang mencari ReplayManager...")
	
	# 1. Cari Node Global dengan aman
	# Kita simpan referensinya ke variabel '_active_manager', BUKAN 'ReplayManager'
	if has_node("/root/ReplayManager"):
		_active_manager = get_node("/root/ReplayManager")
		print("[GHOST] ✅ ReplayManager ditemukan!")
	elif Engine.has_singleton("ReplayManager"):
		_active_manager = Engine.get_singleton("ReplayManager")
		print("[GHOST] ✅ ReplayManager (Singleton) ditemukan!")
	else:
		push_error("[GHOST] ❌ FATAL: ReplayManager tidak ketemu di mana-mana.")
		return 

	# 2. Hubungkan Sinyal (Signal)
	# Pastikan kita menggunakan variabel _active_manager
	if _active_manager:
		if not _active_manager.replay_data_loaded.is_connected(_on_replay_data_loaded):
			_active_manager.replay_data_loaded.connect(_on_replay_data_loaded)
			print("[GHOST] Siap menunggu sinyal 'start_playback'...")
		
	# Setup visual awal
	visible = true 
	modulate = Color(1, 1, 1, 0.6) # Buat hantu agak transparan (60% opacity)

# Fungsi ini dipanggil otomatis saat tombol Playback ditekan
func _on_replay_data_loaded(data):
	playback_data = data
	is_playing = true
	visible = true
	current_frame_index = 0 # Reset index frame
	
	print("[GHOST] ▶️ Playback dimulai! Jumlah frame: ", data.size())
	
	if data.size() > 0:
		# Set posisi awal langsung agar tidak 'teleport' aneh
		global_position = Vector2(data[0].p[0], data[0].p[1])
		animated_sprite.flip_h = data[0].f

func _process(delta):
	# Jika tidak ada manager atau tidak sedang main, stop.
	if not is_playing or playback_data.is_empty() or not _active_manager:
		return

	accumulator += delta
	
	# Loop untuk menjaga kecepatan 60 FPS (sinkronisasi waktu)
	while accumulator >= time_per_frame:
		
		# Minta frame data dari manager menggunakan fungsi khusus
		# Atau kita bisa akses array lokal langsung agar lebih cepat:
		if current_frame_index < playback_data.size():
			var frame_data = playback_data[current_frame_index]
			
			# 1. Update Posisi
			global_position = Vector2(frame_data.p[0], frame_data.p[1]) 
			
			# 2. Update Flip (Kiri/Kanan)
			animated_sprite.flip_h = frame_data.f
			
			# 3. Update Animasi
			if "a" in frame_data:
				if animated_sprite.animation != frame_data.a:
					animated_sprite.play(frame_data.a)
				if "i" in frame_data:
					animated_sprite.frame = frame_data.i
			
			current_frame_index += 1
			accumulator -= time_per_frame
		else:
			print("[GHOST] ⏹️ Playback Selesai.")
			is_playing = false
			# Opsional: visible = false jika ingin hantu hilang setelah selesai
			break
