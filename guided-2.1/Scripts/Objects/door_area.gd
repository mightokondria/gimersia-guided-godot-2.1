extends Area2D

@export var target_scene_path: String = ""
@export var spawn_id: String = ""          # optional: id spawn di scene tujuan
@export var locked: bool = false           # jika true, butuh unlock
@export var require_item: String = ""      # contoh: "key_red"
@export var interact_only: bool = false    # jika true, player harus tekan tombol untuk aktif
@export var prompt_text: String = "Press X to enter"

var _triggered := false
var _player_in_area : CharacterBody2D = null

func _ready() -> void:
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))

func _on_body_entered(body: Node) -> void:
	if not body or not body.is_in_group("player"):
		return
	_player_in_area = body
	if interact_only:
		# show prompt via UI (optional)
		#UI.show_prompt(prompt_text)
		return
	_try_trigger(body)

func _on_body_exited(body: Node) -> void:
	if body == _player_in_area:
		_player_in_area = null
		if interact_only:
			pass
			#UI.hide_prompt()d

func _input(event):
	if interact_only and _player_in_area and event.is_action_pressed("ui_accept"):
		_try_trigger(_player_in_area)

func _try_trigger(player_node: Node) -> void:
	if _triggered:
		return
	if locked:
	# optionally check inventory via GameManager or InventoryManager
		if require_item != "" and Engine.has_singleton("GameManager") and GameManager.has_item(require_item):
			# unlock automatically
			locked = false
		else:
			# show locked feedback
			#UI.show_message("Pintu terkunci")
			return

	_triggered = true
	# Delegate to GameManager; include spawn_id so next scene knows where to place player
	if has_node("/root/GameManager") and get_node("/root/GameManager").has_method("request_change_scene"):
		get_node("/root/GameManager").request_change_scene(target_scene_path)
	else:
		# fallback safe deferred change
		call_deferred("_fallback_change", target_scene_path, spawn_id)

func _fallback_change(path: String, spawn: String) -> void:
	if ResourceLoader.exists(path):
		# store spawn_id in GameManager fallback storage if exists
		if has_node("/root/GameManager") and get_node("/root/GameManager").has_variable("next_spawn_id"):
			get_node("/root/GameManager").next_spawn_id = spawn
		get_tree().change_scene_to_file(path)
	else:
		push_warning("DoorArea: invalid path: " + str(path))
