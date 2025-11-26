extends Area2D

# Popup kalah dan menang
@export var lose_popup: Control
@export var win_popup: Control

# Bisa ganti scene menang / kalah lewat Inspector
@export var lose_scene_path: String = "res://Scenes/Dialog/player_kalah.tscn"
@export var win_scene_path: String  = "res://Scenes/Dialog/player_menang.tscn"

# Debug
@export var is_active: bool = true

var is_cleared: bool = false
var game_over_triggered: bool = false


func _ready():
	# Sembunyikan popup di awal (jika Control)
	if lose_popup and lose_popup is Control:
		lose_popup.visible = false
	if win_popup and win_popup is Control:
		win_popup.visible = false

	# Masukkan ke grup race_checkpoint jika belum
	if not is_in_group("race_checkpoint"):
		add_to_group("race_checkpoint")

	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func _on_body_entered(body):
	if not is_active or game_over_triggered:
		return

	# PLAYER masuk
	if body.is_in_group("player"):
		if not is_cleared:
			is_cleared = true
			modulate = Color.GREEN
			_check_for_all_cleared()
		return

	# GHOST masuk (cek layer 3)
	if body.has_method("get_collision_layer_value") and body.get_collision_layer_value(3):
		if not is_cleared:
			_trigger_defeat()
		return


func _check_for_all_cleared():
	var checkpoints = get_tree().get_nodes_in_group("race_checkpoint")
	if checkpoints.is_empty():
		return

	var passed := 0
	for c in checkpoints:
		if c.get("is_cleared") == true:
			passed += 1

	if passed == checkpoints.size():
		_trigger_victory()


func _find_ghost():
	var scene = get_tree().current_scene
	if not scene:
		return null
	var ghost = scene.find_child("GhostPlayer", true, false)
	if ghost:
		return ghost
	return scene.get_node_or_null("GhostPlayer")


func _trigger_defeat():
	if game_over_triggered:
		return
	game_over_triggered = true

	# Freeze player
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("freeze"):
		player.freeze()

	# Freeze ghost
	var ghost = _find_ghost()
	if ghost and ghost.has_method("freeze"):
		ghost.freeze()

	# Tampilkan popup kalah
	if lose_popup and lose_popup is Control:
		lose_popup.visible = true

	await get_tree().create_timer(2.0).timeout

	# Gunakan GameManager jika ada
	if Engine.has_singleton("GameManager"):
		var gm = Engine.get_singleton("GameManager")
		if gm and gm.has_method("request_change_scene_with_transition"):
			gm.request_change_scene_with_transition(false)
			return

	# Fallback ganti scene langsung
	if ResourceLoader.exists(lose_scene_path):
		get_tree().change_scene_to_file(lose_scene_path)
	else:
		push_error("lose_scene_path invalid: " + lose_scene_path)


func _trigger_victory():
	if game_over_triggered:
		return
	game_over_triggered = true

	# Freeze player
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("freeze"):
		player.freeze()

	# Freeze ghost
	var ghost = _find_ghost()
	if ghost and ghost.has_method("freeze"):
		ghost.freeze()

	# Tampilkan popup menang
	if win_popup and win_popup is Control:
		win_popup.visible = true

	await get_tree().create_timer(2.0).timeout

	# Gunakan GameManager jika ada
	if Engine.has_singleton("GameManager"):
		var gm = Engine.get_singleton("GameManager")
		if gm and gm.has_method("request_change_scene_with_transition"):
			gm.request_change_scene_with_transition(true)
			return

	# Fallback ganti scene langsung
	if ResourceLoader.exists(win_scene_path):
		get_tree().change_scene_to_file(win_scene_path)
	else:
		push_error("win_scene_path invalid: " + win_scene_path)
