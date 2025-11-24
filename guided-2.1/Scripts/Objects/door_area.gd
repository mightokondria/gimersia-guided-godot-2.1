extends Area2D

# Gunakan @export_file agar bisa pilih file lewat folder window di Inspector
@export_file("*.tscn") var target_scene_path: String = ""
@export var spawn_id: String = ""           # ID pintu ini (opsional, buat spawn point)
@export var locked: bool = false            # Jika true, butuh item
@export var require_item: String = ""       # Contoh: "key_red"
@export var interact_only: bool = false     # Jika true, harus tekan tombol (UI Accept)
@export var prompt_text: String = "Press X to enter"

var _triggered := false
var _player_in_area : Node = null

func _ready() -> void:
	# Menghubungkan sinyal secara manual jika belum terhubung
	if not body_entered.is_connected(_on_body_entered):
		connect("body_entered", Callable(self, "_on_body_entered"))
	if not body_exited.is_connected(_on_body_exited):
		connect("body_exited", Callable(self, "_on_body_exited"))

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
		
	# --- VALIDASI DISINI ---
	print("DEBUG: Player berhasil masuk Area2D! (Nama Node: ", body.name, ")")
	_player_in_area = body
	
	
	if interact_only:
		print("UI: " + prompt_text)
		# UI.show_prompt(prompt_text) # (Uncomment jika sudah punya sistem UI)
		return
		
	# Jika tidak interact_only, langsung masuk
	_try_trigger(body)

func _on_body_exited(body: Node) -> void:
	if body == _player_in_area:
		_player_in_area = null
		if interact_only:
			# UI.hide_prompt() # (Uncomment jika sudah punya sistem UI)
			pass

func _input(event):
	# Deteksi tombol interaksi (Enter/Space/X tergantung setting Input Map "ui_accept")
	if interact_only and _player_in_area and event.is_action_pressed("ui_accept"):
		_try_trigger(_player_in_area)

func _try_trigger(player_node: Node) -> void:
	if _triggered:
		return
		
	if locked:
		# Cek inventory via GameManager (pastikan fungsi has_item ada di GameManager)
		# Jika belum punya fungsi has_item, logika ini akan diskip atau error
		if require_item != "" and GameManager and GameManager.has_method("has_item"):
			if GameManager.has_item(require_item):
				locked = false
				print("Door: Unlocked with " + require_item)
			else:
				print("Door: Terkunci! Butuh " + require_item)
				# UI.show_message("Pintu terkunci")
				return
		elif locked:
			print("Door: Terkunci permanen.")
			return

	_triggered = true
	print("Door: Pindah ke scene -> ", target_scene_path)
	
	# --- PANGGIL GAME MANAGER ---
	if GameManager:
		# FIX: Jangan lupa kirim spawn_id agar player muncul di pintu yang benar
		GameManager.request_change_scene(target_scene_path, spawn_id)
	else:
		# Fallback jika GameManager error
		call_deferred("_fallback_change", target_scene_path, spawn_id)

func _fallback_change(path: String, spawn: String) -> void:
	if ResourceLoader.exists(path):
		# FIX: 'has_variable' tidak ada di GDScript, gunakan syntax 'in'
		if GameManager and "next_spawn_id" in GameManager:
			GameManager.next_spawn_id = spawn
		get_tree().change_scene_to_file(path)
	else:
		push_warning("DoorArea: Invalid path: " + str(path))
