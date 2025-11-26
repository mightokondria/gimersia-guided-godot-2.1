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

### --- SISTEM ONE-TIME DOOR (LOGIKA BARU) ---
# Array untuk menyimpan ID pintu yang sudah pernah dilewati
var visited_doors: Array[String] = []

# Referensi ke Autoload TransitionScreen
@onready var TransitionScreen: Node = get_node_or_null("/root/TransitionScreen") 

func _ready() -> void:
	print("GameManager (autoload) ready. Waiting for level/player registration...")

# --- FUNGSI BARU UNTUK PINTU ---
# Cek apakah pintu dengan ID tertentu sudah pernah dilewati
func is_door_visited(door_id: String) -> bool:
	return visited_doors.has(door_id)

# Tandai pintu sudah dilewati (panggil ini saat player berhasil masuk)
func mark_door_visited(door_id: String) -> void:
	if door_id != "" and not visited_doors.has(door_id):
		visited_doors.append(door_id)
		print("GameManager: Door marked as visited -> ", door_id)

# --- FUNGSI UNLOCK SKILL ---
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

# Panggil dari level root saat level ready
func register_level(level_root: Node) -> void:
	# 1. Cek apakah ada request spawn ID khusus dari pintu sebelumnya?
	if next_spawn_id != "":
		# Cari node di dalam level baru yang namanya SAMA dengan next_spawn_id
		var specific_point = level_root.get_node_or_null(next_spawn_id)
		
		if specific_point:
			start_position = specific_point
			print("GameManager: Spawn found by ID -> ", next_spawn_id)
		else:
			# Jika tidak ketemu, fallback ke default "StartPosition"
			print("GameManager: Spawn ID '", next_spawn_id, "' not found. Using default.")
			start_position = level_root.get_node_or_null("StartPosition")
			
		# Reset ID agar tidak terbawa ke level berikutnya
		next_spawn_id = ""
		
	else:
		# 2. Jika tidak ada request ID (misal start game baru), cari default
		start_position = level_root.get_node_or_null("StartPosition")

	transition = level_root.get_node_or_null("transition")
	after_image_container = level_root.get_node_or_null("AfterImageContainer")
	
	if not start_position:
		push_warning("GameManager: No spawn position found!")
	
	print("GameManager: level registered from ", level_root.name)
	
	# --- TELEPORT PLAYER KE POSISI ITU ---
	if player and start_position:
		player.global_position = start_position.global_position


# Panggil dari Player._ready()
func register_player(p: Node) -> void:
	player = p
	var cb = Callable(self, "_on_player_create_after_image")
	if not player.is_connected("create_after_image", cb):
		player.connect("create_after_image", cb)
	print("GameManager: player registered:", player)

func _on_player_create_after_image(texture, spawn_pos, is_flipped) -> void:
	if after_image_container:
		var s = Sprite2D.new()
		s.texture = texture
		s.global_position = spawn_pos
		s.flip_h = is_flipped
		
		s.scale = Vector2(6, 6) 
		
		after_image_container.add_child(s)
		s.modulate = Color(0.5,0.7,1,0.7)
		var tw = create_tween()
		tw.tween_property(s, "modulate", Color(0.5,0.7,1,0), 0.4)
		tw.tween_callback(Callable(s, "queue_free"))
	else:
		pass

# Fungsi generik untuk ganti scene
func request_change_scene(path: String, spawn_id: String = "") -> void:
	if path == "" or not ResourceLoader.exists(path):
		push_warning("GameManager: invalid path: " + str(path))
		return
		
	next_spawn_id = spawn_id

	if player:
		if player.has_method("freeze"):
			player.freeze()
		player.set_physics_process(false)

	call_deferred("_do_change_scene", path)

func _do_change_scene(path: String) -> void:
	print("GameManager: changing scene to", path)
	get_tree().change_scene_to_file(path)
	

# FUNGSI PEMANGGIL TRANISI SAAT MENANG/KALAH
func request_change_scene_with_transition(did_player_win: bool, current_stage_id: int = 1) -> void:
	var target_scene: String
	
	if did_player_win:
		target_scene = "res://Scenes/Dialog/player_menang.tscn"
	else:
		target_scene = "res://Scenes/Dialog/player_kalah.tscn"
		
	if TransitionScreen and TransitionScreen.has_method("transition_to_scene"):
		TransitionScreen.transition_to_scene(target_scene)
		return

	var ts_manual = get_node_or_null("/root/TransitionScreen")
	if ts_manual and ts_manual.has_method("transition_to_scene"):
		ts_manual.transition_to_scene(target_scene)
		return

	push_warning("GameManager: TransitionScreen tidak ditemukan. Menjalankan fallback deferred change.")
	call_deferred("_do_change_scene", target_scene)

func tanda():
	print("tanda")
