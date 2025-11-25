extends Area2D

var first_place_taken = false # Penanda apakah sudah ada yang juara 1

func _ready():
	# Hubungkan sinyal jika belum
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	# 1. JIKA PLAYER YANG MASUK
	if body.is_in_group("player"):
		print("Finish Line: Player Masuk.")
		
		if not first_place_taken:
			# Skenario: Player Juara 1 -> MENANG LANGSUNG
			first_place_taken = true
			print(">>> PLAYER MENANG! Ganti scene menang.")
			_change_scene(true)
		else:
			# Skenario: Ghost sudah ambil juara 1 duluan -> PLAYER KALAH
			print(">>> PLAYER KALAH! (Ghost sudah di sana). Ganti scene kalah.")
			_change_scene(false)

	# 2. JIKA GHOST YANG MASUK
	elif body.has_method("get_collision_layer_value") and body.get_collision_layer_value(3):
		print("Finish Line: Ghost Masuk.")
		
		if not first_place_taken:
			# Skenario: Ghost Juara 1 -> TUNGGU PLAYER
			first_place_taken = true
			print(">>> GHOST MENANG! Menunggu player sampai...")
			
			# Opsional: Hentikan animasi ghost biar terlihat nunggu
			# body.process_mode = Node.PROCESS_MODE_DISABLED 

func _change_scene(is_win: bool):
	var target_scene = ""
	
	if is_win:
		target_scene = "res://Scenes/Dialog/player_menang.tscn"
	else:
		target_scene = "res://Scenes/Dialog/player_kalah.tscn"
	
	# Gunakan GameManager jika ada, atau fallback ke tree change
	if GameManager and GameManager.has_method("request_change_scene"):
		GameManager.request_change_scene(target_scene)
	else:
		get_tree().change_scene_to_file(target_scene)
