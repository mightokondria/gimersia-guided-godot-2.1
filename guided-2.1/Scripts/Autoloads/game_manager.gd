# GameManager.gd (dipakai sebagai Autoload, Name: GameManager)
extends Node

# Node references (akan diisi via register_level)
var player: Node = null
var start_position: Node2D = null
var transition: Node = null
var after_image_container: Node = null
var is_transitioning: bool = false

var next_spawn_id: String = "" 

# --- SISTEM SKILL (PROGRESI) ---
# Default false: Player mulai tanpa skill
var skill_dash_unlocked: bool = false
var skill_double_jump_unlocked: bool = false
var skill_wall_grab_unlocked: bool = false

# Referensi ke Autoload TransitionScreen (pastikan nama di Project Settings -> Autoloads benar)
# Menggunakan get_node_or_null agar tidak crash jika lupa dipasang
@onready var TransitionScreen: Node = get_node_or_null("/root/TransitionScreen") 

func _ready() -> void:
	print("GameManager (autoload) ready. Waiting for level/player registration...")

# Fungsi untuk membuka skill (dipanggil oleh item/trigger)
func unlock_skill(skill_name: String) -> void:
	match skill_name:
		"dash":
			skill_dash_unlocked = true
			print("GameManager: Dash Unlocked!")
		"double_jump":
			skill_double_jump_unlocked = true
			print("GameManager: Double Jump Unlocked!")
		"wall_grab":
			skill_wall_grab_unlocked = true
			print("GameManager: Wall Grab Unlocked!")

# Panggil dari level root saat level ready (misal di TheStage.gd _ready):
# GameManager.register_level(self)
func register_level(level_root: Node) -> void:
	start_position = level_root.get_node_or_null("StartPosition")
	transition = level_root.get_node_or_null("transition")
	after_image_container = level_root.get_node_or_null("AfterImageContainer")
	
	if not start_position:
		# push_warning("GameManager: StartPosition not found in level_root")
		pass
	
	print("GameManager: level registered from ", level_root.name)

# Panggil dari Player._ready()
# GameManager.register_player(self)
func register_player(p: Node) -> void:
	player = p
	var cb = Callable(self, "_on_player_create_after_image")
	# Hindari koneksi ganda
	if not player.is_connected("create_after_image", cb):
		player.connect("create_after_image", cb)
	print("GameManager: player registered:", player)

func _on_player_create_after_image(texture, spawn_pos, is_flipped) -> void:
	if after_image_container:
		var s = Sprite2D.new()
		s.texture = texture
		s.global_position = spawn_pos
		s.flip_h = is_flipped
		
		s.scale = Vector2(6, 6) # Sesuaikan scale dengan pixel art Anda (jika perlu)
		
		after_image_container.add_child(s)
		s.modulate = Color(0.5,0.7,1,0.7)
		var tw = create_tween()
		tw.tween_property(s, "modulate", Color(0.5,0.7,1,0), 0.4)
		tw.tween_callback(Callable(s, "queue_free"))
	else:
		# Warning ini mungkin muncul saat transisi scene, aman diabaikan sesekali
		# push_warning("GameManager: no after_image_container set") 
		pass

# Fungsi generik untuk ganti scene (tanpa transisi khusus)
func request_change_scene(path: String, spawn_id: String = "") -> void:
	if path == "" or not ResourceLoader.exists(path):
		push_warning("GameManager: invalid path: " + str(path))
		return
		
	next_spawn_id = spawn_id

	# optional: freeze player and stop physics to avoid physics-callback removal issues
	if player:
		if player.has_method("freeze"):
			player.freeze()
		# stop player's physics to be safe
		player.set_physics_process(false)

	# do actual change deferred to avoid "Removing a CollisionObject during physics callback" error
	call_deferred("_do_change_scene", path)

func _do_change_scene(path: String) -> void:
	print("GameManager: changing scene to", path)
	get_tree().change_scene_to_file(path)
	

# FUNGSI BARU: FUNGSI PEMANGGIL TRANISI SAAT MENANG/KALAH
# Dipanggil oleh TheStage.gd atau Checkpoint saat kondisi menang/kalah terpenuhi
func request_change_scene_with_transition(did_player_win: bool, current_stage_id: int = 1) -> void:
	var target_scene: String
	
	if did_player_win:
		target_scene = "res://Scenes/Dialog/player_menang.tscn"
	else:
		target_scene = "res://Scenes/Dialog/player_kalah.tscn"
		
	# 1. Coba pakai variabel @onready (Paling cepat)
	if TransitionScreen and TransitionScreen.has_method("transition_to_scene"):
		TransitionScreen.transition_to_scene(target_scene)
		return

	# 2. Coba cari manual (Fallback jika @onready gagal/null saat init)
	var ts_manual = get_node_or_null("/root/TransitionScreen")
	if ts_manual and ts_manual.has_method("transition_to_scene"):
		ts_manual.transition_to_scene(target_scene)
		return

	# 3. Fallback terakhir: Ganti scene kasar (tanpa transisi)
	push_warning("GameManager: TransitionScreen tidak ditemukan. Menjalankan fallback deferred change.")
	call_deferred("_do_change_scene", target_scene)

func tanda():
	print("tanda")
