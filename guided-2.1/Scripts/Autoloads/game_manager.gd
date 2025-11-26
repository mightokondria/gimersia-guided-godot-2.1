# GameManager.gd (dipakai sebagai Autoload, Name: GameManager)
extends Node

var player: Node = null
var start_position: Node2D = null
var transition: Node = null
var after_image_container: Node = null
var is_transitioning: bool = false

var next_spawn_id: String = ""   # tambahkan di top-level jika belum ada

@onready var TransitionScreen: Node = get_node("/root/TransitionScreen") # Sesuaikan path

func _ready() -> void:
	print("GameManager (autoload) ready. Waiting for level/player registration...")

# Panggil dari level root saat level ready:
func register_level(level_root: Node) -> void:
	start_position = level_root.get_node_or_null("StartPosition")
	transition = level_root.get_node_or_null("transition")
	after_image_container = level_root.get_node_or_null("AfterImageContainer")
	if not start_position:
		push_warning("GameManager: StartPosition not found in level_root")
	print("GameManager: level registered")

# Panggil dari Player._ready()
func register_player(p: Node) -> void:
	player = p
	var cb = Callable(self, "_on_player_create_after_image")
	if not player.is_connected("create_after_image", cb):
		player.connect("create_after_image", cb)
	print("GameManager: player registered:", player)

func _on_player_create_after_image(texture, spawn_pos, is_flipped) -> void:
	if after_image_container:
		print("after image")
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
		push_warning("GameManager: no after_image_container set")

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
func request_change_scene_with_transition(did_player_win: bool, current_stage_id: int = 1) -> void:
	var target_scene: String
	
	if did_player_win:
		target_scene = "res://Scenes/Dialog/player_menang.tscn"
	else:
		target_scene = "res://Scenes/Dialog/player_kalah.tscn"
		
	# Jika TransitionScreen ada dan punya method transition_to_scene, panggil itu.
	if has_node("/root/TransitionScreen"):
		var ts = get_node("/root/TransitionScreen")
		if ts and ts.has_method("transition_to_scene"):
			# Panggilan biasa OK (TransitionScreen biasanya yang handle deferred/change)
			ts.transition_to_scene(target_scene)
			return

	# Fallback: gunakan call_deferred supaya tidak memicu physics-callback removal
	push_warning("GameManager: TransitionScreen tidak ditemukan. Menjalankan fallback deferred change.")
	call_deferred("_do_change_scene", target_scene)


	
func tanda():
	print("tanda")
	
