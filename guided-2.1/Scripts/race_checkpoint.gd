extends Area2D

# Tarik node UI Popup "Anda Kalah" dan "Player Menang" lewat Inspector
@export var lose_popup: Control
@export var win_popup: Control

# --- DEBUGGING ---
@export var is_active: bool = true
# -----------------

var is_cleared: bool = false # Penanda apakah player sudah lewat sini dengan aman
var game_over_triggered: bool = false

func _ready():
	# Sembunyikan popup di awal kalau ada
	if lose_popup:
		lose_popup.visible = false
	if win_popup:
		win_popup.visible = false

	# Pastikan checkpoint tergabung di grup "race_checkpoint"
	if not is_in_group("race_checkpoint"):
		add_to_group("race_checkpoint")

	# Connect body_entered (defensive)
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	# Abaikan jika dinonaktifkan atau sudah game over
	if not is_active or game_over_triggered:
		return

	# 1) PLAYER masuk -> aman
	if body.is_in_group("player"):
		if not is_cleared:
			is_cleared = true
			print("Checkpoint: Player lolos! Aman.")
			modulate = Color.GREEN
			_check_for_all_cleared()
		return

	# 2) GHOST / SENSEI masuk -> bahaya (cek layer 3 jika tersedia)
	if body.has_method("get_collision_layer_value") and body.get_collision_layer_value(3):
		if is_cleared:
			print("Checkpoint: Ghost lewat (tapi player sudah aman).")
		else:
			print("Checkpoint: Ghost (sensei) menang di checkpoint ini! PLAYER KALAH.")
			_trigger_defeat()
		return

func _check_for_all_cleared():
	# Ambil semua node di grup race_checkpoint
	var nodes = get_tree().get_nodes_in_group("race_checkpoint")
	if nodes.is_empty():
		return

	var cleared_count: int = 0
	for n in nodes:
		# Gunakan get() supaya aman jika node tidak punya properti
		if n.get("is_cleared") == true:
			cleared_count += 1

	# Jika semua checkpoint terlewati -> victory
	if cleared_count == nodes.size():
		_trigger_victory()

# Helper: cari GhostPlayer secara rekursif, fallback get_node_or_null
func _find_ghost() -> Node:
	var scene = get_tree().current_scene
	if not scene:
		return null
	var g = scene.find_child("GhostPlayer", true, false)
	if g:
		return g
	return scene.get_node_or_null("GhostPlayer")

func _trigger_defeat():
	# Pastikan hanya dipanggil sekali
	if game_over_triggered:
		return
	game_over_triggered = true

	# Freeze player jika ada (GameManager juga akan freeze di request)
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("freeze"):
		player.freeze()

	# Freeze ghost (gunakan helper)
	var ghost = _find_ghost()
	if ghost and ghost.has_method("freeze"):
		ghost.freeze()

	# Tampilkan popup kalah
	if lose_popup:
		lose_popup.visible = true

	# Tunggu 2 detik supaya pemain melihat popup
	await get_tree().create_timer(2.0).timeout

	# Transisi: gunakan GameManager.request_change_scene_with_transition agar flow terpusat
	if Engine.has_singleton("GameManager"):
		var gm = Engine.get_singleton("GameManager")
		if gm and gm.has_method("request_change_scene_with_transition"):
			gm.request_change_scene_with_transition(false)
			return

	# Fallback: langsung ganti scene (deferred) supaya aman terhadap physics callbacks
	push_warning("RaceCheckpoint: GameManager singleton tidak ditemukan, fallback change_scene.")
	call_deferred("_fallback_change_to_defeat")

func _fallback_change_to_defeat():
	get_tree().change_scene_to_file("res://Scenes/Dialog/player_kalah.tscn")

func _trigger_victory():
	# Pastikan hanya dipanggil sekali
	if game_over_triggered:
		return
	game_over_triggered = true

	print("RaceCheckpoint: Semua checkpoint terlewati — PLAYER MENANG!")

	# Freeze player & ghost
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("freeze"):
		player.freeze()

	var ghost = _find_ghost()
	if ghost and ghost.has_method("freeze"):
		ghost.freeze()

	# Tampilkan popup menang
	if win_popup:
		win_popup.visible = true

	# Tunggu 2 detik
	await get_tree().create_timer(2.0).timeout

	# Transisi ke scene menang via GameManager agar terpusat
	if Engine.has_singleton("GameManager"):
		var gm = Engine.get_singleton("GameManager")
		if gm and gm.has_method("request_change_scene_with_transition"):
			gm.request_change_scene_with_transition(true)
			return

	# Fallback: langsung ganti scene (deferred)
	push_warning("RaceCheckpoint: GameManager singleton tidak ditemukan, fallback change_scene.")
	call_deferred("_fallback_change_to_victory")

func _fallback_change_to_victory():
	get_tree().change_scene_to_file("res://Scenes/Dialog/player_menang.tscn")
