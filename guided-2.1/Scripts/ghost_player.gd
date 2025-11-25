extends CharacterBody2D

var _active_manager = null 

var playback_data = []
var time_per_frame = 1.0 / 60.0
var accumulator = 0.0
var is_playing = false
var current_frame_index = 0

# Status Balapan
var is_race_started = false 

@onready var animated_sprite = $AnimatedSprite2D 

func _ready():
	if has_node("/root/ReplayManager"):
		_active_manager = get_node("/root/ReplayManager")
	elif Engine.has_singleton("ReplayManager"):
		_active_manager = Engine.get_singleton("ReplayManager")
	
	if _active_manager:
		if not _active_manager.replay_data_loaded.is_connected(_on_replay_data_loaded):
			_active_manager.replay_data_loaded.connect(_on_replay_data_loaded)
	
	visible = true 
	modulate = Color(1, 1, 1, 0.6) 

	if has_node("CollisionShape2D"):
		$CollisionShape2D.disabled = false 
		collision_layer = 4 
		collision_mask = 0 

func _on_replay_data_loaded(data):
	playback_data = data
	is_playing = true
	visible = true
	current_frame_index = 0
	is_race_started = false 
	
	print("[GHOST] Data dimuat. Menunggu sinyal start_race()...")
	
	if data.size() > 0:
		global_position = Vector2(data[0].p[0], data[0].p[1])
		animated_sprite.flip_h = data[0].f

func start_race():
	is_race_started = true
	print("[GHOST] GASSS! Balapan dimulai.")

# --- FUNGSI BARU: FREEZE ---
func freeze():
	is_race_started = false # Matikan update gerakan
	is_playing = false      # Matikan playback
	print("[GHOST] Dibekukan (Freeze).")
# ---------------------------

func _process(delta):
	if not is_playing or playback_data.is_empty() or not _active_manager or not is_race_started:
		return

	accumulator += delta
	while accumulator >= time_per_frame:
		if current_frame_index < playback_data.size():
			var frame_data = playback_data[current_frame_index]
			global_position = Vector2(frame_data.p[0], frame_data.p[1]) 
			animated_sprite.flip_h = frame_data.f
			if "a" in frame_data:
				if animated_sprite.animation != frame_data.a:
					animated_sprite.play(frame_data.a)
				if "i" in frame_data:
					animated_sprite.frame = frame_data.i
			current_frame_index += 1
			accumulator -= time_per_frame
		else:
			is_playing = false
			break
